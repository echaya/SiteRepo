local M = {}

---@class snacks.picker
---@field explorer fun(opts?: snacks.picker.explorer.Config): snacks.Picker

---@type table<snacks.Picker, snacks.picker.explorer.State>
M._state = setmetatable({}, { __mode = "k" })
local uv = vim.uv or vim.loop

---@class snacks.picker.explorer.Item: snacks.picker.finder.Item
---@field file string
---@field dir? boolean
---@field parent? snacks.picker.explorer.Item
---@field open? boolean
---@field last? boolean
---@field sort? string
---@field internal? boolean internal parent directories not part of fd output
---@field status? string

---@class snacks.picker.explorer.Node
---@field name string
---@field open boolean
---@field parent? snacks.picker.explorer.Node
---@field children table<string, snacks.picker.explorer.Node>

local function norm(path)
  return vim.fs.normalize(path)
end

---@class snacks.picker.explorer.Tree
---@field root snacks.picker.explorer.Node
local Tree = {}
Tree.__index = Tree

function Tree.new()
  local self = setmetatable({}, Tree)
  self.root = { name = "", open = true, children = {} }
  return self
end

---@param path string
function Tree:add(path)
  return self:find(path, { add = true }) ---@type snacks.picker.explorer.Node
end

---@param path string
---@param opts? {add?: boolean}
function Tree:find(path, opts)
  opts = opts or {}
  path = norm(path)
  local node = self.root
  for part in path:gmatch("[^/]+") do
    if not node.children[part] then
      if not opts.add then
        return
      end
      node.children[part] = { name = part, open = true, parent = node, children = {} }
    end
    node = node.children[part] ---@type snacks.picker.explorer.Node
  end
  return node
end

---@param path string
function Tree:open(path)
  path = norm(path)
  local node = self:add(path)
  while node do
    node.open = true
    node = node.parent
  end
end

---@param cwd string
---@param path string
function Tree:in_cwd(cwd, path)
  path = norm(path)
  cwd = norm(cwd)
  return cwd == "/" or path == cwd or path:find(cwd .. "/", 1, true) == 1
end

---@param cwd string
---@param path string
function Tree:visible(cwd, path)
  path = norm(path)
  cwd = norm(cwd)
  if not self:in_cwd(cwd, path) then
    return false
  end
  local cwd_node = self:add(cwd)
  local node = self:find(path)
  if not node then
    return false
  end
  while node and node ~= cwd_node do
    if not node.open then
      return false
    end
    node = node.parent
  end
  return true
end

---@param path string
function Tree:close(path)
  path = norm(path)
  local node = self:add(path)
  node.open = false
end

function Tree:close_all()
  self.root.children = {}
end

