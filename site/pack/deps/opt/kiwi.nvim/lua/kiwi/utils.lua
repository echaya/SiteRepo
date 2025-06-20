local utils = {}

-- Deeply merges two tables. `override` values take precedence over `base` values.
-- @param base (table): The base table.
-- @param override (table): The table with overrides.
-- @return (table): The merged table.
local function deep_merge(base, override)
	local result = vim.deepcopy(base)
	for k, v in pairs(override) do
		if type(v) == "table" and type(result[k]) == "table" and not vim.islist(v) then -- Use modern vim.islist
			result[k] = deep_merge(result[k], v)
		else
			result[k] = v
		end
	end
	return result
end

-- Setup wiki configuration
utils.setup = function(opts, config)
	opts = opts or {}

	local local_config = deep_merge(config, opts)
	for k, v in pairs(local_config) do
		config[k] = v
	end

	-- handle flatten wiki_dirs
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
		config.path = utils.get_wiki_path()
		config.wiki_dirs = nil
	end
	utils.ensure_directories(config)
end

-- Resolves a path string from the config into a full, absolute path.
-- @param path_str (string): The path from the configuration (e.g., "wiki" or "~/notes/wiki").
-- @return (string): The resolved absolute path.
local resolve_path = function(path_str)
	if not path_str or path_str == "" then
		return nil
	end

	local path_to_resolve
	if vim.fn.isabsolutepath(path_str) == 0 then
		path_to_resolve = vim.fs.joinpath(vim.loop.os_homedir(), path_str)
	else
		path_to_resolve = path_str
	end

	local expanded_path = vim.fn.fnamemodify(path_to_resolve, ":p")

	if vim.fn.isdirectory(expanded_path) ~= 1 then
		pcall(vim.fn.mkdir, expanded_path, "p")
		vim.notify("  " .. expanded_path .. " created.", vim.log.levels.INFO)
	end

	-- Always return the fully resolved, absolute path.
	return expanded_path
end

-- Get the default wiki_dir path
utils.get_wiki_path = function()
	return vim.fs.joinpath(vim.loop.os_homedir(), "wiki")
end

-- Create wiki wiki_dir
utils.ensure_directories = function(config)
	if config.wiki_dirs then
		for _, wiki_dir in ipairs(config.wiki_dirs) do
			wiki_dir.path = resolve_path(wiki_dir.path)
		end
	else
		config.path = resolve_path(config.path)
	end
end

-- Process a raw link target string.
local process_link_target = function(target)
	if not target or not target:match("%S") then
		return nil
	end

	local clean_target = target:match("^%s*(.-)%s*$")

	if not clean_target:match("^%a+://") and not clean_target:match("%.md$") then
		clean_target = clean_target .. ".md"
	end
	return clean_target
end

-- Finds all valid link targets on a single line of text.
local find_all_link_targets = function(line)
	local targets = {}

	for file in line:gmatch("%]%(<?([^)>]+)>?%)") do
		local processed = process_link_target(file)
		if processed then
			table.insert(targets, processed)
		end
	end

	for file in line:gmatch("%[%[([^]]+)%]%]") do
		local processed = process_link_target(file)
		if processed then
			table.insert(targets, processed)
		end
	end

	return targets
end

-- Checks if the cursor is on a link and returns the cleaned link target.
utils.is_link = function(cursor, line)
	cursor[2] = cursor[2] + 1
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
	-- --- Check for [[file]] ---
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

-- Clean up links that are broken
utils.cleanup_broken_links = function()
	local choice = vim.fn.confirm("Clean up all broken links from this page?", "&Yes\n&No")
	if choice ~= 1 then
		vim.notify("Kiwi: Link cleanup skipped.", vim.log.levels.INFO)
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
		local message = "Kiwi: Link cleanup complete.\nRemoved "
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
		vim.notify("Kiwi: No broken links were found.", vim.log.levels.INFO)
	end
end

-- Prompts the user to select a wiki from a list and executes a callback with the result.
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

-- Determines the correct wiki path and executes a callback.
utils.prompt_wiki_dir = function(config, on_complete)
	if not config.wiki_dirs or #config.wiki_dirs == 0 then
		vim.notify("Kiwi: No wiki wiki_dirs configured.", vim.log.levels.ERROR)
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

-- Scans a base path recursively to find all directories containing an index file.
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

-- Normalizes a file path for reliable comparison on any OS.
utils.normalize_path_for_comparison = function(path)
	if not path then
		return ""
	end
	return path:lower():gsub("\\", "/"):gsub("//", "/")
end

---Register a global internal keymap that wraps `rhs` to be repeatable.
---@param mode string|table keymap mode, see vim.keymap.set()
---@param lhs string lhs of the internal keymap to be created, should be in the form `<Plug>(...)`
---@param rhs function rhs of the keymap, see vim.keymap.set()
---@return string The name of a registered internal `<Plug>(name)` keymap. Make sure you use { remap = true }.
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
		-- Then, safely attempt to set up the repeat.
		pcall(vim.fn["repeat#set"], vim.api.nvim_replace_termcodes(lhs, true, true, true))
	end)
	return lhs
end

return utils
