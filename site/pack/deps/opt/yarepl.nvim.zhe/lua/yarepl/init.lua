--[[
This Lua module provides functionality for managing and interacting with
Read-Eval-Print Loops (REPLs) within Neovim. It allows users to start,
focus, send code to, and manage various REPL instances, enhancing
interactive coding workflows. The plugin is highly configurable,
supporting different REPL types, custom commands, and formatters.
--]]
local M = {}
local api = vim.api
local fn = vim.fn
local is_win32 = vim.fn.has 'win32' == 1

-- Table to store available formatter functions.
M.formatter = {}
-- Table to store user-callable command functions.
M.commands = {}

-- Provides the default configuration for the plugin.
-- Users can override these settings in their Neovim configuration.
local default_config = function()
    return {
        buflisted = true, -- If true, REPL buffers will be listed.
        scratch = true, -- If true, REPL buffers will be scratch buffers (no swap file, not written to disk).
        ft = 'REPL', -- Default filetype for REPL buffers.
        wincmd = 'belowright 15 split', -- Default command to open the REPL window. Can be a string or a function.
        metas = { -- Configuration for specific REPL types.
            -- Example: 'aichat' REPL configuration.
            aichat = { cmd = 'aichat', formatter = 'bracketed_pasting', source_syntax = 'aichat' },
            -- Example: 'radian' (R REPL) configuration.
            radian = { cmd = 'radian', formatter = 'bracketed_pasting_no_final_new_line', source_syntax = 'R' },
            -- Example: 'ipython' REPL configuration.
            ipython = { cmd = 'ipython', formatter = 'bracketed_pasting', source_syntax = 'ipython' },
            -- Example: 'python' REPL configuration.
            python = { cmd = 'python', formatter = 'trim_empty_lines', source_syntax = 'python' },
            -- Example: 'R' REPL configuration.
            R = { cmd = 'R', formatter = 'trim_empty_lines', source_syntax = 'R' },
            -- Bash configuration: Uses bracketed paste mode on Linux, trims empty lines otherwise.
            -- This is because macOS ships with an older bash version that may not support bracketed paste.
            bash = {
                cmd = 'bash',
                formatter = vim.fn.has 'linux' == 1 and 'bracketed_pasting' or 'trim_empty_lines',
                source_syntax = 'bash',
            },
            -- Example: 'zsh' REPL configuration.
            zsh = { cmd = 'zsh', formatter = 'bracketed_pasting', source_syntax = 'bash' },
        },
        close_on_exit = true, -- If true, closes the REPL window when the REPL process exits.
        scroll_to_bottom_after_sending = true, -- If true, scrolls the REPL window to the bottom after sending code.
        -- If true, format REPL buffer names like #repl_name#n (e.g., #ipython#1).
        -- Otherwise, uses terminal defaults.
        format_repl_buffers_names = true,
        os = { -- OS-specific configurations.
            windows = {
                -- If true, sends a delayed Carriage Return (CR) after sending code on Windows.
                -- This can help ensure commands are executed properly in some REPLs.
                send_delayed_final_cr = true,
            },
        },
        print_1st_line_on_source = false, -- If true, sends the first non-empty line of sourced content as a comment to the REPL.
        comment_prefixes = { -- Defines comment characters for different REPLs, used by `print_1st_line_on_source`.
            python = '# ',
            ipython = '# ',
            R = '# ',
            bash = '# ',
            zsh = '# ',
            lua = '-- ',
        },
    }
end

-- Stores active REPL instances, indexed by a unique ID.
-- Each entry is a table: { bufnr = number, term = job_id, name = string }
M._repls = {}
-- Maps buffer numbers to their associated REPL instances.
-- This is used to quickly find the REPL attached to a given buffer.
M._bufnrs_to_repls = {}

-- Checks if a REPL instance is valid and its buffer is loaded.
-- @param repl table The REPL object to check.
-- @return boolean True if the REPL is valid, false otherwise.
local function repl_is_valid(repl)
    return repl ~= nil and api.nvim_buf_is_loaded(repl.bufnr)
end

-- Cleans up REPL instances.
-- Removes invalid REPLs and re-indexes the remaining ones to ensure no gaps in `M._repls`.
-- Also updates buffer names if `format_repl_buffers_names` is enabled.
local function repl_cleanup()
    local valid_repls = {}
    local valid_repls_id = {}
    -- Collect IDs of valid REPLs from the main M._repls table.
    for id, repl in pairs(M._repls) do
        if repl_is_valid(repl) then
            table.insert(valid_repls_id, id)
        end
    end

    -- Clean up M._bufnrs_to_repls by removing entries for invalid REPLs or unloaded buffers.
    for bufnr, repl in pairs(M._bufnrs_to_repls) do
        if not repl_is_valid(repl) then
            M._bufnrs_to_repls[bufnr] = nil
        end

        if not api.nvim_buf_is_loaded(bufnr) then
            M._bufnrs_to_repls[bufnr] = nil
        end
    end

    table.sort(valid_repls_id) -- Sort IDs to maintain order.

    -- Rebuild M._repls with only valid REPLs, re-indexing them.
    for _, id in ipairs(valid_repls_id) do
        table.insert(valid_repls, M._repls[id])
    end
    M._repls = valid_repls

    -- If configured, reformat REPL buffer names to ensure sequential numbering after cleanup.
    if M._config.format_repl_buffers_names then
        for id, repl in pairs(M._repls) do
            -- Set a temporary name first to avoid conflicts if names are swapped.
            api.nvim_buf_set_name(repl.bufnr, string.format('#%s#temp#%d', repl.name, id))
        end

        for id, repl in pairs(M._repls) do
            -- Set the final, formatted name.
            api.nvim_buf_set_name(repl.bufnr, string.format('#%s#%d', repl.name, id))
        end
    end
end

