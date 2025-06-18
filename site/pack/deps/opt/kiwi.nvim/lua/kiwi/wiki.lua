local config = require("kiwi.config")
local todo = require("kiwi.todo")
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
	utils.make_repeatable("n", "<Plug>(KiwiToggleTask)", todo.toggle_task)
	local link_pattern = [[\(\[.\{-}\](.\{-})\)\|\(\[\[.\{-}\]\]\)]]

	local actions = {
		follow_link = { mode = "n", rhs = require("kiwi.wiki").open_link, desc = "Open Link" },
		follow_link_vsplit = {
			mode = "n",
			rhs = function()
				require("kiwi.wiki").open_link("vsplit")
			end,
			desc = "Open Link (VSplit)",
		},
		follow_link_split = {
			mode = "n",
			rhs = function()
				require("kiwi.wiki").open_link("split")
			end,
			desc = "Open Link (Split)",
		},
		next_link = {
			mode = "n",
			rhs = (function()
				local p = link_pattern
				return string.format(":let @/=%s<CR>nl:noh<CR>", vim.fn.string(p))
			end)(),
			desc = "Jump to Next Link",
		},
		prev_link = {
			mode = "n",
			rhs = (function()
				local p = link_pattern
				return string.format(":let @/=%s<CR>NNl:noh<CR>", vim.fn.string(p))
			end)(),
			desc = "Jump to Prev Link",
		},
		jump_to_index = { mode = "n", rhs = require("kiwi.wiki").jump_to_index, desc = "Jump to Index" },
		delete_page = { mode = "n", rhs = require("kiwi.wiki").delete_wiki, desc = "Delete Wiki Page" },
		cleanup_links = { mode = "n", rhs = utils.cleanup_broken_links, desc = "Clean Broken Links" },
		toggle_task = { mode = "n", rhs = "<Plug>(KiwiToggleTask)", desc = "Toggle Task Status", remap = true },

		create_link = {
			mode = "v",
			rhs = ":'<,'>lua require('kiwi').create_or_open_wiki_file()<CR>",
			desc = "Create Link from Selection",
		},
		create_link_vsplit = {
			mode = "v",
			rhs = ":'<,'>lua require('kiwi').create_or_open_wiki_file('vsplit')<CR>",
			desc = "Create Link from Selection (VSplit)",
		},
		create_link_split = {
			mode = "v",
			rhs = ":'<,'>lua require('kiwi').create_or_open_wiki_file('split')<CR>",
			desc = "Create Link from Selection (Split)",
		},
	}

	for _, maps in pairs(config.keymaps) do -- e.g., group = "normal"
		for name, lhs in pairs(maps) do -- e.g., name = "toggle_task", lhs = "<leader>wt"
			if lhs and lhs ~= "" and actions[name] then
				local action = actions[name]
				-- This is now a direct, clean call to the modern API.
				vim.keymap.set(action.mode, lhs, action.rhs, {
					buffer = buffer_number,
					desc = "Kiwi: " .. action.desc,
					remap = action.remap, -- Correctly handles remap = true for our <Plug> map
					silent = true,
				})
			end
		end
	end
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
			-- User specified a wiki name directly, find it and proceed.
			local found_path = nil
			for _, wiki_dir in ipairs(config.wiki_dirs) do
				if wiki_dir.name == name then
					found_path = wiki_dir.path
					break
				end
			end
			open_index_from_path(found_path) -- Open it (or do nothing if not found).
		else
			utils.prompt_wiki_dir(config, open_index_from_path)
		end
	else
		open_index_from_path(config.path)
	end
end

M.open_wiki = function(name)
	open_wiki_index(name)
end

M.open_wiki_in_new_tab = function(name)
	open_wiki_index(name, "tabnew")
end

-- Create a new Wiki entry in Journal wiki_dir on highlighting word and pressing <CR>
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
	local normalized_root_index_path = utils.normalize_path_for_comparison(vim.fs.joinpath(root, "index.md"))
	local normalized_file_path = utils.normalize_path_for_comparison(vim.fn.fnamemodify(file_path, ":p"))
	if normalized_root_index_path == normalized_file_path then
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

