---@class snacks.picker.input
---@field win snacks.win
---@field totals string
---@field picker snacks.Picker
---@field filter snacks.picker.Filter
local M = {}
M.__index = M

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("snacks.picker.input")

---@param picker snacks.Picker
function M.new(picker)
  local self = setmetatable({}, M)
  self.totals = ""
  self.picker = picker
  self.filter = require("snacks.picker.core.filter").new(picker)
  picker.matcher:init(self.filter.pattern)

  self.win = Snacks.win(Snacks.win.resolve(picker.opts.win.input, {
    show = false,
    enter = true,
    height = 1,
    text = picker.opts.live and self.filter.search or self.filter.pattern,
    ft = "regex",
    on_win = function(win)
      -- HACK: set all other picker input prompt buffers to nofile.
      -- Otherwise when the prompt buffer is closed,
      -- Neovim always stops insert mode.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= win.buf and vim.bo[buf].filetype == "snacks_picker_input" then
          vim.bo[buf].buftype = "nofile"
        end
      end
      vim.fn.prompt_setprompt(win.buf, "")
      win:focus()
      vim.cmd("startinsert!")
    end,
    bo = {
      filetype = "snacks_picker_input",
      buftype = "prompt",
    },
    wo = {
      statuscolumn = self:statuscolumn(),
      cursorline = false,
      winhighlight = Snacks.picker.highlight.winhl("SnacksPickerInput"),
    },
  }))

  local ref = Snacks.util.ref(self)
  self.win:on(
    { "TextChangedI", "TextChanged" },
    Snacks.util.throttle(function()
      local input = ref()
      if not input or not input.win:valid() then
        return
      end
      -- only one line
      -- Can happen when someone pastes a multiline string
      if vim.api.nvim_buf_line_count(input.win.buf) > 1 then
        local line = vim.trim(input.win:text():gsub("\n", " "))
        vim.api.nvim_buf_set_lines(input.win.buf, 0, -1, false, { line })
        vim.api.nvim_win_set_cursor(input.win.win, { 1, #line + 1 })
      end
      vim.bo[input.win.buf].modified = false
      local pattern = input:get()
      if input.picker.opts.live then
        input.filter.search = pattern
      else
        input.filter.pattern = pattern
      end
      vim.schedule(function()
        input.picker:find({ refresh = false })
      end)
    end, { ms = picker.opts.live and 100 or 30 }),
    { buf = true }
  )
  return self
end

function M:close()
  self.win:destroy()
  self.picker = nil -- needed for garbage collection of the picker
end

function M:stopinsert()
  -- only stop insert mode if needed
  if not vim.fn.mode():find("^i") then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  -- if the other buffer is a prompt, then don't stop insert mode
  if buf ~= self.win.buf and vim.bo[buf].buftype == "prompt" then
    return
  end
  vim.cmd("stopinsert")
end

function M:statuscolumn()
  local parts = {} ---@type string[]
  local function add(str, hl)
    if str then
      parts[#parts + 1] = ("%%#%s#%s%%*"):format(hl, str:gsub("%%", "%%"))
    end
  end
  local pattern = self.picker.opts.live and self.filter.pattern or self.filter.search
  if pattern ~= "" then
    if #pattern > 20 then
      pattern = Snacks.picker.util.truncate(pattern, 20)
    end
    add(pattern, "SnacksPickerInputSearch")
  end
  add(self.picker.opts.prompt or " ", "SnacksPickerPrompt")
  return table.concat(parts, " ")
end

function M:update()
  if not self.win:valid() then
    return
  end
  local sc = self:statuscolumn()
  if self.win.opts.wo.statuscolumn ~= sc then
    self.win.opts.wo.statuscolumn = sc
    Snacks.util.wo(self.win.win, { statuscolumn = sc })
  end
  local line = {} ---@type snacks.picker.Highlight[]
  if self.picker:is_active() then
    line[#line + 1] = { M.spinner(), "SnacksPickerSpinner" }
    line[#line + 1] = { " " }
  end
  local selected = #self.picker.list.selected
  if selected > 0 then
    line[#line + 1] = { ("(%d)"):format(selected), "SnacksPickerTotals" }
    line[#line + 1] = { " " }
  end
  line[#line + 1] = { ("%d/%d"):format(self.picker.list:count(), #self.picker.finder.items), "SnacksPickerTotals" }
  line[#line + 1] = { " " }
  local totals = table.concat(vim.tbl_map(function(v)
    return v[1]
  end, line))
  if self.totals == totals then
    return
  end
  self.totals = totals
  vim.api.nvim_buf_set_extmark(self.win.buf, ns, 0, 0, {
    id = 999,
    virt_text = line,
    virt_text_pos = "right_align",
  })
end

function M:get()
  return self.win:line()
end

---@param pattern? string
---@param search? string
function M:set(pattern, search)
  self.filter.pattern = pattern or self.filter.pattern
  self.filter.search = search or self.filter.search
  vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, {
    self.picker.opts.live and self.filter.search or self.filter.pattern,
  })
  vim.api.nvim_win_set_cursor(self.win.win, { 1, #self:get() + 1 })
  self.totals = ""
  self.win.opts.wo.statuscolumn = ""
  self:update()
  self.picker:update_titles()
end

function M.spinner()
  local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  return spinner[math.floor(uv.hrtime() / (1e6 * 80)) % #spinner + 1]
end

return M