-- Focuses on the specified REPL window.
-- If the REPL window exists, it switches to it. Otherwise, it creates/opens the REPL window.
-- @param repl table The REPL object to focus.
local function focus_repl(repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local win = fn.bufwinid(repl.bufnr) -- Get window ID for the REPL buffer.
    if win ~= -1 then
        -- Window exists, set it as current.
        api.nvim_set_current_win(win)
    else
        -- Window doesn't exist, use configured wincmd to open it.
        local wincmd = M._config.metas[repl.name].wincmd or M._config.wincmd

        if type(wincmd) == 'function' then
            -- If wincmd is a function, call it with bufnr and repl name.
            wincmd(repl.bufnr, repl.name)
        else
            -- If wincmd is a string, execute it as a vim command.
            vim.cmd(wincmd)
            api.nvim_set_current_buf(repl.bufnr) -- Set the buffer in the new window.
        end
    end
end

-- Creates a new REPL instance.
-- @param id number The desired ID for the new REPL.
-- @param repl_name string The name of the REPL type to create (e.g., "python", "bash").
local function create_repl(id, repl_name)
    if repl_is_valid(M._repls[id]) then
        vim.notify(string.format('REPL %d already exists, no new REPL is created', id))
        return
    end

    if not M._config.metas[repl_name] then
        vim.notify 'No REPL palette is found' -- "Palette" likely means configuration/meta.
        return
    end

    -- Create a new buffer for the REPL.
    local bufnr = api.nvim_create_buf(M._config.buflisted, M._config.scratch)
    vim.bo[bufnr].filetype = M._config.ft -- Set filetype for the REPL buffer.

    local cmd -- Command to start the REPL process.

    -- Determine the command, can be a string or a function from config.
    if type(M._config.metas[repl_name].cmd) == 'function' then
        cmd = M._config.metas[repl_name].cmd()
    else
        cmd = M._config.metas[repl_name].cmd
    end

    -- Determine the window command, can be a string or a function from config.
    local wincmd = M._config.metas[repl_name].wincmd or M._config.wincmd

    -- Open the window for the REPL.
    if type(wincmd) == 'function' then
        wincmd(bufnr, repl_name)
    else
        vim.cmd(wincmd)
        api.nvim_set_current_buf(bufnr)
    end

    local opts = {} -- Options for termopen/jobstart.
    opts.on_exit = function(_, _, _) -- Callback for when the REPL process exits.
        if M._config.close_on_exit then
            -- Close all windows associated with the REPL buffer.
            local bufwinid = fn.bufwinid(bufnr)
            while bufwinid ~= -1 do
                api.nvim_win_close(bufwinid, true)
                bufwinid = fn.bufwinid(bufnr)
            end
            -- Delete the buffer if it's still loaded.
            if api.nvim_buf_is_loaded(bufnr) then
                api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        repl_cleanup() -- Perform cleanup of REPL lists.
    end

    -- Wrapper function for termopen/jobstart for compatibility with nvim 0.11+.
    ---@diagnostic disable-next-line: redefined-local
    local function termopen(cmd_str, term_opts) -- Renamed params for clarity from original `cmd, opts`.
        if vim.fn.has 'nvim-0.11' == 1 then
            term_opts.term = true -- For nvim 0.11+, jobstart is used with term = true.
            return vim.fn.jobstart(cmd_str, term_opts)
        else
            return vim.fn.termopen(cmd_str, term_opts) -- For older nvim versions.
        end
    end

    local term = termopen(cmd, opts) -- Start the terminal/job for the REPL.
    if M._config.format_repl_buffers_names then
        -- Set the formatted buffer name.
        api.nvim_buf_set_name(bufnr, string.format('#%s#%d', repl_name, id))
    end
    -- Store the new REPL instance.
    M._repls[id] = { bufnr = bufnr, term = term, name = repl_name }
end

-- Finds the ID of the closest REPL with the given `name`, relative to a starting `id`.
-- "Closest" means the smallest absolute difference in IDs.
-- @param id number The starting ID to measure distance from.
-- @param name string The name of the REPL type to find.
-- @return number|nil The ID of the closest matching REPL, or nil if not found.
local function find_closest_repl_from_id_with_name(id, name)
    local closest_id = nil
    local closest_distance = math.huge
    for repl_id, repl in pairs(M._repls) do
        if repl.name == name then
            local distance = math.abs(repl_id - id)
            if distance < closest_distance then
                closest_id = repl_id
                closest_distance = distance
            end
            if distance == 0 then -- Found an exact match for the ID, no need to search further.
                break
            end
        end
    end
    return closest_id
end

-- Swaps two REPL instances in the `M._repls` table by their IDs.
-- After swapping, `repl_cleanup` is called to re-index and update names.
-- @param id_1 number The ID of the first REPL.
-- @param id_2 number The ID of the second REPL.
local function repl_swap(id_1, id_2)
    local repl_1 = M._repls[id_1]
    local repl_2 = M._repls[id_2]
    M._repls[id_1] = repl_2
    M._repls[id_2] = repl_1
    repl_cleanup() -- Important to re-index and potentially rename buffers.
end

-- Attaches a buffer (by its `bufnr`) to a specific REPL instance.
-- This allows commands to implicitly target this REPL when operating from the attached buffer.
-- @param bufnr number The buffer number to attach.
-- @param repl table The REPL object to attach the buffer to.
local function attach_buffer_to_repl(bufnr, repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    if not api.nvim_buf_is_loaded(bufnr) then
        vim.notify [[Invalid buffer!]]
        return
    end
    M._bufnrs_to_repls[bufnr] = repl
end

-- Checks if a given buffer number is attached to any valid REPL.
-- @param bufnr number The buffer number to check.
-- @return boolean True if the buffer is attached to a valid REPL, false otherwise.
M.bufnr_is_attached_to_repl = function(bufnr)
    return repl_is_valid(M._bufnrs_to_repls[bufnr])
end

--- Gets a specific REPL instance based on ID, name, and/or attached buffer.
---@param id number|nil The ID of the REPL. If 0 or nil, tries to use attached REPL or defaults to ID 1.
---@param name string|nil The name of the REPL type to find (e.g., "python"). If provided, finds the closest one.
---@param bufnr number|nil The buffer number to check for an attached REPL.
---@return table|nil The REPL object, or nil if not found or invalid.
function M._get_repl(id, name, bufnr)
    local repl

    -- Highest precedence: If a 'name' is provided, find the closest REPL of that type.
    if name ~= nil and name ~= '' then
        -- The search for the closest REPL is relative to the provided `id`, or defaults to 1.
        local reference_id = (id == nil or id == 0) and 1 or id
        local closest_id = find_closest_repl_from_id_with_name(reference_id, name)
        repl = M._repls[closest_id]
    else
        -- No 'name' provided, so use 'id' or the attached buffer.
        if id ~= nil and id ~= 0 then
            -- A specific ID was requested.
            repl = M._repls[id]
        else
            -- No ID was given, so try the REPL attached to the current buffer first.
            repl = M._bufnrs_to_repls[bufnr]
            -- If the attached REPL isn't valid, fall back to the default REPL (ID 1).
            if not repl_is_valid(repl) then
                repl = M._repls[1]
            end
        end
    end

    -- Finally, validate the selected REPL before returning.
    if repl_is_valid(repl) then
        return repl
    end

    return nil
end

-- Scrolls the window of a given REPL to the bottom.
-- @param repl table The REPL object whose window should be scrolled.
local function repl_win_scroll_to_bottom(repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local repl_win = fn.bufwinid(repl.bufnr) -- Get the window ID for the REPL buffer.
    if repl_win ~= -1 then
        local lines = api.nvim_buf_line_count(repl.bufnr) -- Get total lines in buffer.
        api.nvim_win_set_cursor(repl_win, { lines, 0 }) -- Set cursor to the last line.
    end
end

-- Retrieves lines of text based on the current mode (visual or operator).
-- This function is used to get the text that needs to be sent to the REPL.
-- @param mode string Either 'operator' or 'visual'.
-- @return table A list of strings, where each string is a line of text.
local function get_lines(mode)
    -- Determine the marks for the start and end of the selection.
    -- '[ and '] are for operator-pending mode.
    -- '< and '> are for visual mode.
    local begin_mark = mode == 'operator' and "'[" or "'<"
    local end_mark = mode == 'operator' and "']" or "'>"

    local begin_line = fn.getpos(begin_mark)[2] -- Get line number of the beginning mark.
    local end_line = fn.getpos(end_mark)[2] -- Get line number of the ending mark.
    -- Retrieve the lines from the current buffer (0) between begin_line-1 and end_line.
    return api.nvim_buf_get_lines(0, begin_line - 1, end_line, false)
end

--- Get the formatter function from either a string name or the function itself.
--- @param formatter string|function The formatter name (e.g., "bracketed_pasting") or a formatter function.
--- @return function The formatter function to use.
--- @throws string Error if a string formatter name is unknown.
local function get_formatter(formatter)
    if type(formatter) == 'string' then
        -- If formatter is a string, look it up in M.formatter table.
        return M.formatter[formatter] or error('Unknown formatter: ' .. formatter)
    end
    -- If formatter is already a function, return it directly.
    return formatter
end

-- A factory function to create custom formatter functions.
-- Formatters are used to process lines of code before sending them to a REPL.
-- This allows for things like bracketed paste mode, trimming lines, etc.
-- @param opts table Configuration options for the formatter.
-- @return function A new formatter function that takes a list of lines and returns formatted lines.
function M.formatter.factory(opts)
    if type(opts) ~= 'table' then
        error 'opts must be a table'
    end

    -- Default configuration for the formatter
    local config = {
        replace_tab_by_space = false,
        number_of_spaces_to_replace_tab = 8,
        when_multi_lines = {
            open_code = '',
            end_code = '\r', -- Default to carriage return for multi-line end
            trim_empty_lines = false,
            remove_leading_spaces = false,
            -- gsub_pattern and gsub_repl are applied to each line after other processing
            -- but before open_code (for the first line) and end_code.
            gsub_pattern = '', -- Lua pattern
            gsub_repl = '',
        },
        when_single_line = {
            open_code = '',
            end_code = '\r', -- Default to carriage return for single-line end
            gsub_pattern = '', -- Lua pattern
            gsub_repl = '',
        },
        os = {
            windows = {
                join_lines_with_cr = true, -- Specific behavior for Windows
            },
        },
    }

    -- Merge user-provided options with defaults.
    config = vim.tbl_deep_extend('force', config, opts)

    -- Return the actual formatting function that captures the resolved 'config'
    return function(lines)
        if #lines == 1 then
            local line = lines[1] -- Work on a copy if modifications are extensive, but direct assignment is fine here.
            if config.replace_tab_by_space then
                line = line:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
            end

            -- Apply gsub only if a pattern is provided
            if config.when_single_line.gsub_pattern ~= '' then
                line = line:gsub(config.when_single_line.gsub_pattern, config.when_single_line.gsub_repl)
            end

            -- Add open and end codes for the single line
            line = config.when_single_line.open_code .. line .. config.when_single_line.end_code
            return { line } -- Return as a table of lines
        end

        -- Multi-line processing
        local formatted_lines = {}
        local current_line = lines[1] -- Process the first line separately for open_code

        -- Apply multi-line gsub to the first line if a pattern is provided
        if config.when_multi_lines.gsub_pattern ~= '' then
            current_line = current_line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)
        end
        current_line = config.when_multi_lines.open_code .. current_line
        table.insert(formatted_lines, current_line)

        -- Process subsequent lines
        for i = 2, #lines do
            current_line = lines[i]

            -- Only process and add the line if it's not an empty line that's configured to be trimmed
            if not (config.when_multi_lines.trim_empty_lines and current_line == '') then
                if config.when_multi_lines.remove_leading_spaces then
                    current_line = current_line:gsub('^%s+', '')
                end

                if config.replace_tab_by_space then
                    current_line = current_line:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
                end

                -- Apply multi-line gsub if a pattern is provided
                if config.when_multi_lines.gsub_pattern ~= '' then
                    current_line =
                        current_line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)
                end

                table.insert(formatted_lines, current_line)
            end
        end

        if config.when_multi_lines.end_code then
            -- Append end_code. Note: This adds it as a new "line" in the table.
            -- If end_code is just '\r', it means the last actual code line should be followed by CR.
            -- If `join_lines_with_cr` is true on Windows, this structure gets flattened.
            table.insert(formatted_lines, config.when_multi_lines.end_code)
        end

        -- On Windows, if configured, concatenate all parts with '\r' to form a single string.
        -- This is to ensure correct line endings when sending to some REPLs via `chansend`.
        if is_win32 and config.os.windows.join_lines_with_cr then
            formatted_lines = { table.concat(formatted_lines, '\r') }
        end

        return formatted_lines
    end
