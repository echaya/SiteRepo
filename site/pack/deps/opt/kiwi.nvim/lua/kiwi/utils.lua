local utils = {}

-- Setup wiki folder
utils.setup = function(opts, config)
	if opts and #opts > 0 then
		config.folders = opts
	else
		config.path = utils.get_wiki_path()
		config.folders = nil -- Clear folders to ensure consistent state.
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

-- Get the default Wiki folder path
utils.get_wiki_path = function()
	return vim.fs.joinpath(vim.loop.os_homedir(), "wiki")
end

-- Create wiki folder
utils.ensure_directories = function(config)
	if config.folders then
		for _, folder in ipairs(config.folders) do
			folder.path = resolve_path(folder.path)
		end
	else
		config.path = resolve_path(config.path)
	end
end

-- Check if the cursor is on a link on the line
utils.is_link = function(cursor, line)
	cursor[2] = cursor[2] + 1 -- because vim counts from 0 but lua from 1

	-- Pattern for [title](file)
	local pattern1 = "%[(.-)%]%(<?([^)>]+)>?%)"
	local start_pos = 1
	while true do
		local match_start, match_end, _, file = line:find(pattern1, start_pos)
		if not match_start then
			break
		end
		start_pos = match_end + 1 -- Move past the current match
		file = utils._is_cursor_on_file(cursor, file, match_start, match_end)
		if file then
			return file
		end
	end

	-- Pattern for [[file]]
	local pattern2 = "%[%[(.-)%]%]"
	start_pos = 1
	while true do
		local match_start, match_end, file = line:find(pattern2, start_pos)
		if not match_start then
			break
		end
		start_pos = match_end + 1 -- Move past the current match
		file = utils._is_cursor_on_file(cursor, file, match_start, match_end)
		if file then
			return "./" .. file
		end
	end

	return nil
end

-- Private function to determine if cursor is placed on a valid file
utils._is_cursor_on_file = function(cursor, file, match_start, match_end)
	if cursor[2] >= match_start and cursor[2] <= match_end then
		if not file:match("%.md$") then
			file = file .. ".md"
		end
		return file
	end
end

-- Prompts the user to select a wiki from a list and executes a callback with the result.
-- @param folders (table): A list of folder configuration tables.
-- @param on_complete (function): A callback function to execute with the chosen path.
--                                It receives one argument: the full path string, or nil if canceled.
utils.choose_wiki = function(folders, on_complete)
	-- Create a stable, indexed list of folder names for the UI select.
	local items = {}
	for _, folder in ipairs(folders) do
		table.insert(items, folder.name)
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
		for _, folder in pairs(folders) do
			if folder.name == choice then
				on_complete(folder.path)
				return
			end
		end
		vim.notify("Error: Could not find path for selected wiki.", vim.log.levels.ERROR)
		on_complete(nil)
	end)
end

-- Determines the correct wiki path and executes a callback.
-- If multiple wikis exist, it prompts the user. If one, it uses it directly.
-- @param config (table): The plugin's configuration table.
-- @param on_complete (function): The callback to execute with the final path.
utils.prompt_folder = function(config, on_complete)
	if not config.folders or #config.folders == 0 then
		vim.notify("Kiwi: No wiki folders configured.", vim.log.levels.ERROR)
		if on_complete then
			on_complete(nil)
		end
		return
	end

	if #config.folders > 1 then
		utils.choose_wiki(config.folders, on_complete)
	else
		on_complete(config.folders[1].path)
	end
end

-- Scans a base path recursively to find all directories containing an index file.
-- @param search_path (string): The top-level directory to begin the scan from.
-- @param index_filename (string): The name of the index file to locate.
-- @return (table): A list of absolute paths to the directories containing the index file.
utils.find_nested_roots = function(search_path, index_filename)
	local roots = {}
	if not search_path or search_path == "" then
		return roots
	end

	-- The '**' pattern recursively searches all subdirectories at any depth.
	local search_pattern = vim.fs.joinpath("**", index_filename)
	-- The third 'true' enables list output, the second 'true' handles path separators. (Note: Signature is path, expr, keep_empty, list)
	local index_files = vim.fn.globpath(search_path, search_pattern, false, true)

	for _, file_path in ipairs(index_files) do
		local root_path = vim.fn.fnamemodify(file_path, ":p:h")
		table.insert(roots, root_path)
	end

	return roots
end

-- Normalizes a file path for reliable comparison on any OS.
-- @param path (string) The file path to normalize.
-- @return (string) The normalized path.
utils.normalize_path_for_comparison = function(path)
	if not path then
		return ""
	end
	return path:lower():gsub("\\", "/"):gsub("//", "/")
end

return utils
