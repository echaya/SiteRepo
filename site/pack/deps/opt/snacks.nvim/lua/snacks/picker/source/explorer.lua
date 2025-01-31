local M = {}

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

---@class snacks.picker.explorer.State
---@field cwd string
---@field expanded table<string, boolean>
---@field all? boolean
---@field picker snacks.Picker.ref
---@field opts snacks.picker.explorer.Config
---@field on_find? fun()?
local State = {}
State.__index = State
---@param picker snacks.Picker
function State.new(picker)
  local self = setmetatable({}, State)
  self.opts = picker.opts --[[@as snacks.picker.explorer.Config]]
  self.picker = picker:ref()
  local filter = picker:filter()
  self.cwd = filter.cwd
  self.expanded = { [self.cwd] = true }
  local buf = vim.api.nvim_win_get_buf(picker.main)
  local buf_file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if uv.fs_stat(buf_file) then
    self:expand(buf_file)
  end
  picker.list.win:on({ "WinEnter", "BufEnter" }, function()
    self:follow()
  end)
  -- schedule initial follow
  if self.opts.follow_file then
    self.on_find = function()
      self.on_find = nil
      self:show(buf_file)
    end
  end
  return self
end

function State:follow()
  if not self.opts.follow_file then
    return
  end
  local picker = self.picker()
  if not picker or picker:is_focused() or picker.closed or picker.jumping then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  self:show(file)
end

---@param path string
function State:show(path)
  local picker = self.picker()
  if not picker then
    return
  end
  path = vim.fs.normalize(path)
  if not uv.fs_stat(path) then
    return
  end
  local function show()
    for item, idx in picker:iter() do
      if item.file == path then
        picker.list:view(idx)
        break
      end
    end
  end
  if not self:is_visible(path) then
    self:expand(path)
    self:update({ on_done = show })
  else
    show()
  end
end

---@param path string
function State:is_visible(path)
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  if not self:in_cwd(dir) then
    return false
  end
  if not self.expanded[dir] then
    return false
  end
  for p, v in pairs(self.expanded) do
    if not v and p:find(dir .. "/", 1, true) == 1 then
      return false
    end
  end
  return true
end

---@param dir string
function State:is_open(dir)
  return self.all or self.expanded[dir]
end

function State:in_cwd(path)
  return path == self.cwd or path:find(self.cwd .. "/", 1, true) == 1
end

---@param path string
function State:expand(path)
  if not self:in_cwd(path) then
    return
  end
  if vim.fn.isdirectory(path) == 1 then
    self.expanded[path] = true
  else
    self.expanded[vim.fs.dirname(path)] = true
  end
  for p in vim.fs.parents(path) do
    if not self:in_cwd(p) then
      break
    end
    self.expanded[p] = true
  end
end

---@param item snacks.picker.Item
function State:toggle(item)
  local dir = Snacks.picker.util.path(item)
  if not dir then
    return
  end
  self.expanded[dir] = not self.expanded[dir]
  if self.expanded[dir] then
    self:expand(dir)
  end
  self:update()
end

function State:expand_dirs()
  local expand = {} ---@type table<string, boolean>
  local exclude = {} ---@type table<string, boolean>
  for k, v in pairs(self.expanded) do
    if self:in_cwd(k) then
      (v and expand or exclude)[k] = true
    end
  end
  -- remove excluded directories
  for p in pairs(expand) do
    for e in pairs(exclude) do
      if p:find(e .. "/", 1, true) == 1 then
        expand[p] = nil
        break
      end
    end
  end
  local ret = vim.tbl_keys(expand) ---@type string[]
  -- add parents
  for p in pairs(expand) do
    for pp in vim.fs.parents(p) do
      if expand[pp] or not self:in_cwd(pp) then
        break
      end
      expand[pp] = true
      ret[#ret + 1] = pp
    end
  end
  return ret
end

---@param opts snacks.picker.explorer.Config
---@param ctx snacks.picker.finder.ctx
function State:setup(opts, ctx)
  opts = Snacks.picker.util.shallow_copy(opts)
  opts.cmd = "fd"
  opts.cwd = self.cwd
  opts.args = { "--type", "d", "--path-separator", "/", "--absolute-path" }
  self.all = #ctx.filter.search > 0
  if self.all then
    local picker = self.picker()
    if not picker then
      return {}
    end
    picker.list:set_target()
    self.on_find = function()
      for item, idx in picker:iter() do
        if not item.internal then
          picker.list:view(idx)
          return
        end
      end
    end
  else
    opts.dirs = self:expand_dirs()
    vim.list_extend(opts.args, { "--max-depth", "1" })
  end
  return opts
end

---@param opts? {target?: boolean, on_done?: fun()}
function State:update(opts)
  opts = opts or {}
  local picker = self.picker()
  if not picker then
    return
  end
  if opts.target ~= false then
    picker.list:set_target()
  end
  picker:find({ on_done = opts.on_done })
end

function State:dir()
  local picker = self.picker()
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

function State:set_cwd(cwd)
  self.cwd = cwd
  self.expanded[cwd] = true
  for k in pairs(self.expanded) do
    if not self:in_cwd(k) then
      self.expanded[k] = nil
    end
  end
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
  explorer_up = function(picker)
    M.get_state(picker):up()
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
      state:expand(dir)
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
        state:expand(new)
        state:update()
      end,
    })
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
      state:expand(dir)
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
  explorer_move = function(picker)
    local state = M.get_state(picker)
    ---@type string[]
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
    if #paths == 0 then
      Snacks.notify.warn("No files selected to move")
      return
    end
    local to = state:dir()
    local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
    local t = vim.fn.fnamemodify(to, ":p:~:.")

    Snacks.picker.select({ "Yes", "No" }, { prompt = "Move " .. what .. " to " .. t .. "?" }, function(_, idx)
      if idx == 1 then
        for _, path in ipairs(paths) do
          local ok, err = pcall(vim.fn.rename, path, to .. "/" .. vim.fn.fnamemodify(path, ":t"))
          if not ok then
            Snacks.notify.error("Failed to move `" .. path .. "`:\n- " .. err)
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
    state:set_cwd(vim.fn.getcwd())
  end,
  confirm = function(picker)
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
      picker:action("jump")
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

  local files = require("snacks.picker.source.files").files(opts, ctx)
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

  return function(cb)
    if state.on_find then
      ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
    end
    cb(root)

    ---@param item snacks.picker.explorer.Item
    local function add(item)
      local dirname, basename = item.file:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or item.file
      local parent = dirs[dirname] ~= item and dirs[dirname] or root

      -- hierarchical sorting
      if item.dir then
        item.sort = parent.sort .. "/0" .. basename
      else
        item.sort = parent.sort .. "/1" .. basename
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
      -- add to picker
      cb(item)
    end

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
        item.open = state:is_open(item.file)
        dirs[item.file] = item
      end

      -- Add parents when needed
      if item.file:sub(1, #cwd) == cwd and #item.file > #cwd then
        local path = item.file
        local to = #cwd + 1 ---@type number?
        while to do
          to = path:find("/", to + 1, true)
          if not to then
            break
          end
          local dir = path:sub(1, to - 1)
          if not dirs[dir] then
            dirs[dir] = {
              text = dir,
              file = dir,
              dir = true,
              open = state:is_open(dir),
              internal = true,
            }
            add(dirs[dir])
          end
        end
      end

      add(item)
    end)
  end
end

return M