end

-- Predefined formatter: Trims empty lines from multi-line input.
M.formatter.trim_empty_lines = M.formatter.factory {
    when_multi_lines = {
        trim_empty_lines = true,
    },
}

-- Predefined formatter: Implements bracketed paste mode.
-- Sends escape codes to tell the terminal/REPL to treat the pasted text literally.
-- Includes a final carriage return.
M.formatter.bracketed_pasting = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~', -- Start bracketed paste mode.
        end_code = '\27[201~\r', -- End bracketed paste mode and send CR.
    },
}

-- Predefined formatter: Implements bracketed paste mode without a final new line/carriage return.
M.formatter.bracketed_pasting_no_final_new_line = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~', -- Start bracketed paste mode.
        end_code = '\27[201~', -- End bracketed paste mode.
    },
}

--- Processes the source command to potentially add a commented first line as a log.
-- This is used when `print_1st_line_on_source` is enabled in the configuration.
-- @param initial_source_command string The initial command string generated for sourcing (e.g., `source "tempfile"`).
-- @param strings table A list of the original code lines being sent.
-- @param source_syntax_key string The key for the source syntax (e.g., 'python', 'R') used to find the comment prefix.
-- @return string The potentially modified source command string, with an appended comment if applicable.
local function append_source_log(initial_source_command, strings, source_syntax_key)
    local comment_to_send_to_repl

    -- Check if the feature to print the first line is enabled in the plugin's configuration.
    if M._config.print_1st_line_on_source then
        -- Get the specific comment prefix for the given source syntax from the configuration.
        local comment_prefix = M._config.comment_prefixes[source_syntax_key]
        -- Only proceed if a comment_prefix is defined for this source_syntax.
        if comment_prefix then
            local first_non_empty_line = 'YAREPL' -- Default text in case no non-empty line is found.
            -- Determine the final prefix, ensuring a space if the prefix isn't empty and doesn't end with one.
            local final_prefix = comment_prefix
            if #comment_prefix > 0 and comment_prefix:sub(-1) ~= ' ' then
                final_prefix = comment_prefix .. ' '
            end
            -- Find the first non-empty line from the original code lines.
            for _, line in ipairs(strings) do
                local trimmed_line = vim.fn.trim(line) -- Trim whitespace from the line.
                if #trimmed_line > 0 then
                    first_non_empty_line = trimmed_line
                    break -- Found the first non-empty line.
                end
            end
            -- Format the comment string with the prefix, current time, and the first non-empty line.
            comment_to_send_to_repl = string.format('%s%s - %s', final_prefix, os.date '%H:%M:%S', first_non_empty_line)
        end
    end
    -- If a comment was generated, append it (with a newline) to the initial source command.
    if comment_to_send_to_repl then
        return initial_source_command .. '\n' .. comment_to_send_to_repl
    else
        -- Otherwise, return the original source command.
        return initial_source_command
    end
