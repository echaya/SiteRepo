local config = require("kiwi.config")
local utils = require("kiwi.utils")
local todo = require("kiwi.todo")
local wiki = require("kiwi.wiki")

local M = {}
M.VERSION = "0.4.0"
M.todo = todo
M.open_wiki_index = wiki.open_wiki_index
M.create_or_open_wiki_file = wiki.create_or_open_wiki_file
M.open_link = wiki.open_link
M.jump_to_index = wiki.jump_to_index

-- Checks if the current buffer is a markdown file within a configured wiki
-- directory and, if so, applies the buffer-local keymaps.
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

	table.sort(matching_wikis, function(a, b)
		return #a.normalized > #b.normalized
	end)

	local wiki_index_dir = nil
	if current_filename == "index.md" and #matching_wikis >= 2 then
		wiki_index_dir = matching_wikis[2].resolved
	else
		wiki_index_dir = matching_wikis[1].resolved
	end

	if wiki_index_dir then
		vim.b[0].wiki_root = wiki_index_dir
		config.path = matching_wikis[1].resolved
		wiki._create_buffer_keymaps(0)
	end
end

local process_wiki_paths = function()
	local manual_folders = {}
	if config.path and config.path ~= "" then
		table.insert(manual_folders, config.path)
	end
	if config.folders then
		for _, folder in ipairs(config.folders) do
			table.insert(manual_folders, folder.path)
		end
	end

	local all_roots_set = {}
	for _, path in ipairs(manual_folders) do
		local resolved_path = vim.fn.fnamemodify(path, ":p")
		all_roots_set[resolved_path] = true

		local nested_roots = utils.find_nested_roots(resolved_path, "index.md")
		for _, nested_root in ipairs(nested_roots) do
			all_roots_set[nested_root] = true
		end
	end

	local processed_wiki_paths = {}
	for path, _ in pairs(all_roots_set) do
		table.insert(processed_wiki_paths, {
			resolved = path,
			normalized = utils.normalize_path_for_comparison(path),
		})
	end
	return processed_wiki_paths
end

M.setup = function(opts)
	utils.setup(opts, config)
	config.processed_wiki_paths = process_wiki_paths()

	local kiwi_augroup = vim.api.nvim_create_augroup("Kiwi", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = kiwi_augroup,
		pattern = "*.md",
		callback = setup_keymaps_for_wiki_file,
		desc = "Set Kiwi keymaps for markdown files in wiki directories.",
	})
end

return M
