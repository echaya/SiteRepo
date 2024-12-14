# 🍿 statuscolumn

<!-- docgen -->

## 📦 Setup

```lua
-- lazy.nvim
{
  "folke/snacks.nvim",
  opts = {
    statuscolumn = {
      -- your statuscolumn configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}
```

## ⚙️ Config

```lua
---@class snacks.statuscolumn.Config
---@field enabled? boolean
{
  left = { "mark", "sign" }, -- priority of signs on the left (high to low)
  right = { "fold", "git" }, -- priority of signs on the right (high to low)
  folds = {
    open = false, -- show open fold icons
    git_hl = false, -- use Git Signs hl for fold icons
  },
  git = {
    -- patterns to match Git signs
    patterns = { "GitSign", "MiniDiffSign" },
  },
  refresh = 50, -- refresh at most every 50ms
}
```

## 📦 Module

### `Snacks.statuscolumn()`

```lua
---@type fun(): string
Snacks.statuscolumn()
```

### `Snacks.statuscolumn.get()`

```lua
Snacks.statuscolumn.get()
```