end

--- Sends a list of strings (lines of code) to a specified REPL.
--- This is the core function for dispatching code to REPLs.
---@param id number The ID of the REPL. If 0, tries to find the REPL attached to `bufnr` or defaults to ID 1.
---@param name string? The name of the REPL type to find (e.g., "python"). Overrides ID if specified.
---@param bufnr number? The buffer number from which to find an attached REPL. Defaults to current buffer if nil/0.
---@param strings string[] A list of strings (lines) to send.
---@param use_formatter boolean? Whether to apply the configured formatter. Defaults to true.
---@param source_content boolean? Whether to treat content as needing sourcing (e.g., wrapping in `source file` command). Defaults to false.
M._send_strings = function(id, name, bufnr, strings, use_formatter, source_content)
    if use_formatter == nil then
        use_formatter = true
    end
    if bufnr == nil or bufnr == 0 then
        bufnr = api.nvim_get_current_buf() -- Default to current buffer if not specified.
    end

    local repl = M._get_repl(id, name, bufnr) -- Resolve the target REPL.

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local meta = M._config.metas[repl.name]
    if source_content then
        local source_syntax = M.source_syntaxes[meta.source_syntax] or meta.source_syntax

        if not source_syntax then
            vim.notify(
                'No source syntax or source function is available for '
                    .. repl.name
                    .. '. Fallback to send string directly.'
            )
            -- Proceed without sourcing if no syntax defined, effectively like direct send.
        end

        local content = table.concat(strings, '\n') -- Join lines into a single content string.
        local source_command_sent_to_repl

        if type(source_syntax) == 'string' then
            -- If source_syntax is a string template, process it.
            source_command_sent_to_repl = M.source_file_with_source_syntax(content, source_syntax)
        elseif type(source_syntax) == 'function' then
            -- If source_syntax is a function, call it.
            source_command_sent_to_repl = source_syntax(content)
        end

        if source_command_sent_to_repl and source_command_sent_to_repl ~= '' then
            -- If a source command was generated, potentially log it and update `strings` to be this command.
            source_command_sent_to_repl = append_source_log(source_command_sent_to_repl, strings, meta.source_syntax)
            strings = vim.split(source_command_sent_to_repl, '\n') -- Split command into lines for chansend.
        else
            -- If no source command could be generated (e.g. source_syntax was nil or returned empty),
            -- the original `strings` will be sent directly, effectively falling back.
        end
    end

    if use_formatter then
        -- Apply the configured formatter for the REPL type.
        strings = meta.formatter(strings)
    end

    -- Determine if a delayed CR is needed using the more flexible logic from the remote.
    -- It checks the specific REPL's config first, then falls back to the OS-wide setting.
    local send_delayed_final_cr = meta.send_delayed_final_cr
    if send_delayed_final_cr == nil then
        if is_win32 and M._config.os.windows.send_delayed_final_cr then
            send_delayed_final_cr = true
        end
    end

    fn.chansend(repl.term, strings) -- Send the main code block.

    if send_delayed_final_cr then
        vim.defer_fn(function()
            if repl_is_valid(repl) then
                fn.chansend(repl.term, '\r')
            end
        end, 200)
    end

    -- If configured, scroll the REPL window to the bottom after sending.
    if M._config.scroll_to_bottom_after_sending then
        repl_win_scroll_to_bottom(repl)
    end
end

-- Internal function for the send operator.
-- This function is set to `vim.go.operatorfunc` to enable custom operator motions.
-- @param motion string|nil The motion command (e.g., 'ip', 'iw'). Nil if called for dot-repeat.
M._send_operator_internal = function(motion)
    -- Hack: allow dot-repeat. If motion is nil, it means we are in a dot-repeat scenario.
    -- We re-assign the operatorfunc and feedkeys `g@` to re-trigger the operator.
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'yarepl'._send_operator_internal]]
        api.nvim_feedkeys('g@', 'ni', false) -- 'n' for noremap, 'i' for insert mode style keys.
    end

    -- Get REPL target information from buffer-local variables, which are set by the M.commands.send_operator function.
    local id = vim.b[0].repl_id -- Target REPL ID.
    local name = vim.b[0].closest_repl_name -- Target REPL name.
    local current_bufnr = api.nvim_get_current_buf()

    local lines = get_lines 'operator' -- Get lines based on the operator motion.

    if #lines == 0 then
        vim.notify 'No motion!' -- Nothing selected by the motion.
        return
    end

    M._send_strings(id, name, current_bufnr, lines) -- Send the extracted lines.
