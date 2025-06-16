local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

-- The single, generic utility to open any file path with an optional command.
-- @param full_path (string): The absolute path to the file to open.
-- @param open_cmd (string|nil): The vim command to use ('vsplit', 'tabnew', etc.).
M._open_file = function(full_path, open_cmd)
	-- Check if the buffer is already loaded and visible in a window.
	local abs_path = vim.fn.fnamemodify(full_path, ":p")
	local buffer_number = vim.fn.bufnr(abs_path)

	if buffer_number ~= -1 then
		local win_nr = vim.fn.bufwinnr(buffer_number)
		if win_nr ~= -1 then
			local win_id = vim.fn.win_getid(win_nr)
			vim.api.nvim_set_current_win(win_id)
			return
		end
	end

	if open_cmd and type(open_cmd) == "string" and #open_cmd > 0 then
		vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(full_path))
	else
		local bn_to_open = vim.fn.bufnr(full_path, true)
		vim.api.nvim_win_set_buf(0, bn_to_open)
	end
end

M._create_buffer_keymaps = function(buffer_number)
	-- TODO to expose the keymap for override
	-- Helper function to set keymaps with descriptions cleanly.
	local function set_keymap(mode, key, command, description)
		vim.api.nvim_buf_set_keymap(buffer_number, mode, key, command, {
			noremap = true,
			silent = true,
			nowait = true,
			desc = "Kiwi: " .. description,
		})
	end

	-- Visual mode keymaps for creating links from a selection
	set_keymap("v", "<CR>", ":'<,'>lua require('kiwi').create_or_open_wiki_file()<CR>", "Create Link from Selection")
	set_keymap(
		"v",
		"<S-CR>",
		":'<,'>lua require('kiwi').create_or_open_wiki_file('vsplit')<CR>",
		"Create Link from Selection (VSplit)"
	)
	set_keymap(
		"v",
		"<C-CR>",
		":'<,'>lua require('kiwi').create_or_open_wiki_file('split')<CR>",
		"Create Link from Selection (Split)"
	)

	-- Normal mode keymaps for following links
	set_keymap("n", "<CR>", ':lua require("kiwi").open_link()<CR>', "Open Link Under Cursor")
	set_keymap("n", "<S-CR>", ':lua require("kiwi").open_link("vsplit")<CR>', "Open Link Under Cursor (VSplit)")
	set_keymap("n", "<C-CR>", ':lua require("kiwi").open_link("split")<CR>', "Open Link Under Cursor (Split)")
	-- TODO to set the search using vim.fn.search
	set_keymap("n", "<Tab>", ':let @/="\\\\[.\\\\{-}\\\\]\\("<CR>nl:noh<cr>', "Jump to Next Link")
	set_keymap("n", "<S-Tab>", ':let @/="\\\\[.\\\\{-}\\\\]\\("<CR>NNl:noh<cr>', "Jump to Prev Link")
	set_keymap("n", "<Backspace>", ':lua require("kiwi").jump_to_index()<CR>', "Jump to Index")
	set_keymap("n", "<leader>wd", ':lua require("kiwi.wiki").delete_wiki()<CR>', "Delete Wiki Page")
end

-- Private handler that finds a link under the cursor and delegates opening to _open_file.
M._open_link_handler = function(open_cmd)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.fn.getline(cursor[1])
	local filename = utils.is_link(cursor, line)

	if filename and filename:len() > 1 then
		if filename:sub(1, 2) == "./" then
			filename = filename:sub(2, -1)
		end
		local full_path = vim.fs.joinpath(config.path, filename)

		-- Delegate to the new utility function
		M._open_file(full_path, open_cmd)
	else
		vim.notify("Kiwi: No link under cursor.", vim.log.levels.WARN)
	end
end

M.open_wiki_index = function(name)
	local function open_index_from_path(wiki_path)
		if not wiki_path then
			return
		end
		config.path = wiki_path
		local wiki_index_path = vim.fs.joinpath(config.path, "index.md")
		M._open_file(wiki_index_path)
	end

	if config.folders then
		if name then
			-- User specified a wiki name directly, find it and proceed.
			local found_path = nil
			for _, props in ipairs(config.folders) do
				if props.name == name then
					found_path = props.path
					break
				end
			end
			open_index_from_path(found_path) -- Open it (or do nothing if not found).
		else
			utils.prompt_folder(config, open_index_from_path)
		end
	else
		open_index_from_path(config.path)
	end
end

-- Create a new Wiki entry in Journal folder on highlighting word and pressing <CR>
M.create_or_open_wiki_file = function(open_cmd)
	local selection_start = vim.fn.getpos("'<")
	local selection_end = vim.fn.getpos("'>")
	local line = vim.fn.getline(selection_start[2], selection_end[2])
	local name = line[1]:sub(selection_start[3], selection_end[3])
	local filename = name:gsub(" ", "_"):gsub("\\", "") .. ".md"
	local new_mkdn = "[" .. name .. "](" .. "./" .. filename .. ")"
	local newline = line[1]:sub(0, selection_start[3] - 1)
		.. new_mkdn
		.. line[1]:sub(selection_end[3] + 1, string.len(line[1]))
	vim.api.nvim_set_current_line(newline)

	local full_path = vim.fs.joinpath(config.path, filename)

	M._open_file(full_path, open_cmd)
end

M.open_link = function(open_cmd)
	M._open_link_handler(open_cmd)
end

-- Jumps to the index.md file of the current wiki.
M.jump_to_index = function()
	local root = vim.b[0].wiki_root
	if root and root ~= "" then
		local index_path = vim.fs.joinpath(root, "index.md")
		M._open_file(index_path) -- Open in the current window
	else
		vim.notify("Kiwi: Not inside a kiwi wiki. Cannot jump to index.", vim.log.levels.WARN)
	end
end

-- Deletes the current wiki page and optionally cleans up links pointing to it.
M.delete_wiki = function()
	local root = vim.b[0].wiki_root
	if not root or root == "" then
		vim.notify("Kiwi: Not a wiki file.", vim.log.levels.WARN)
		return
	end

	local file_path = vim.api.nvim_buf_get_name(0)
	local file_name = vim.fn.fnamemodify(file_path, ":t")
	local root_index_path = vim.fs.joinpath(root, "index.md")

	if vim.fn.fnamemodify(file_path, ":p") == root_index_path then
		vim.notify("Kiwi: Cannot delete the root index.md file.", vim.log.levels.ERROR)
		return
	end

	local choice = vim.fn.confirm('Permanently delete "' .. file_name .. '"?', "&Yes\n&No")

	if choice == 1 then -- User selected 'Yes'
		local ok, err = pcall(os.remove, file_path)

		if ok then
			vim.notify('Kiwi: Deleted "' .. file_name .. '"', vim.log.levels.INFO)
			vim.cmd("bdelete! " .. vim.fn.bufnr("%"))
			M.jump_to_index()

			-- Defer the cleanup function to run after the index has been opened.
			vim.schedule(function()
				utils.cleanup_broken_links()
			end)
		else
			vim.notify("Kiwi: Error deleting file: " .. err, vim.log.levels.ERROR)
		end
	else
		vim.notify("Kiwi: Delete operation canceled.", vim.log.levels.INFO)
	end
end

return M
