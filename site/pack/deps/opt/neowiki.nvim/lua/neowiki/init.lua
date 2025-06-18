---@class neowiki
local config = require("neowiki.config")
local utils = require("neowiki.utils")
local wiki = require("neowiki.wiki")
local todo = require("neowiki.todo")

local M = {}

--- Public API ---

M.VERSION = "0.1.0"
M.open_wiki = wiki.open_wiki
M.open_wiki_in_new_tab = wiki.open_wiki_in_new_tab

--- Private Functions ---

---
-- Sets up buffer-local keymaps if the current buffer is a markdown file
-- located within a configured wiki directory.
-- This function is triggered by the BufEnter autocommand.
--
local function setup_keymaps_for_wiki_file()
	if vim.bo.filetype ~= "markdown" then
		return
	end

	local buf_path = vim.api.nvim_buf_get_name(0)
	if not buf_path or buf_path == "" then
		return
	end
	local current_file_path = vim.fn.fnamemodify(buf_path, ":p")
	local normalized_current_path = utils.normalize_path_for_comparison(current_file_path)
	local current_filename = vim.fn.fnamemodify(buf_path, ":t"):lower()

	-- Find all wiki roots that contain the current file.
	local matching_wikis = {}
	for _, wiki_info in ipairs(config.processed_wiki_paths) do
		local dir_to_check = wiki_info.normalized
		if not dir_to_check:find("/$") then
			dir_to_check = dir_to_check .. "/"
		end

		if normalized_current_path:find(dir_to_check, 1, true) == 1 then
			table.insert(matching_wikis, wiki_info)
		end
	end

	if #matching_wikis == 0 then
		return
	end

	-- Sort matches by path length, descending, to find the most specific match.
	table.sort(matching_wikis, function(a, b)
		return #a.normalized > #b.normalized
	end)

	-- Determine the correct root directory for the wiki.
	local wiki_index_dir = nil
	if current_filename == "index.md" and #matching_wikis >= 2 then
		-- If we are in an index file of a nested wiki, the root is the parent.
		wiki_index_dir = matching_wikis[2].resolved
	else
		-- Otherwise, the most specific path is the root.
		wiki_index_dir = matching_wikis[1].resolved
	end

	if wiki_index_dir then
		-- Set buffer-local variables and create keymaps.
		vim.b[0].wiki_root = wiki_index_dir
		config.path = matching_wikis[1].resolved
		wiki._create_buffer_keymaps(0)
		-- Trigger progress calculation when entering a wiki file.
		todo.update_progress()
	end
end

---
-- Processes the user's configuration to create a flat list of all wiki root paths.
-- @return {table} A list of processed wiki path objects.
--
local function process_wiki_paths()
	local manual_wiki_dirs = {}
	if config.path and config.path ~= "" then
		table.insert(manual_wiki_dirs, config.path)
	end
	if config.wiki_dirs then
		for _, wiki_dir in ipairs(config.wiki_dirs) do
			table.insert(manual_wiki_dirs, wiki_dir.path)
		end
	end

	local all_roots_set = {}
	for _, path in ipairs(manual_wiki_dirs) do
		local resolved_path = vim.fn.fnamemodify(path, ":p")
		all_roots_set[resolved_path] = true

		-- Find all directories with an `index.md` inside the resolved path.
		local nested_roots = utils.find_nested_roots(resolved_path, "index.md")
		for _, nested_root in ipairs(nested_roots) do
			all_roots_set[nested_root] = true
		end
	end

	-- Convert the set of paths to a list of objects for easier processing.
	local processed_wiki_paths = {}
	for path, _ in pairs(all_roots_set) do
		table.insert(processed_wiki_paths, {
			resolved = path,
			normalized = utils.normalize_path_for_comparison(path),
		})
	end
	return processed_wiki_paths
end

---
-- Initializes the neowiki plugin with user-provided options.
-- This function merges user options with defaults, processes wiki paths,
-- and sets up autocommands.
-- @param opts (table|nil): User configuration options to override defaults.
--
M.setup = function(opts)
	utils.setup(opts, config)
	config.processed_wiki_paths = process_wiki_paths()

	-- Autocommand to set up keymaps when entering a markdown file.
	local neowiki_augroup = vim.api.nvim_create_augroup("neowiki", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = neowiki_augroup,
		pattern = "*.md",
		callback = setup_keymaps_for_wiki_file,
		desc = "Set neowiki keymaps for markdown files in wiki directories.",
	})

	-- Add an autocommand to update progress display on text changes.
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = neowiki_augroup,
		pattern = "*.md",
		callback = function()
			-- Debounce the function to prevent it from running on every keystroke.
			vim.defer_fn(function()
				if vim.b.wiki_root and vim.api.nvim_buf_is_valid(0) then
					todo.update_progress()
				end
			end, 200) -- 200ms delay
		end,
		desc = "Update neowiki todo progress on text change.",
	})
end

return M
