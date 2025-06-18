local config = require("neowiki.config")
local todo = require("neowiki.todo")
local utils = require("neowiki.utils")

local M = {}

---
-- Opens a file at a given path. If the file is already open in a window,
-- it jumps to that window. Otherwise, it opens the file in the current window
-- or via a specified command (e.g., 'vsplit').
-- @param full_path (string): The absolute path to the file.
-- @param open_cmd (string|nil): Optional vim command to open the file (e.g., "vsplit", "tabnew").
--
M._open_file = function(full_path, open_cmd)
	local abs_path = vim.fn.fnamemodify(full_path, ":p")
	local buffer_number = vim.fn.bufnr(abs_path)

	-- If buffer is already open and visible, jump to its window.
	if buffer_number ~= -1 then
		local win_nr = vim.fn.bufwinnr(buffer_number)
		if win_nr ~= -1 then
			local win_id = vim.fn.win_getid(win_nr)
			vim.api.nvim_set_current_win(win_id)
			return
		end
	end

	-- Open the file using the specified command or in the current window.
	if open_cmd and type(open_cmd) == "string" and #open_cmd > 0 then
		vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(full_path))
	else
		local bn_to_open = vim.fn.bufnr(full_path, true)
		vim.api.nvim_win_set_buf(0, bn_to_open)
	end
end

---
-- Creates buffer-local keymaps for the current wiki file.
-- These keymaps are defined in the user's configuration.
-- @param buffer_number (number): The buffer number to attach the keymaps to.
--
M._create_buffer_keymaps = function(buffer_number)
	-- Make the todo toggle function repeatable for normal mode.
	utils.make_repeatable("n", "<Plug>(neowikiToggleTask)", function()
		require("neowiki.todo").toggle_task()
	end)

	local link_pattern = [[\(\[.\{-}\](.\{-})\)\|\(\[\[.\{-}\]\]\)]]

	-- Defines the behavior of logical actions across different modes.
	local logical_actions = {
		action_link = {
			n = { rhs = require("neowiki.wiki").open_link, desc = "Open Link" },
			v = {
				rhs = ":'<,'>lua require('neowiki.wiki').create_or_open_wiki_file()<CR>",
				desc = "Create Link from Selection",
			},
		},
		action_link_vsplit = {
			n = {
				rhs = function()
					require("neowiki.wiki").open_link("vsplit")
				end,
				desc = "Open Link (VSplit)",
			},
			v = {
				rhs = ":'<,'>lua require('neowiki.wiki').create_or_open_wiki_file('vsplit')<CR>",
				desc = "Create Link from Selection (VSplit)",
			},
		},
		action_link_split = {
			n = {
				rhs = function()
					require("neowiki.wiki").open_link("split")
				end,
				desc = "Open Link (Split)",
			},
			v = {
				rhs = ":'<,'>lua require('neowiki.wiki').create_or_open_wiki_file('split')<CR>",
				desc = "Create Link from Selection (Split)",
			},
		},
		toggle_task = {
			n = { rhs = "<Plug>(neowikiToggleTask)", desc = "Toggle Task Status", remap = true },
			v = {
				rhs = ":'<,'>lua require('neowiki.todo').toggle_task({ visual = true })<CR>",
				desc = "Toggle Tasks in Selection",
			},
		},
		next_link = {
			n = {
				rhs = (function()
					return string.format(":let @/=%s<CR>nl:noh<CR>", vim.fn.string(link_pattern))
				end)(),
				desc = "Jump to Next Link",
			},
		},
		prev_link = {
			n = {
				rhs = (function()
					return string.format(":let @/=%s<CR>NNl:noh<CR>", vim.fn.string(link_pattern))
				end)(),
				desc = "Jump to Prev Link",
			},
		},
		jump_to_index = {
			n = { rhs = require("neowiki.wiki").jump_to_index, desc = "Jump to Index" },
		},
		delete_page = {
			n = { rhs = require("neowiki.wiki").delete_wiki, desc = "Delete Wiki Page" },
		},
		cleanup_links = {
			n = { rhs = utils.cleanup_broken_links, desc = "Clean Broken Links" },
		},
	}

	-- Iterate through the user's flattened keymap config and apply the mappings.
	for action_name, lhs in pairs(config.keymaps) do
		if lhs and lhs ~= "" and logical_actions[action_name] then
			local modes = logical_actions[action_name]
			-- For each logical action, create a keymap for every mode defined (n, v, etc.).
			for mode, action_details in pairs(modes) do
				vim.keymap.set(mode, lhs, action_details.rhs, {
					buffer = buffer_number,
					desc = "neowiki: " .. action_details.desc,
					remap = action_details.remap,
					silent = true,
				})
			end
		end
	end
end

---
-- Finds a markdown link under the cursor and opens the target file.
-- @param open_cmd (string|nil): Optional command for opening the file (e.g., 'vsplit').
--
M._open_link_handler = function(open_cmd)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.fn.getline(cursor[1])
	local filename = utils.is_link(cursor, line)

	if filename and filename:len() > 1 then
		if filename:sub(1, 2) == "./" then
			filename = filename:sub(2, -1)
		end
		local full_path = vim.fs.joinpath(config.path, filename)
		M._open_file(full_path, open_cmd)
	else
		vim.notify("neowiki: No link under cursor.", vim.log.levels.WARN)
	end