---@param cwd string
---@param ret? string[]
function Tree:dirs(cwd, ret)
  cwd = norm(cwd)
  local node = self:add(cwd)
  ret = ret or {}
  ret[#ret + 1] = cwd
  cwd = cwd == "/" and "" or cwd
  for _, child in pairs(node.children) do
    if child.open then
      local dir = cwd .. "/" .. child.name
      self:dirs(dir, ret)
    end
  end
  return ret
end
local tree = Tree.new()

---@class snacks.picker.explorer.State
---@field cwd string
---@field tree snacks.picker.explorer.Tree
---@field all? boolean
---@field ref snacks.Picker.ref
---@field opts snacks.picker.explorer.Config
---@field on_find? fun()?
---@field git_status {file: string, status: string, sort?:string}[]
local State = {}
State.__index = State
---@param picker snacks.Picker
function State.new(picker)
  local self = setmetatable({}, State)
  self.opts = picker.opts --[[@as snacks.picker.explorer.Config]]
  self.ref = picker:ref()
  local filter = picker:filter()
  self.cwd = filter.cwd
  self.tree = tree
  self.git_status = {}
  local buf = vim.api.nvim_win_get_buf(picker.main)
  local buf_file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if uv.fs_stat(buf_file) then
    self:open(buf_file)
  end
  picker.list.win:on({ "WinEnter", "BufEnter" }, function(_, ev)
    vim.schedule(function()
      if ev.buf == vim.api.nvim_get_current_buf() then
        self:follow()
      end
    end)
  end)
  picker.list.win:on("TermClose", function()
    self:update()
  end, { pattern = "*lazygit" })
  picker.list.win:on("BufWritePost", function(_, ev)
    if self:is_visible(ev.file) then
      self:update()
    end
  end)
  picker.list.win:on("DirChanged", function(_, ev)
    self:set_cwd(vim.fs.normalize(ev.file))
  end)
  -- schedule initial follow
  if self.opts.follow_file then
    self.on_find = function()
      self:show(buf_file)
    end
  end
  return self
end

function State:sort_git_status()
  for _, s in ipairs(self.git_status) do
    if self.tree:in_cwd(self.cwd, s.file) then
      local parts = vim.split(s.file:sub(#self.cwd + 2), "/", { plain = true })
      for i, part in ipairs(parts) do
        parts[i] = (i == #parts and "#" or "!") .. part
      end
      s.sort = table.concat(parts, " ") .. " "
    end
  end
  self.git_status = vim.tbl_filter(function(s)
    return s.sort
  end, self.git_status)
  table.sort(self.git_status, function(a, b)
    return a.sort < b.sort
  end)
end

function State:picker()
  local ret = self.ref()
  return ret and not ret.closed and ret or nil
end

function State:follow()
  if not self.opts.follow_file then
    return
  end
  local picker = self:picker()
  if not picker or picker:is_focused() or not picker:on_current_tab() then
    return
  end
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local item = picker:current()
  if item and item.file == norm(file) then
    return
  end
  self:show(file)
end

---@param path string
---@param opts? {refresh?: boolean}
function State:show(path, opts)
  opts = opts or {}
  path = norm(path)
  if not uv.fs_stat(path) then
    return
  end
  local function show()
    local picker = self:picker()
    if picker then
      for item, idx in picker:iter() do
        if item.file == path then
          picker.list:view(idx)
          break
        end
      end
    end
  end
  local visible = self:is_visible(path)
  if opts.refresh or not visible then
    if not visible then
      self:open(path)
    end
    self:update({ on_done = show })
  else
    show()
  end
end

---@param path string
function State:is_visible(path)
  return self.tree:visible(self.cwd, vim.fs.dirname(path))
end

---@param path string
function State:open(path)
  if not self.tree:in_cwd(self.cwd, path) then
    return
  end
  path = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  self.tree:open(path)
end

---@param item snacks.picker.Item
function State:toggle(item)
  local dir = Snacks.picker.util.path(item)
  if not dir then
    return
  end
  dir = item.dir and dir or vim.fs.dirname(dir)
  if self.tree:visible(self.cwd, dir) then
    self.tree:close(dir)
  else
    self.tree:open(dir)
  end
  self:update()
end

---@param opts snacks.picker.explorer.Config
---@param ctx snacks.picker.finder.ctx
function State:setup(opts, ctx)
  opts = Snacks.picker.util.shallow_copy(opts)
  opts.cmd = "fd"
  opts.cwd = self.cwd
  opts.args = {
    "--type",
    "d", -- include directories
    "--path-separator", -- same everywhere
    "/",
    "--absolute-path", -- easier to work with
    "--follow", -- always needed to make sure we see symlinked dirs as dirs
  }
  self.all = #ctx.filter.search > 0
  if self.all then
    local picker = self:picker()
    if not picker then
      return {}
    end
    picker.list:set_target()
    self.on_find = function()
      if picker.closed then
        return
      end
      for item, idx in picker:iter() do
        if not item.internal then
          picker.list:view(idx)
          return
        end
      end
    end
  else
    opts.dirs = self.tree:dirs(self.cwd)
    vim.list_extend(opts.args, { "--max-depth", "1" })
  end
  return opts
end

---@param opts? {target?: boolean, on_done?: fun()}
function State:update(opts)
  opts = opts or {}
  local picker = self:picker()
  if picker then
    if opts.target ~= false then
      picker.list:set_target()
    end
    picker:find({ on_done = opts.on_done })
  end
end

function State:dir()
  local picker = self:picker()
  if not picker then
    return self.cwd
  end
  local item = picker:current()
  if item and item.dir then
    return item.file
  elseif item then
    return vim.fn.fnamemodify(item.file, ":h")
  else
    return self.cwd
  end
end

---@param cwd string
function State:set_cwd(cwd)
  self.cwd = cwd
  self:update({ target = false })
end

function State:up()
  self:set_cwd(vim.fs.dirname(self.cwd))
end

---@param opts snacks.picker.explorer.Config
function M.setup(opts)
  return Snacks.config.merge(opts, {
    live = true,
    actions = M.actions,
    formatters = {
      file = {
        filename_only = opts.tree,
      },
    },
  })
end

---@type table<string, snacks.picker.Action.spec>
M.actions = {
  explorer_update = function(picker)
    M.get_state(picker):update()
  end,
  explorer_up = function(picker)
    M.get_state(picker):up()
  end,
  explorer_close = function(picker)
    local state = M.get_state(picker)
    local item = picker:current()
    if not item then
      return
    end
    local dir = state:dir()
    if item.dir and not item.open then
      dir = vim.fs.dirname(dir)
    end
    state.tree:close(dir)
    state:show(dir, { refresh = true })
  end,
  explorer_close_all = function(picker)
    M.get_state(picker).tree:close_all()
    M.get_state(picker):update()
  end,
  explorer_add = function(picker)
    local state = M.get_state(picker)
    Snacks.input({
      prompt = 'Add a new file or directory (directories end with a "/")',
    }, function(value)
      if not value or value:find("^%s$") then
        return
      end
      local dir = state:dir()
      local path = vim.fs.normalize(dir .. "/" .. value)
      local is_dir = value:sub(-1) == "/"
      dir = is_dir and path or vim.fs.dirname(path)
      vim.fn.mkdir(dir, "p")
      state:open(dir)
      if not is_dir then
        if uv.fs_stat(path) then
          Snacks.notify.warn("File already exists:\n- `" .. path .. "`")
          return
        end
        io.open(path, "w"):close()
      end
      state:update()
    end)
  end,
  explorer_rename = function(picker, item)
    if not item then
      return
    end
    local state = M.get_state(picker)
    Snacks.rename.rename_file({
      file = item.file,
      on_rename = function(new)
        state:open(new)
        state:update()
      end,
    })
  end,
  explorer_git_next = function(picker, item)
    local state = M.get_state(picker)
    if not item or #state.git_status == 0 then
      return
    end
    for _, s in ipairs(state.git_status) do
      if s.sort and s.sort > item.sort then
        return state:show(s.file)
      end
    end
    return state:show(state.git_status[1].file)
  end,
  explorer_git_prev = function(picker, item)
    local state = M.get_state(picker)
    if not item or #state.git_status == 0 then
      return
    end
    for i = #state.git_status, 1, -1 do
      local s = state.git_status[i]
      if s.sort and s.sort < item.sort then
        return state:show(s.file)
      end
    end
    return state:show(state.git_status[#state.git_status].file)
  end,
  explorer_move = function(picker)
    local state = M.get_state(picker)
    ---@type string[]
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
    if #paths == 0 then
      Snacks.notify.warn("No files selected to move")
      return
    end
    local target = state:dir()
    local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
    local t = vim.fn.fnamemodify(target, ":p:~:.")

    Snacks.picker.select({ "Yes", "No" }, { prompt = "Move " .. what .. " to " .. t .. "?" }, function(_, idx)
      if idx == 1 then
        for _, from in ipairs(paths) do
          local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
          Snacks.rename.on_rename_file(from, to, function()
            local ok, err = pcall(vim.fn.rename, from, to)
            if not ok then
              Snacks.notify.error("Failed to move `" .. from .. "`:\n- " .. err)
            end
          end)
        end
        state:update()
      end
    end)
  end,
  explorer_copy = function(picker, item)
    if not item then
      return
    end
    if item.dir then
      Snacks.notify.warn("Cannot copy directories")
      return
    end
    local state = M.get_state(picker)
    Snacks.input({
      prompt = "Copy to",
    }, function(value)
      if not value or value:find("^%s$") then
        return
      end
      local dir = state:dir()
      local path = vim.fs.normalize(dir .. "/" .. value)
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      state:open(dir)
      if uv.fs_stat(path) then
        Snacks.notify.warn("File already exists:\n- `" .. path .. "`")
        return
      end
      uv.fs_copyfile(item.file, path, function(err)
        if err then
          Snacks.notify.error("Failed to copy `" .. item.file .. "` to `" .. path .. "`:\n- " .. err)
        end
        state:update()
      end)
    end)
  end,
  explorer_del = function(picker)
    local state = M.get_state(picker)
    ---@type string[]
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
    if #paths == 0 then
      return
    end
    local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
    Snacks.picker.select({ "Yes", "No" }, { prompt = "Delete " .. what .. "?" }, function(_, idx)
      if idx == 1 then
        for _, path in ipairs(paths) do
          local ok, err = pcall(vim.fn.delete, path, "rf")
          if not ok then
            Snacks.notify.error("Failed to delete `" .. path .. "`:\n- " .. err)
          end
        end
        state:update()
      end
    end)
  end,
  explorer_focus = function(picker)
    local state = M.get_state(picker)
    state:set_cwd(state:dir())
  end,
  explorer_open = function(picker, item)
    if item then
      local _, err = vim.ui.open(item.file)
      if err then
        Snacks.notify.error("Failed to open `" .. item.file .. "`:\n- " .. err)
      end
    end
  end,
  explorer_yank = function(_, item)
    if not item then
      return
    end
    vim.fn.setreg("+", item.file)
    Snacks.notify.info("Yanked `" .. item.file .. "`")
  end,
  explorer_cd = function(picker)
    local state = M.get_state(picker)
    vim.fn.chdir(state:dir())
  end,
  confirm = function(picker, item, action)
    local state = M.get_state(picker)
    local item = picker:current()
    if not item then
      return
    elseif item.dir then
      if state.all then
        picker.input:set("", "")
        state:set_cwd(item.file)
        return
      end
      state:toggle(item)
    else
      Snacks.picker.actions.jump(picker, item, action)
    end
  end,
}

---@param picker snacks.Picker
function M.get_state(picker)
  if not M._state[picker] then
    M._state[picker] = State.new(picker)
  end
  return M._state[picker]
end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
function M.explorer(opts, ctx)
  local state = M.get_state(ctx.picker)
  opts = state:setup(opts, ctx)
  opts.notify = false
  local expanded = {} ---@type table<string, boolean>
  for _, dir in ipairs(opts.dirs or {}) do
    expanded[dir] = true
  end
  -- vim.notify(table.concat(opts.dirs or {}, "\n"), "info")

  ---@param path string
  local function is_open(path)
    return state.all or expanded[path]
  end

  local Git = require("snacks.picker.source.git")

  local files = require("snacks.picker.source.files").files(opts, ctx)
  local git = Git.status(opts, ctx)

  local dirs = {} ---@type table<string, snacks.picker.explorer.Item>
  local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>

  ---@type snacks.picker.explorer.Item
  local root = {
    file = state.cwd,
    dir = true,
    open = true,
    text = "",
    sort = "",
    internal = true,
  }
  local cwd = state.cwd
  dirs[cwd] = root
  state.git_status = {}

  local items = {} ---@type table<string, snacks.picker.explorer.Item>
  ---@async
  return function(cb)
    if state.on_find then
      ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
      state.on_find = nil
    end
    items[cwd] = root
    cb(root)

    ---@param item snacks.picker.explorer.Item
    local function add(item)
      local dirname, basename = item.file:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or item.file
      local parent = dirs[dirname] ~= item and dirs[dirname] or root

      -- hierarchical sorting
      if item.dir then
        item.sort = parent.sort .. "!" .. basename .. " "
      else
        item.sort = parent.sort .. "#" .. basename .. " "
      end

      if opts.tree then
        -- tree
        item.parent = parent
        if not last[parent] or last[parent].sort < item.sort then
          if last[parent] then
            last[parent].last = false
          end
          item.last = true
          last[parent] = item
        end
      end
      items[item.file] = item
      -- add to picker
      cb(item)
    end

    -- gather git status in a separate coroutine,
    -- so that both git and fd can run in parallel
    local git_async ---@type snacks.picker.Async?
    if opts.git_status then
      git_async = require("snacks.picker.util.async").new(function()
        git(function(item)
          local path = Snacks.picker.util.path(item)
          if path then
            table.insert(state.git_status, { file = path, status = item.status })
          end
        end)
      end)
    end

    -- get files and directories
    files(function(item)
      ---@cast item snacks.picker.explorer.Item
      item.cwd = nil -- we use absolute paths

      -- Directories
      if item.file:sub(-1) == "/" then
        item.dir = true
        item.file = item.file:sub(1, -2)
        if dirs[item.file] then
          dirs[item.file].internal = false
          return
        end
        item.open = is_open(item.file)
        dirs[item.file] = item
      end

      -- Add parents when needed
      for dir in Snacks.picker.util.parents(item.file, cwd) do
        if not dirs[dir] then
          dirs[dir] = {
            text = dir,
            file = dir,
            dir = true,
            open = is_open(dir),
            internal = true,
          }
          add(dirs[dir])
        end
      end

      add(item)
    end)

    -- wait for git status to finish
    if git_async then
      git_async:wait()
    end

    local function add_git_status(path, status)
      if not opts.git_status_open and is_open(path) then
        return
      end
      local item = items[path]
      if item then
        if item.status then
          item.status = Git.merge_status(item.status, status)
        else
          item.status = status
        end
      end
    end

    state:sort_git_status()

    -- Add git status to files and parents
    for _, s in ipairs(state.git_status) do
      local file, status = s.file, s.status
      add_git_status(file, status)
      add_git_status(cwd, status)
      for dir in Snacks.picker.util.parents(file, cwd) do
        add_git_status(dir, status)
      end
    end
  end
end

return M
