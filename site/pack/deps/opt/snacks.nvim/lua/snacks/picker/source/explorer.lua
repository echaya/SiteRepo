local Async = require("snacks.picker.util.async")
local Git = require("snacks.picker.source.git")

local M = {}

---@class snacks.picker
---@field explorer fun(opts?: snacks.picker.explorer.Config|{}): snacks.Picker

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
-- global git status
local git_tree_status = {} ---@type table<string, string>

---@class snacks.picker.explorer.State
---@field cwd string
---@field tick number
---@field tree snacks.picker.explorer.Tree
---@field all? boolean
---@field ref snacks.Picker.ref
---@field opts snacks.picker.explorer.Config
---@field on_find? fun()?
---@field git_status {file: string, status: string, sort?:string}[]
---@field expanded table<string, boolean>
---@field cache table<string, snacks.picker.explorer.Item[]>
---@field cache_opts? snacks.picker.explorer.Config|{}
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
  self.tick = 0
  self.git_status = {}
  self.expanded = {}
  self.cache = {}
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
    self:update({ force = true })
  end, { pattern = "*lazygit" })
  picker.list.win:on("BufWritePost", function(_, ev)
    if self:is_visible(ev.file) then
      self:update({ force = true })
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

function State:update_git_status()
  -- Setup hierarchical sorting
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

  -- Update tree status
  git_tree_status = {}

  ---@param path string
  ---@param status string
  local function add_git_status(path, status)
    git_tree_status[path] = git_tree_status[path] and Git.merge_status(git_tree_status[path], status) or status
  end

  -- Add git status to files and parents
  for _, s in ipairs(self.git_status) do
    local path = s.file:gsub("/$", "")
    add_git_status(path, s.status)
    if s.status:sub(1, 1) ~= "!" then -- don't propagate ignored status
      add_git_status(self.cwd, s.status)
      for dir in Snacks.picker.util.parents(path, self.cwd) do
        add_git_status(dir, s.status)
      end
    end
  end
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
  self.tick = self.tick + 1
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
  self.expanded = {}
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
    for _, dir in ipairs(opts.dirs or {}) do
      self.expanded[dir] = true
    end
    vim.list_extend(opts.args, { "--max-depth", "1" })
  end
  return opts
end

---@param opts? {target?: boolean, on_done?: fun(), force?: boolean}
function State:update(opts)
  opts = opts or {}
  if opts.force then
    self.cache = {}
  end
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

---@param prompt string
---@param fn fun()
function M.confirm(prompt, fn)
  Snacks.picker.select({ "Yes", "No" }, { prompt = prompt }, function(_, idx)
    if idx == 1 then
      fn()
    end
  end)
end

---@type table<string, snacks.picker.Action.spec>
M.actions = {
  explorer_update = function(picker)
    M.get_state(picker):update({ force = true })
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
      state:update({ force = true })
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
        state:update({ force = true })
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
      Snacks.notify.warn("No files selected to move. Renaming instead.")
      return M.actions.explorer_rename(picker, picker:current())
    end
    local target = state:dir()
    local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
    local t = vim.fn.fnamemodify(target, ":p:~:.")

    M.confirm("Move " .. what .. " to " .. t .. "?", function()
      for _, from in ipairs(paths) do
        local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
        Snacks.rename.on_rename_file(from, to, function()
          local ok, err = pcall(vim.fn.rename, from, to)
          if not ok then
            Snacks.notify.error("Failed to move `" .. from .. "`:\n- " .. err)
          end
        end)
      end
      picker.list:set_selected() -- clear selection
      state:update({ force = true })
    end)
  end,
  explorer_copy = function(picker, item)
    if not item then
      return
    end
    local state = M.get_state(picker)
    ---@type string[]
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
    -- Copy selection
    if #paths > 0 then
      local dir = state:dir()
      Snacks.picker.util.copy(paths, dir)
      state:open(dir)
      picker.list:set_selected() -- clear selection
      state:update({ force = true })
      return
    end
    Snacks.input({
      prompt = "Copy to",
    }, function(value)
      if not value or value:find("^%s$") then
        return
      end
      local dir = vim.fs.dirname(item.file)
      local to = vim.fs.normalize(dir .. "/" .. value)
      if uv.fs_stat(to) then
        Snacks.notify.warn("File already exists:\n- `" .. to .. "`")
        return
      end
      Snacks.picker.util.copy_path(item.file, to)
      state:open(dir)
      state:update({ force = true })
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
    M.confirm("Delete " .. what .. "?", function()
      for _, path in ipairs(paths) do
        local ok, err = pcall(vim.fn.delete, path, "rf")
        if not ok then
          Snacks.notify.error("Failed to delete `" .. path .. "`:\n- " .. err)
        end
      end
      state:update({ force = true })
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
  local tick = state.tick
  opts.notify = false
  local expanded = {} ---@type table<string, boolean>
  local cache_opts = { hidden = opts.hidden, ignored = opts.ignored }

  local use_cache = not state.all and vim.deep_equal(state.cache_opts, cache_opts)
  for _, dir in ipairs(opts.dirs or {}) do
    expanded[dir] = true
    use_cache = use_cache and state.cache[dir] ~= nil
  end

  if not use_cache then
    state.cache = {}
    state.cache_opts = cache_opts
  end

  ---@param path string
  local function is_open(path)
    return state.all or expanded[path]
  end

  ---@param item snacks.picker.explorer.Item
  local function add_git_status(item)
    item.status = git_tree_status[item.file or ""] or nil
    local ignored = item.status and item.status:sub(1, 1) == "!"
    if item.open and not opts.git_status_open and not ignored then
      item.status = nil
    end
    if item.status and ignored then
      item.ignored = true
    end
  end

  ---@type snacks.picker.explorer.Item
  local root = {
    file = state.cwd,
    dir = true,
    open = true,
    text = "",
    sort = "",
    internal = true,
  }

  if use_cache then
    local ret = { root } ---@type snacks.picker.explorer.Item[]
    for _, dir in ipairs(opts.dirs or {}) do
      for _, item in ipairs(state.cache[dir]) do
        item.open = is_open(item.file)
        add_git_status(item)
        table.insert(ret, item)
      end
    end
    if state.on_find then
      state.on_find()
      state.on_find = nil
    end
    return ret
  end

  local files = require("snacks.picker.source.files").files(opts, ctx)
  local git = Git.status(opts, ctx)

  local dirs = {} ---@type table<string, snacks.picker.explorer.Item>
  local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>

  local cwd = state.cwd
  dirs[cwd] = root
  state.git_status = {}

  ---@async
  return function(cb)
    if state.on_find then
      ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
      state.on_find = nil
    end
    cb(root)

    ---@param item snacks.picker.explorer.Item
    local function add(item)
      local dirname, basename = item.file:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or item.file
      local parent = dirs[dirname] ~= item and dirs[dirname] or root

      state.cache[dirname] = state.cache[dirname] or {}
      table.insert(state.cache[dirname], item)

      -- hierarchical sorting
      if item.dir then
        item.sort = parent.sort .. "!" .. basename .. " "
      else
        item.sort = parent.sort .. "#" .. basename .. " "
      end
      if basename:sub(1, 1) == "." then
        item.hidden = true
      end
      add_git_status(item)

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
      -- add to picker
      cb(item)
    end
    -- ctx.async:sleep(1000)

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

    -- gather git status in a separate coroutine,
    -- so that git doesn't block the picker
    if opts.git_status then
      ---@async
      Async.new(function()
        local me = Async.running()

        local check = function() -- check if we need to abort
          return state.tick ~= tick or ctx.picker.closed and me:abort()
        end

        -- fetch git status
        git(function(item)
          check()
          table.insert(state.git_status, {
            file = Snacks.picker.util.path(item),
            status = item.status,
          })
        end)
        check()

        state:update_git_status()

        ctx.async:wait() -- wait till fd is done
        check()
        -- add git status to picker items
        for item in ctx.picker:iter() do
          ---@cast item snacks.picker.explorer.Item
          add_git_status(item)
        end
        ctx.picker:update({ force = true })
      end)
    end
  end
end

return M
