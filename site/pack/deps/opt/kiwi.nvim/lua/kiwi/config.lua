local config = {
	wiki_dirs = nil,
	keymaps = {
		visual = {
			create_link = "<CR>",
			create_link_vsplit = "<S-CR>",
			create_link_split = "<C-CR>",
		},
		normal = {
			follow_link = "<CR>",
			follow_link_vsplit = "<S-CR>",
			follow_link_split = "<C-CR>",
			next_link = "<Tab>",
			prev_link = "<S-Tab>",
			jump_to_index = "<Backspace>",
			delete_page = "<leader>wd",
			cleanup_links = "<leader>wc",
			toggle_task = "<leader>wt",
		},
	},
}

return config

