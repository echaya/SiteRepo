# 🍿 git

<!-- docgen -->

## 🎨 Styles

### `blame_line`

```lua
{
  width = 0.6,
  height = 0.6,
  border = "rounded",
  title = " Git Blame ",
  title_pos = "center",
  ft = "git",
}
```

## 📦 Module

### `Snacks.git.blame_line()`

Show git log for the current line.

```lua
---@param opts? snacks.terminal.Opts | {count?: number}
Snacks.git.blame_line(opts)
```

### `Snacks.git.get_root()`

Gets the git root for a buffer or path.
Defaults to the current buffer.

```lua
---@param path? number|string buffer or path
Snacks.git.get_root(path)
```
