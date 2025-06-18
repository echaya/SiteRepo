local utils = {}

---
-- Recursively merges two tables. Values in `override` take precedence.
-- @param base (table): The table to merge into.
-- @param override (table): The table with values to merge from.
-- @return (table): A new table containing the merged result.
--
local function deep_merge(base, override)
	local result = vim.deepcopy(base)
	for k, v in pairs(override) do
		if type(v) == "table" and type(result[k]) == "table" and not vim.islist(v) then
			result[k] = deep_merge(result[k], v)
		else
			result[k] = v
		end
	end
	return result
end

---
-- Merges user options with the default configuration and processes wiki directory paths.
-- @param opts (table): User-provided options.
-- @param config (table): The default configuration table.
--
utils.setup = function(opts, config)
	opts = opts or {}

	-- Merge user config into the default config.
	local local_config = deep_merge(config, opts)
	for k, v in pairs(local_config) do
		config[k] = v
	end

	-- Normalize the `wiki_dirs` structure for consistency.
	local user_dirs = config.wiki_dirs
	if user_dirs and type(user_dirs) == "table" then
		if user_dirs.path and user_dirs[1] == nil then
			user_dirs = { user_dirs }
		end
	end

	if user_dirs and type(user_dirs) == "table" and #user_dirs > 0 then
		config.wiki_dirs = user_dirs
		config.path = nil
	else
		-- Fallback to default path if no wiki_dirs are provided.
		config.path = utils.get_wiki_path()
		config.wiki_dirs = nil
	end
	utils.ensure_directories(config)
end

---
-- Resolves a configuration path string (e.g., "~/notes") into a full, absolute path.
-- Creates the directory if it does not exist.
-- @param path_str (string): The path string from the configuration.
-- @return (string|nil): The resolved absolute path, or nil if input is invalid.
--
utils.resolve_path = function(path_str)
	if not path_str or path_str == "" then
		return nil
	end

	-- Resolve path relative to home directory if it's not absolute.
	local path_to_resolve
	if vim.fn.isabsolutepath(path_str) == 0 then
		path_to_resolve = vim.fs.joinpath(vim.loop.os_homedir(), path_str)
	else
		path_to_resolve = path_str
	end

	local expanded_path = vim.fn.fnamemodify(path_to_resolve, ":p")

	-- Create the directory if it doesn't exist.
	if vim.fn.isdirectory(expanded_path) ~= 1 then
		pcall(vim.fn.mkdir, expanded_path, "p")
		vim.notify("  " .. expanded_path .. " created.", vim.log.levels.INFO)
	end

	return expanded_path
end

---
-- Gets the default wiki path, which is `~/wiki`.
-- @return (string): The default wiki path.
--
utils.get_wiki_path = function()
	return vim.fs.joinpath(vim.loop.os_homedir(), "wiki")
end

---
-- Ensures all configured wiki directories exist by resolving their paths.
-- @param config (table): The plugin configuration table.
--
utils.ensure_directories = function(config)
	if config.wiki_dirs then
		for _, wiki_dir in ipairs(config.wiki_dirs) do
			wiki_dir.path = utils.resolve_path(wiki_dir.path)
		end
	else
		config.path = utils.resolve_path(config.path)
	end
end

---
-- Processes a raw link target, cleaning it and appending `.md` if necessary.
-- @param target (string): The raw link target string (e.g., "my page").
-- @return (string|nil): The processed link target (e.g., "my_page.md"), or nil.
--
local process_link_target = function(target)
	if not target or not target:match("%S") then
		return nil
	end

	-- Trim whitespace.
	local clean_target = target:match("^%s*(.-)%s*$")

	-- Append .md extension if it's not a web link and doesn't have it.
	if not clean_target:match("^%a+://") and not clean_target:match("%.md$") then
		clean_target = clean_target .. ".md"
	end
	return clean_target
end

---
-- Finds all valid markdown link targets on a single line of text.
-- @param line (string): The line to search.
-- @return (table): A list of processed link targets found on the line.
--
local find_all_link_targets = function(line)
	local targets = {}

	-- Find standard markdown links: [text](target)
	for file in line:gmatch("%]%(<?([^)>]+)>?%)") do
		local processed = process_link_target(file)
		if processed then
			table.insert(targets, processed)
		end
	end

	-- Find wikilinks: [[target]]
	for file in line:gmatch("%[%[([^]]+)%]%]") do
		local processed = process_link_target(file)
		if processed then
			table.insert(targets, processed)
		end
	end

	return targets
end

---
-- Checks if the cursor is currently on a markdown link.
-- @param cursor (table): The cursor position `{row, col}`.
-- @param line (string): The content of the current line.
-- @return (string|nil): The processed link target if the cursor is on a link, otherwise nil.
--
utils.is_link = function(cursor, line)
	cursor[2] = cursor[2] + 1 -- Adjust to 1-based indexing for find.
	-- Pattern for [title](file)
	local pattern1 = "%[(.-)%]%(<?([^)>]+)>?%)"
	local start_pos1 = 1
	while true do
		local match_start, match_end, _, file = line:find(pattern1, start_pos1)
		if not match_start then
			break
		end
		start_pos1 = match_end + 1

		if cursor[2] >= match_start and cursor[2] <= match_end then
			return process_link_target(file)
		end
	end
	-- Pattern for [[file]]
	local pattern2 = "%[%[(.-)%]%]"
	local start_pos2 = 1
	while true do
		local match_start, match_end, file = line:find(pattern2, start_pos2)
		if not match_start then
			break
		end
		start_pos2 = match_end + 1

		if cursor[2] >= match_start and cursor[2] <= match_end then
			local processed_link = process_link_target(file)
			if processed_link then
				return "./" .. processed_link
			end
		end
	end

	return nil