end

-- Internal function for the source operator.
-- Similar to _send_operator_internal, but sets the `source_content` flag to true.
-- @param motion string|nil The motion command. Nil if called for dot-repeat.
M._source_operator_internal = function(motion)
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'yarepl'._source_operator_internal]]
        api.nvim_feedkeys('g@', 'ni', false)
    end

    local id = vim.b[0].repl_id
    local name = vim.b[0].closest_repl_name
    local current_bufnr = api.nvim_get_current_buf()

    local lines = get_lines 'operator'

    if #lines == 0 then
        vim.notify 'No motion!'
        return
    end

    M._send_strings(id, name, current_bufnr, lines, nil, true) -- Send lines with source_content = true.
end

-- Helper function to run a Vim command with a preceding count (vim.v.count).
-- @param cmd string The command to run (without the count).
local function run_cmd_with_count(cmd)
    vim.cmd(string.format('%d%s', vim.v.count, cmd))
end

-- Helper function to create a Vim command-line expression that includes the count.
-- Used for keymaps that need to construct a command dynamically.
-- <C-U> (\21) clears any existing range in the command line.
-- @param cmd string The command string (e.g., "REPLExec ").
-- @return string The command-line expression (e.g., ":\213REPLExec ").
local function partial_cmd_with_count_expr(cmd)
    return ':\21' .. vim.v.count .. cmd
end

--- A helper function to find a REPL based on command options and execute an action.
--- It handles the boilerplate of resolving the REPL and notifying the user if it's not found.
---@param opts table The command options table (containing count, args).
---@param action function A function to execute if a valid REPL is found. It receives the repl object.
local function _with_repl(opts, action)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    action(repl)
end

-- Adds keymaps for REPL commands.
-- Can create generic keymaps or keymaps specific to a REPL type (`meta_name`).
-- @param meta_name string|nil The name of the REPL type for specific keymaps (e.g., "python").
-- If nil, creates generic keymaps.
local function add_keymap(meta_name)
    -- Sanitize meta_name for use in <Plug> mapping names.
    if meta_name then
        meta_name = meta_name:gsub('[^%w-_]', '-') -- Replace non-alphanumeric characters (except - and _) with a dash.
    end

    local suffix = meta_name and ('-' .. meta_name) or '' -- Suffix for <Plug> mapping (e.g., "-python").

    -- List of commands and their default modes for which keymaps are generated.
    local mode_commands = {
        { 'n', 'REPLStart' },
        { 'n', 'REPLFocus' },
        { 'n', 'REPLHide' },
        { 'n', 'REPLHideOrFocus' },
        { 'n', 'REPLSendLine' },
        { 'n', 'REPLSendOperator' }, -- Operator-pending mapping
        { 'v', 'REPLSendVisual' }, -- Visual mode mapping
        { 'n', 'REPLSourceOperator' }, -- Operator-pending mapping for sourcing
        { 'v', 'REPLSourceVisual' }, -- Visual mode mapping for sourcing
        { 'n', 'REPLClose' },
    }

    for _, spec in ipairs(mode_commands) do
        api.nvim_set_keymap(spec[1], string.format('<Plug>(%s%s)', spec[2], suffix), '', {
            noremap = true,
            callback = function()
                if meta_name then
                    -- If specific REPL, call command with count and meta_name argument.
                    run_cmd_with_count(spec[2] .. ' ' .. meta_name)
                else
                    -- Generic command, call with count.
                    run_cmd_with_count(spec[2])
                end
            end,
        })
    end

    -- REPLExec keymap is handled separately as it needs `expr = true` to build a command-line string.
    api.nvim_set_keymap('n', string.format('<Plug>(%s%s)', 'REPLExec', suffix), '', {
        noremap = true,
        callback = function()
            if meta_name then
                -- Construct command like `:[count]REPLExec $meta_name `
                return partial_cmd_with_count_expr('REPLExec $' .. meta_name .. ' ')
            else
                -- Construct command like `:[count]REPLExec `
                return partial_cmd_with_count_expr 'REPLExec '
            end
        end,
        expr = true, -- The callback returns a string to be executed as a command-line.
    })
end