end

---
-- Opens the index.md file of a selected or specified wiki.
-- @param name (string|nil): The name of the wiki to open. If nil, prompts the user.
-- @param open_cmd (string|nil): Optional command for opening the file.
--
local open_wiki_index = function(name, open_cmd)
	local function open_index_from_path(wiki_path)
		if not wiki_path then
			return
		end
		config.path = wiki_path
		local wiki_index_path = vim.fs.joinpath(config.path, "index.md")
		M._open_file(wiki_index_path, open_cmd)
	end

	if config.wiki_dirs then
		if name then
			-- Find the wiki path by its name.
			local found_path = nil
			for _, wiki_dir in ipairs(config.wiki_dirs) do
				if wiki_dir.name == name then
					found_path = wiki_dir.path
					break
				end
			end
			open_index_from_path(found_path)
		else
			-- If no name is given, prompt user to choose from available wikis.
			utils.prompt_wiki_dir(config, open_index_from_path)
		end
	else
		-- If no multi-wiki setup, open the default index.
		open_index_from_path(config.path)
	end
end

---
-- Public function to open a wiki's index page in the current window.
-- @param name (string|nil): The name of the wiki to open. Prompts if nil and multiple wikis exist.
--
M.open_wiki = function(name)
	open_wiki_index(name)
end

---
-- Public function to open a wiki's index page in a new tab.
-- @param name (string|nil): The name of the wiki to open. Prompts if nil and multiple wikis exist.
--
M.open_wiki_in_new_tab = function(name)
	open_wiki_index(name, "tabnew")
end

---
-- Creates a new wiki page from the visual selection, replacing the selection with a link.
-- Then opens the new page.
-- @param open_cmd (string|nil): Optional command for opening the new file.
--
M.create_or_open_wiki_file = function(open_cmd)
	local selection_start = vim.fn.getpos("'<")
	local selection_end = vim.fn.getpos("'>")
	local line = vim.fn.getline(selection_start[2], selection_end[2])
	local name = line[1]:sub(selection_start[3], selection_end[3])

	-- Create a filename and markdown link from the selected text.
	local filename = name:gsub(" ", "_"):gsub("\\", "") .. ".md"
	local new_mkdn = "[" .. name .. "](" .. "./" .. filename .. ")"
	local newline = line[1]:sub(0, selection_start[3] - 1)
		.. new_mkdn
		.. line[1]:sub(selection_end[3] + 1, string.len(line[1]))
	vim.api.nvim_set_current_line(newline)

	local full_path = vim.fs.joinpath(config.path, filename)
	local dir_path = vim.fn.fnamemodify(full_path, ":h")
	utils.resolve_path(dir_path)
	M._open_file(full_path, open_cmd)
end

---
-- Public function to follow a link under the cursor.
-- @param open_cmd (string|nil): Optional command to open the link with.
--
M.open_link = function(open_cmd)
	M._open_link_handler(open_cmd)
end

---
-- Jumps to the index.md file of the wiki that the current buffer belongs to.
--
M.jump_to_index = function()
	local root = vim.b[0].wiki_root
	if root and root ~= "" then
		local index_path = vim.fs.joinpath(root, "index.md")
		M._open_file(index_path)
	else
		vim.notify("neowiki: Not inside a neowiki wiki. Cannot jump to index.", vim.log.levels.WARN)
	end
end

---
-- Deletes the current wiki page after confirmation. It prevents deletion of the
-- root 'index.md' file and can optionally clean up broken links pointing to the deleted page.
--
M.delete_wiki = function()
	local root = vim.b[0].wiki_root
	if not root or root == "" then
		vim.notify("neowiki: Not a wiki file.", vim.log.levels.WARN)
		return
	end

	local file_path = vim.api.nvim_buf_get_name(0)
	local file_name = vim.fn.fnamemodify(file_path, ":t")

	-- Prevent deletion of the main index.md file.
	local normalized_root_index_path = utils.normalize_path_for_comparison(vim.fs.joinpath(root, "index.md"))
	local normalized_file_path = utils.normalize_path_for_comparison(vim.fn.fnamemodify(file_path, ":p"))
	if normalized_root_index_path == normalized_file_path then
		vim.notify("neowiki: Cannot delete the root index.md file.", vim.log.levels.ERROR)
		return
	end

	local choice = vim.fn.confirm('Permanently delete "' .. file_name .. '"?', "&Yes\n&No")
	if choice == 1 then
		local ok, err = pcall(os.remove, file_path)

		if ok then
			vim.notify('neowiki: Deleted "' .. file_name .. '"', vim.log.levels.INFO)
			vim.cmd("bdelete! " .. vim.fn.bufnr("%"))
			M.jump_to_index()

			-- Schedule broken link cleanup to run after jumping to the index.
			vim.schedule(function()
				utils.cleanup_broken_links()
			end)
		else
			vim.notify("neowiki: Error deleting file: " .. err, vim.log.levels.ERROR)
		end
	else
		vim.notify("neowiki: Delete operation canceled.", vim.log.levels.INFO)
	end
end

return M