end

---
-- Scans the current buffer for lines containing broken markdown links and removes them.
-- A link is considered broken if the target file does not exist.
--
utils.cleanup_broken_links = function()
	local choice = vim.fn.confirm("Clean up all broken links from this page?", "&Yes\n&No")
	if choice ~= 1 then
		vim.notify("neowiki: Link cleanup skipped.", vim.log.levels.INFO)
		return
	end

	local current_buf_path = vim.api.nvim_buf_get_name(0)
	local current_dir = vim.fn.fnamemodify(current_buf_path, ":p:h")
	local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local lines_to_keep = {}
	local deleted_lines_info = {}

	for i, line in ipairs(all_lines) do
		local has_broken_link = false
		local link_targets = find_all_link_targets(line)

		for _, target in ipairs(link_targets) do
			local full_target_path = vim.fn.fnamemodify(vim.fs.joinpath(current_dir, target), ":p")
			-- A link is broken if the target file isn't readable.
			if vim.fn.filereadable(full_target_path) == 0 then
				has_broken_link = true
				break
			end
		end

		if has_broken_link then
			table.insert(deleted_lines_info, "Line " .. i .. ": " .. line)
		else
			table.insert(lines_to_keep, line)
		end
	end

	if #deleted_lines_info > 0 then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines_to_keep)
		local message = "neowiki: Link cleanup complete.\nRemoved "
			.. #deleted_lines_info
			.. " line(s) with broken links:\n"
			.. table.concat(deleted_lines_info, "\n")
		vim.notify(message, vim.log.levels.INFO, {
			on_open = function(win)
				local width = vim.api.nvim_win_get_width(win)
				local height = #deleted_lines_info + 3
				vim.api.nvim_win_set_config(win, { height = height, width = math.min(width, 100) })
			end,
		})
	else
		vim.notify("neowiki: No broken links were found.", vim.log.levels.INFO)
	end
end

---
-- Displays a `vim.ui.select` prompt for the user to choose a wiki.
-- @param wiki_dirs (table): A list of configured wiki directory objects.
-- @param on_complete (function): Callback to execute with the selected wiki path.
--
utils.choose_wiki = function(wiki_dirs, on_complete)
	local items = {}
	for _, wiki_dir in ipairs(wiki_dirs) do
		table.insert(items, wiki_dir.name)
	end
	vim.ui.select(items, {
		prompt = "Select wiki:",
		format_item = function(item)
			return "  " .. item
		end,
	}, function(choice)
		if not choice then
			vim.notify("Wiki selection cancelled.", vim.log.levels.INFO)
			on_complete(nil)
			return
		end
		for _, wiki_dir in pairs(wiki_dirs) do
			if wiki_dir.name == choice then
				on_complete(wiki_dir.path)
				return
			end
		end
		vim.notify("Error: Could not find path for selected wiki.", vim.log.levels.ERROR)
		on_complete(nil)
	end)
end

---
-- Prompts the user to select a wiki if multiple are configured; otherwise,
-- directly provides the path to the single configured wiki.
-- @param config (table): The plugin configuration table.
-- @param on_complete (function): Callback to execute with the resulting wiki path.
--
utils.prompt_wiki_dir = function(config, on_complete)
	if not config.wiki_dirs or #config.wiki_dirs == 0 then
		vim.notify("neowiki: No wiki directories configured.", vim.log.levels.ERROR)
		if on_complete then
			on_complete(nil)
		end
		return
	end

	if #config.wiki_dirs > 1 then
		utils.choose_wiki(config.wiki_dirs, on_complete)
	else
		on_complete(config.wiki_dirs[1].path)
	end
end

---
-- Recursively finds all directories within a base path that contain a specific index file.
-- @param search_path (string): The base path to search from.
-- @param index_filename (string): The name of the index file (e.g., "index.md").
-- @return (table): A list of absolute paths to the directories containing the index file.
--
utils.find_nested_roots = function(search_path, index_filename)
	local roots = {}
	if not search_path or search_path == "" then
		return roots
	end

	local search_pattern = vim.fs.joinpath("**", index_filename)
	local index_files = vim.fn.globpath(search_path, search_pattern, false, true)

	for _, file_path in ipairs(index_files) do
		local root_path = vim.fn.fnamemodify(file_path, ":p:h")
		table.insert(roots, root_path)
	end

	return roots
end

---
-- Normalizes a file path for case-insensitive and slash-consistent comparison.
-- @param path (string): The file path to normalize.
-- @return (string): The normalized path.
--
utils.normalize_path_for_comparison = function(path)
	if not path then
		return ""
	end
	return path:lower():gsub("\\", "/"):gsub("//", "/")
end

---
-- Wraps a function in a keymap that can be repeated with the `.` operator.
-- It leverages the `repeat.vim` plugin functionality.
-- @param mode (string|table): The keymap mode (e.g., "n", "v").
-- @param lhs (string): The left-hand side of the mapping (must start with `<Plug>`).
-- @param rhs (function): The function to execute.
-- @return (string): The `lhs` of the mapping.
--
utils.make_repeatable = function(mode, lhs, rhs)
	vim.validate({
		mode = { mode, { "string", "table" } },
		rhs = { rhs, "function" },
		lhs = { lhs, "string" },
	})
	if not vim.startswith(lhs, "<Plug>") then
		error("`lhs` should start with `<Plug>`, given: " .. lhs)
	end
	vim.keymap.set(mode, lhs, function()
		rhs()
		-- Make the action repeatable with '.'
		pcall(vim.fn["repeat#set"], vim.api.nvim_replace_termcodes(lhs, true, true, true))
	end)
	return lhs
end

return utils
