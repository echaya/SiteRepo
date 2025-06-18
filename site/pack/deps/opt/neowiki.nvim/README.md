# neowiki.nvim
Modern vimwiki for Instant Notes & GTD 🚀📝

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](./LICENSE)
[![Lua](https://img.shields.io/badge/Made_with-Lua-blueviolet.svg?style=for-the-badge)](https://www.lua.org)
[![Neovim](https://img.shields.io/badge/Built_for-Neovim-57A143?style=for-the-badge&logo=neovim)](https://neovim.io/)

---

## 🌟 Introduction

**neowiki.nvim** is a lightweight, Lua-based Neovim plugin for fast note-taking and Getting Things Done (GTD). Built for Neovim’s ecosystem, it works the best with Treesitter and other your favorite markdown plugins for a minimal, intuitive workflow. Perfect for notes, tasks, and projects, it supports multiple and nested wikis.

---

## 🔍 Features

- 🔗 **Instant Linking**: Create/follow markdown links with `<CR>`; use `<S-CR>` or `<C-CR>` for splits.
- ✅ **Smart GTD**: Toggle tasks (`<leader>wt`) with `[ ]`/`[x]`; smart nested tasks with progress tracking
- 📂 **Multi-Wiki & Nested**: Manage multiple wikis (e.g., work, personal) and nested structures via `index.md`.
- 🧹 **Easy Maintenance**: Delete pages (`<leader>wd`) and clean broken links (`<leader>wc`).
- ⚙️ **Extensible**: First-class citizen compatible with your favorite markdown plugins and Nvim ecosystem.

---

## 📷 Screenshots

*Coming soon! Share your setups in [GitHub Discussions](https://github.com/echaya/neowiki.nvim/discussions) to be featured!*

---

## 🛠️ Installation

Requires **Neovim >= 0.10**. Treesitter’s `markdown` and `markdown_inline` are recommended.

```lua
-- Lazy.nvim
{
    "echaya/neowiki.nvim",
    opts = {
      wiki_dirs = {
        -- absolute and relative paths are both supported
        { name = "cooking", path = "cooking/receipes" },
        { name = "hobby", path = "hobby" },
        { name = "mywiki", path = "C:/mywiki/" },
      },
    },
    keys = {
      { "<leader>ww", "<cmd>lua require('neowiki').open_wiki()<cr>", desc = "Open Wiki Index" },
      {
        "<leader>wh",
        "<cmd>lua require('neowiki').open_wiki('hobby')<cr>",
        desc = "Open Personal Wiki",
      },
      {
        "<leader>wT",
        "<cmd>lua require('neowiki').open_wiki_in_new_tab()<cr>",
        desc = "Open Wiki in Tab",
      },
    },
}

-- mini.deps
add('echaya/neowiki.nvim')

-- Vim-Plug
Plug 'echaya/neowiki.nvim'
```


---

## 📝 Usage


### Quick Start
1. Open wiki: `<leader>ww` or `<leader>wT`.
2. Create note: Select “My Project”, press `<CR>` to make `[My Project](./My_Project.md)`.
3. Toggle tasks: Write `[ ] Task`, use `<leader>wt` for `[x] Task`.
4. Navigate: `<Tab>`/`<S-Tab>` for links, `<Backspace>` for index, `<leader>wc` to clean links.
5. Save: `:w`.

**Wiki Index Example**:
```markdown
# My Knowledge Base
- [Tasks](./Tasks.md)
- [Project Ideas](./Project_Ideas.md)
- [ ] GTD: neowiki setup
```

**Nested Wiki Example**:
```markdown
# Work Wiki
- [Team Notes](./team/index.md)
```

---

## ⌨️ Key Bindings

| Mode   | Key           | Action                          | Description                              |
|--------|---------------|---------------------------------|------------------------------------------|
| Normal | `<CR>`        | Follow link                     | Open link under cursor                   |
| Visual | `<CR>`        | Create link                     | Link selected text                       |
| Normal | `<S-CR>`      | Follow link (vsplit)            | Open link in vertical split              |
| Visual | `<S-CR>`      | Create link (vsplit)            | Create link and open in vertical split   |
| Normal | `<C-CR>`      | Follow link (split)             | Open link in horizontal split            |
| Visual | `<C-CR>`      | Create link (split)             | Create link and open in horizontal split |
| Normal | `<Tab>`       | Next link                       | Jump to next wiki link                   |
| Normal | `<S-Tab>`     | Previous link                   | Jump to previous wiki link               |
| Normal | `<Backspace>` | Jump to index                   | Open wiki’s `index.md`                   |
| Normal | `<leader>wd`  | Delete page                     | Delete current wiki page                 |
| Normal | `<leader>wc`  | Clean broken links              | Remove broken links from page            |
| Normal | `<leader>wt`  | Toggle task                     | Toggle task status (`[ ]` ↔ `[x]`)       |
| Normal | `<leader>wT`  | Open wiki in new tab            | Open wiki index in a new tab             |

Customize:
```lua
require('neowiki').setup({
  keymaps = {
    normal = { follow_link = "<Enter>", toggle_task = "<leader>t" },
    visual = { create_link = "<Enter>" },
  },
})
```

---

## 🤝 Contributing

**neowiki.nvim** is a WIP, and we need you to make it epic! Contribute by:
- 🐛 **Issues**: Report bugs at [GitHub Issues](https://github.com/echaya/neowiki.nvim/issues).
- 💡 **PRs**: Submit features or fixes; see [Contributing Guide](CONTRIBUTING.md) (TBD).
- 📣 **Feedback**: Share ideas in [GitHub Discussions](https://github.com/echaya/neowiki.nvim/discussions).
- ⭐ **Stars**: Help us hit 200 stars to unlock future goodies!

Join the Neovim community! 🚀

---

## 🙏 Thanks

Big thanks to **kiwi.nvim** by [serenevoid](https://github.com/serenevoid/kiwi.nvim) for inspiring **neowiki.nvim**’s lean approach. Shoutout to the Neovim community for fueling this project! 📝

---

## 📜 License

[MIT License](./LICENSE)

[![Hits](https://hits.sh/github.com/echaya/neowiki.nvim.svg)](https://hits.sh/github.com/echaya/neowiki.nvim/)
[![Stargazers](https://starchart.cc/echaya/neowiki.nvim.svg)](https://starchart.cc/echaya/neowiki.nvim)

