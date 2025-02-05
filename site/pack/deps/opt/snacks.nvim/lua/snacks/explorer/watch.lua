local M = {}

local Git = require("snacks.explorer.git")
local Tree = require("snacks.explorer.tree")

local uv = vim.uv or vim.loop

---@alias snacks.explorer.Watcher fun(path:string, opts:vim._watch.watch.Opts?, callback:vim._watch.Callback):fun()

---@return snacks.explorer.Watcher?
function M.watcher()
  if not vim._watch then
    return
  end
  if vim.fn.has("win32") == 1 or vim.fn.has("mac") == 1 then
    return vim._watch.watch
  elseif vim.fn.executable("inotifywait") == 1 then
    return vim._watch.inotify
  end
  -- This is horrible for performance. Don't use it!
  -- return vim._watch.watchdirs
end

local running = {} ---@type table<string, fun()>

function M.abort()
  for _, abort in pairs(running) do
    pcall(abort)
  end
  running = {}
end

local timer = assert(uv.new_timer())

function M.refresh()
  -- batch updates and give explorer the time to update before the watcher
  timer:start(500, 0, function()
    local picker = Snacks.picker.get({ source = "explorer" })[1]
    if picker and not picker.closed and Tree:is_dirty(picker:cwd(), picker.opts) then
      if not picker.list.target then
        picker.list:set_target()
      end
      picker:find()
    end
  end)
end

---@param cwd string
function M.watch_git(cwd)
  local root = Snacks.git.get_root(cwd)
  if not root then
    return
  end
  local handle = assert(vim.uv.new_fs_event())
  handle:start(root .. "/.git", {}, function(_, file)
    if file == "index" then
      Git.refresh(root)
      M.refresh()
    end
  end)
  return function()
    if handle and not handle:is_closing() then
      handle:close()
    end
  end
end

---@param cwd string
function M.watch_files(cwd)
  local watch = M.watcher()
  if not watch then
    return
  end

  return watch(cwd, {
    uvflags = { recursive = true },
  }, function(path, changes)
    -- handle deletes
    while not uv.fs_stat(path) do
      local p = vim.fs.dirname(path)
      if p == path then
        return
      end
      path = p
    end
    Tree:refresh(path)
    M.refresh()
  end)
end

---@param cwd string
function M.watch(cwd)
  if running[cwd] then
    return
  end

  local watchers = { M.watch_git, M.watch_files }
  local cancel = {} ---@type (fun())[]

  for _, watch in ipairs(watchers) do
    local ok, c = pcall(watch, cwd)
    if ok and c then
      cancel[#cancel + 1] = c
    end
  end

  running[cwd] = function()
    vim.tbl_map(pcall, cancel)
    running[cwd] = nil
  end
end

return M