-- Command: Starts a new REPL or focuses an existing one.
-- `:REPLStart[!] [count] [name]`
-- `[count]` specifies the REPL ID. If 0 or not given, uses next available ID.
-- `[name]` specifies the REPL type (e.g., "python"). If empty, prompts user.
-- `[!뱅]` attaches the current buffer to the started/focused REPL.
M.commands.start = function(opts)
    local repl_name = opts.args -- Name of the REPL type from command arguments.
    -- Determine REPL ID: if count is 0 (no count given by user), use next available ID. Otherwise use user's count.
    local id = opts.count == 0 and (#M._repls + 1) or opts.count
    local repl = M._repls[id] -- Check if a REPL with this ID already exists.
    local current_bufnr = api.nvim_get_current_buf()

    if repl_is_valid(repl) then
        vim.notify(string.format('REPL %d already exists', id))
        focus_repl(repl) -- If REPL exists, just focus it.
        return
    end

    if repl_name == '' then
        -- If no REPL name provided, prompt the user to select one.
        local repls = {} -- Collect available REPL types from config.
        for name, _ in pairs(M._config.metas) do
            table.insert(repls, name)
        end

        vim.ui.select(repls, {
            prompt = 'Select REPL: ',
        }, function(choice) -- Callback for vim.ui.select.
            if not choice then
                return
            end -- User cancelled selection.

            repl_name = choice
            create_repl(id, repl_name) -- Create the selected REPL.

            if opts.bang then -- If `!` was used with the command.
                attach_buffer_to_repl(current_bufnr, M._repls[id]) -- Attach current buffer.
            end

            if M._config.scroll_to_bottom_after_sending then -- Initial scroll after creation.
                repl_win_scroll_to_bottom(M._repls[id])
            end
        end)
    else
        -- REPL name was provided as an argument.
        create_repl(id, repl_name)

        if opts.bang then
            attach_buffer_to_repl(current_bufnr, M._repls[id])
        end

        if M._config.scroll_to_bottom_after_sending then
            repl_win_scroll_to_bottom(M._repls[id])
        end
    end
end

-- Command: Cleans up invalid REPLs and re-orders existing ones.
-- Maps directly to the `repl_cleanup` function.
M.commands.cleanup = repl_cleanup

-- Command: Focuses on a specific REPL.
-- `:[count]REPLFocus [name]`
-- `[count]` specifies REPL ID. If 0/nil, uses attached REPL or ID 1.
-- `[name]` specifies REPL type.
M.commands.focus = function(opts)
    _with_repl(opts, function(repl)
        focus_repl(repl)
    end)
end

-- Command: Hides a specific REPL (closes its window).
-- `:[count]REPLHide [name]`
M.commands.hide = function(opts)
    _with_repl(opts, function(repl)
        local bufnr = repl.bufnr
        local win = fn.bufwinid(bufnr)
        -- Close all windows associated with this REPL buffer.
        while win ~= -1 do
            api.nvim_win_close(win, true) -- Force close.
            win = fn.bufwinid(bufnr) -- Check if more windows exist for this buffer.
        end
    end)
end

-- Command: Toggles visibility of a REPL. If visible, hides it. If hidden, focuses it.
-- `:[count]REPLHideOrFocus [name]`
M.commands.hide_or_focus = function(opts)
    _with_repl(opts, function(repl)
        local bufnr = repl.bufnr
        local win = fn.bufwinid(bufnr)
        if win ~= -1 then
            -- REPL window is visible, so hide it.
            while win ~= -1 do
                api.nvim_win_close(win, true)
                win = fn.bufwinid(bufnr)
            end
        else
            -- REPL window is hidden, so focus (open) it.
            focus_repl(repl)
        end
    end)
end

-- Command: Closes a specific REPL (sends EOF/Ctrl-D to its terminal).
-- This typically terminates the REPL process.
-- `:[count]REPLClose [name]`
M.commands.close = function(opts)
    _with_repl(opts, function(repl)
        fn.chansend(repl.term, string.char(4)) -- Send EOT (End of Transmission, Ctrl-D).
    end)
end
-- Command: Swaps two REPL instances by their IDs.
-- `:REPLSwap [id1] [id2]`
-- If IDs are not provided, prompts the user to select them.
M.commands.swap = function(opts)
    local id_1 = tonumber(opts.fargs[1]) -- First ID from arguments.
    local id_2 = tonumber(opts.fargs[2]) -- Second ID from arguments.

    if id_1 ~= nil and id_2 ~= nil then
        repl_swap(id_1, id_2) -- If both IDs provided, perform swap.
        return
    end

    -- Collect IDs of all active REPLs for selection.
    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end
    table.sort(repl_ids) -- Sort for consistent display.

    if #repl_ids < 2 then
        vim.notify 'Not enough REPLs to swap.'
        return
    end

    if id_1 == nil then
        -- Prompt for the first REPL ID if not provided.
        vim.ui.select(repl_ids, {
            prompt = 'select first REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(selected_id1)
            if not selected_id1 then
                return
            end

            -- Prompt for the second REPL ID.
            vim.ui.select(repl_ids, {
                prompt = 'select second REPL',
                format_item = function(item)
                    return item .. ' ' .. M._repls[item].name
                end,
            }, function(selected_id2)
                if not selected_id2 then
                    return
                end
                if selected_id1 == selected_id2 then
                    vim.notify 'Cannot swap a REPL with itself.'
                    return
                end
                repl_swap(selected_id1, selected_id2)
            end)
        end)
    elseif id_2 == nil then
        -- Prompt for the second REPL ID if only the first was provided.
        vim.ui.select(repl_ids, {
            prompt = 'select second REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(selected_id2)
            if not selected_id2 then
                return
            end
            if id_1 == selected_id2 then
                vim.notify 'Cannot swap a REPL with itself.'
                return
            end
            repl_swap(id_1, selected_id2)
        end)
    end
end

-- Command: Attaches the current buffer to a REPL.
-- `:[count]REPLAttachBufferToREPL[! ]`
-- `[count]` specifies the REPL ID. If 0/nil, prompts user.
-- `[!뱅]` detaches the current buffer if it's already attached (acts as detach).
M.commands.attach_buffer = function(opts)
    local current_buffer = api.nvim_get_current_buf()

    if opts.bang then
        -- If `!` is used, detach the current buffer from any REPL.
        M._bufnrs_to_repls[current_buffer] = nil
        vim.notify('Buffer ' .. current_buffer .. ' detached from REPL.')
        return
    end

    local repl_id = opts.count -- REPL ID from count.

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        if repl_is_valid(M._repls[id]) then -- Only list valid REPLs
            table.insert(repl_ids, id)
        end
    end
    table.sort(repl_ids)

    if #repl_ids == 0 then
        vim.notify 'No active REPLs to attach to.'
        return
    end

    if repl_id == 0 then -- No count provided, prompt user.
        vim.ui.select(repl_ids, {
            prompt = 'select REPL that you want to attach to',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id)
            if not id then
                return
            end
            attach_buffer_to_repl(current_buffer, M._repls[id])
            vim.notify('Buffer ' .. current_buffer .. ' attached to REPL ' .. id .. ' (' .. M._repls[id].name .. ').')
        end)
    else
        -- Count provided, try to attach to that REPL ID.
        if M._repls[repl_id] and repl_is_valid(M._repls[repl_id]) then
            attach_buffer_to_repl(current_buffer, M._repls[repl_id])
            vim.notify(
                'Buffer ' .. current_buffer .. ' attached to REPL ' .. repl_id .. ' (' .. M._repls[repl_id].name .. ').'
            )
        else
            vim.notify('REPL with ID ' .. repl_id .. ' not found or is invalid.')
        end
    end
end

-- Command: Detaches the current buffer from any REPL it might be attached to.
-- `:REPLDetachBufferToREPL`
M.commands.detach_buffer = function()
    local current_buffer = api.nvim_get_current_buf()
    if M._bufnrs_to_repls[current_buffer] then
        M._bufnrs_to_repls[current_buffer] = nil
        vim.notify('Buffer ' .. current_buffer .. ' detached from REPL.')
    else
        vim.notify('Buffer ' .. current_buffer .. ' was not attached to any REPL.')
    end
end

-- Command: Sends the visually selected text to a REPL.
-- `:[count]REPLSendVisual [name]`
M.commands.send_visual = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    api.nvim_feedkeys('\27', 'nx', false) -- Exit visual mode. '\27' is Escape.

    local lines = get_lines 'visual' -- Get lines from the visual selection.

    if #lines == 0 then
        vim.notify 'No visual range!'
        return
    end

    M._send_strings(id, name, current_buffer, lines, nil, opts.source_content)
end

-- Command: Sends the current line to a REPL.
-- `:[count]REPLSendLine [name]`
M.commands.send_line = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local line = api.nvim_get_current_line() -- Get the current line content.

    M._send_strings(id, name, current_buffer, { line }) -- Send as a single-line table.
end

-- Command: Sets up an operator to send selected text (via motion) to a REPL.
-- `:[count]REPLSendOperator [name]`
-- After this command, a motion is expected (e.g., `ip` for inner paragraph).
M.commands.send_operator = function(opts)
    local repl_name = opts.args
    local id = opts.count

    -- Store target REPL info in buffer-local variables for the internal operator function.
    if repl_name ~= '' then
        vim.b[0].closest_repl_name = repl_name
    else
        vim.b[0].closest_repl_name = nil
    end

    if id ~= 0 then
        vim.b[0].repl_id = id
    else
        vim.b[0].repl_id = nil
    end

    -- Set the appropriate internal operator function based on whether sourcing is intended.
    vim.go.operatorfunc = opts.source_content and [[v:lua.require'yarepl'._source_operator_internal]]
        or [[v:lua.require'yarepl'._send_operator_internal]]
    api.nvim_feedkeys('g@', 'ni', false) -- Trigger the operator mode.
end

-- Command: Sources the visually selected text in a REPL.
-- This is a convenience wrapper around `send_visual` with `source_content = true`.
-- `:[count]REPLSourceVisual [name]`
M.commands.source_visual = function(opts)
    opts.source_content = true
    M.commands.send_visual(opts)
end

-- Command: Sets up an operator to source selected text (via motion) in a REPL.
-- This is a convenience wrapper around `send_operator` with `source_content = true`.
-- `:[count]REPLSourceOperator [name]`
M.commands.source_operator = function(opts)
    opts.source_content = true
    M.commands.send_operator(opts)
end

-- Command: Executes a given string directly in a REPL.
-- `:[count]REPLExec [$repl_name] <command_string>`
-- If `$repl_name` is given (e.g., `$python`), targets that specific REPL type.
-- Otherwise, uses default REPL resolution (ID, attached buffer).
M.commands.exec = function(opts)
    local first_arg = opts.fargs[1] -- First "full argument" (space-separated).
    local current_buffer = api.nvim_get_current_buf()
    local name = '' -- Target REPL name if specified with $.
    local command = opts.args -- The full command string to execute.

    -- Check if the first argument specifies a REPL type like `$python`.
    for repl_name_iter, _ in pairs(M._config.metas) do
        if '$' .. repl_name_iter == first_arg then
            name = first_arg:sub(2) -- Extract "python" from "$python".
            break
        end
    end

    if name ~= '' then
        -- If a REPL name was specified, remove it from the command string.
        command = command:gsub('^%$' .. name .. '%s+', '')
    end

    local id = opts.count
    local command_list = vim.split(command, '\r') -- Split command by CR for multi-line exec.

    M._send_strings(id, name, current_buffer, command_list)
end

--- Creates a temporary file with the given content.
--- The file is scheduled for deletion after a short delay unless `keep_file` is true.
---@param content string The content to write to the temporary file.
---@param keep_file boolean? If true, the temporary file will not be automatically deleted.
---@return string? The file name (path) of the temporary file, or nil on failure.
function M.make_tmp_file(content, keep_file) -- Added keep_file parameter
    local tmp_file = os.tmpname() .. '_yarepl'
    local f = io.open(tmp_file, 'w+')
    if f == nil then
        vim.notify('Cannot open temporary message file: ' .. tmp_file, vim.log.levels.ERROR)
        return nil -- Return nil on failure
    end

    f:write(content)
    f:close()

    if not keep_file then
        vim.defer_fn(function()
            os.remove(tmp_file)
        end, 5000)
    end
    return tmp_file
end

--- Creates a temporary file with content and formats a `source_syntax` string.
--- The `source_syntax` string should contain `{{file}}` which will be replaced
--- by the actual temporary file path.
---@param content string The content to write to the temporary file.
---@param source_syntax string The syntax string for sourcing, e.g., 'source "{{file}}"'.
---@param keep_file boolean? If true, the temporary file will not be automatically deleted.
---@return string? The command string to source the file, or nil on failure to create the file.
function M.source_file_with_source_syntax(content, source_syntax, keep_file)
    local tmp_file = M.make_tmp_file(content, keep_file) -- Call the modified function
    if not tmp_file then
        return nil
    end

    -- replace {{file}} placeholder with the temp file name
    source_syntax = source_syntax:gsub('{{file}}', tmp_file)
    return source_syntax
end

--- Table storing definitions for how to "source" content in different REPLs.
--- Keys are syntax names (e.g., "python", "bash").
--- Values can be:
--- 1. A string template: `{{file}}` will be replaced with the path to a temporary file containing the code.
--- 2. A function: Takes the code content (string) and should return the command string to execute in the REPL.
---@type table<string, string | fun(str: string): string?>
M.source_syntaxes = {}

-- Python: Execute content from a temporary file using `exec(compile(...))`.
-- The temporary file is kept because PDB (Python Debugger) might need it for context.
M.source_syntaxes.python = function(str)
    return M.source_file_with_source_syntax(
        str,
        'exec(compile(open("{{file}}", "r").read(), "{{file}}", "exec"))',
        true -- keep_file = true
    )
end

-- IPython: Use `%run -i` to execute content from a temporary file.
-- The `-i` flag ensures the script runs in the current IPython namespace.
-- The temporary file is kept.
M.source_syntaxes.ipython = function(str)
    return M.source_file_with_source_syntax(str, '%run -i "{{file}}"', true) -- keep_file = true
end

-- Bash: Source the temporary file directly.
M.source_syntaxes.bash = 'source "{{file}}"'
-- R: Use `eval(parse(text = readr::read_file(...)))` assuming `readr` package is available.
M.source_syntaxes.R = 'eval(parse(text = readr::read_file("{{file}}")))'
-- aichat: Uses a custom `.file` command for sourcing.
M.source_syntaxes.aichat = '.file "{{file}}"'

-- Setup function for the plugin.
-- Merges user options with defaults and initializes commands and keymaps.
-- @param opts table User-provided configuration options.
M.setup = function(opts)
    -- Deep extend the default configuration with user options.
    M._config = vim.tbl_deep_extend('force', default_config(), opts or {})

    -- Process REPL meta configurations.
    for name, meta in pairs(M._config.metas) do
        if not meta then
            -- If user explicitly sets a builtin meta to false/nil, remove it.
            M._config.metas[name] = nil
        else
            -- Convert string formatter names in meta to actual formatter functions.
            if meta.formatter and type(meta.formatter) == 'string' then
                meta.formatter = get_formatter(meta.formatter)
            elseif not meta.formatter then
                -- Fallback to a very basic formatter if none is specified for a meta
                meta.formatter = function(lines)
                    return lines
                end
            end
        end
    end

    add_keymap() -- Add generic <Plug> keymaps.

    -- Add specific <Plug> keymaps for each configured REPL type.
    for meta_name, _ in pairs(M._config.metas) do
        if M._config.metas[meta_name] then -- Ensure meta wasn't removed.
            add_keymap(meta_name)
        end
    end
end

-- User Commands Definition
-- These commands are exposed to the Neovim user via :CommandName

api.nvim_create_user_command('REPLStart', M.commands.start, {
    count = true, -- Allows a [count] prefix, e.g., :2REPLStart
    bang = true, -- Allows a [!] suffix, e.g., :REPLStart!
    nargs = '?', -- Optional argument (REPL name)
    complete = function() -- Autocompletion for REPL name argument.
        local metas = {}
        for name, _ in pairs(M._config.metas) do
            if M._config.metas[name] then
                table.insert(metas, name)
            end
        end
        return metas
    end,
    desc = [[
Create REPL `[count]` (or next available) of type `[name]`.
If `[name]` is omitted, prompts for selection.
With `!`, attaches current buffer to the REPL.
Example: `:2REPLStart python` or `:REPLStart!`
]],
})

api.nvim_create_user_command(
    'REPLCleanup',
    M.commands.cleanup,
    { desc = 'Clean invalid REPLs and rearrange the REPLs order.' }
)

api.nvim_create_user_command('REPLFocus', M.commands.focus, {
    count = true,
    nargs = '?',
    desc = [[
Focus on REPL `[count]` (or REPL attached to current buffer, or REPL 1) of type `[name]`.
Example: `:REPLFocus python` or `:2REPLFocus`
]],
})

api.nvim_create_user_command('REPLHide', M.commands.hide, {
    count = true,
    nargs = '?',
    desc = [[
Hide REPL `[count]` (or REPL attached to current buffer, or REPL 1) of type `[name]`.
Example: `:REPLHide python`
]],
})

api.nvim_create_user_command('REPLHideOrFocus', M.commands.hide_or_focus, {
    count = true,
    nargs = '?',
    desc = [[
Toggle visibility of REPL `[count]` (or REPL attached to current buffer, or REPL 1) of type `[name]`.
If visible, hides it. If hidden, focuses it.
]],
})

api.nvim_create_user_command('REPLClose', M.commands.close, {
    count = true,
    nargs = '?',
    desc = [[
Close REPL `[count]` (or REPL attached to current buffer, or REPL 1) of type `[name]` by sending EOF.
Example: `:REPLClose python`
]],
})

api.nvim_create_user_command('REPLSwap', M.commands.swap, {
    desc = [[Swap two REPLs. Prompts for IDs if not given as arguments. Example: `:REPLSwap 1 2`]],
    nargs = '*', -- 0, 1, or 2 arguments (REPL IDs)
})

api.nvim_create_user_command('REPLAttachBufferToREPL', M.commands.attach_buffer, {
    count = true,
    bang = true, -- `!` detaches the buffer.
    desc = [[
Attach current buffer to REPL `[count]`. Prompts if `[count]` is 0.
With `!`, detaches the current buffer from any REPL.
Example: `:2REPLAttachBufferToREPL` or `:REPLAttachBufferToREPL!`
]],
})

api.nvim_create_user_command('REPLDetachBufferToREPL', M.commands.detach_buffer, {
    -- `count` here is likely a typo in original, as detach usually doesn't need it.
    -- M.commands.detach_buffer doesn't use count.
    desc = [[Detach current buffer from any REPL it is attached to.]],
})

api.nvim_create_user_command('REPLSendVisual', M.commands.send_visual, {
    count = true,
    nargs = '?',
    -- No range attribute means it's not directly for :'<,'>REPLSendVisual, but used by <Plug> mapping from visual mode.
    desc = [[
Send visually selected text to REPL `[count]` (or attached/default REPL) of type `[name]`.
Typically used via a visual mode mapping.
]],
})

api.nvim_create_user_command('REPLSendLine', M.commands.send_line, {
    count = true,
    nargs = '?',
    desc = [[
Send current line to REPL `[count]` (or attached/default REPL) of type `[name]`.
Example: `:REPLSendLine`
]],
})

api.nvim_create_user_command('REPLSendOperator', M.commands.send_operator, {
    count = true,
    nargs = '?',
    -- This command sets up an operator; it doesn't take a range itself.
    desc = [[
Operator to send text (defined by subsequent motion) to REPL `[count]` (or attached/default) of type `[name]`.
Example: Map `gs` to this, then use `gsip` to send inner paragraph.
]],
})

api.nvim_create_user_command('REPLSourceVisual', M.commands.source_visual, {
    count = true,
    nargs = '?',
    desc = [[
Source visually selected text in REPL `[count]` (or attached/default REPL) of type `[name]`.
Typically used via a visual mode mapping.
]],
})

api.nvim_create_user_command('REPLSourceOperator', M.commands.source_operator, {
    count = true,
    nargs = '?',
    desc = [[
Operator to source text (defined by subsequent motion) in REPL `[count]` (or attached/default) of type `[name]`.
Example: Map `gS` to this, then use `gSip` to source inner paragraph.
]],
})

api.nvim_create_user_command('REPLExec', M.commands.exec, {
    count = true,
    nargs = '*', -- Takes multiple arguments as the command string.
    desc = [[
Execute a `<command_string>` in REPL `[count]` (or attached/default).
Can target specific REPL type: `:REPLExec $python print("hello")`
Example: `:REPLExec print("Hello from YAREPL!")`
]],
})

return M
