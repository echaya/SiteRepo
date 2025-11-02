---@class snacks.gh.Diff
---@field opts snacks.gh.Config
---@field level number
---@field path string
---@field hunk string
---@field ft string
---@field context number
---@field diff snacks.gh.diff.Line[]
---@field comment snacks.gh.Comment
local M = {}
M.__index = M

---@class snacks.gh.diff.Line
---@field type " "|"+"|"-"
---@field line number
---@field lines string[]
---@field virt_lines snacks.picker.Text[][]

local diff_types = {
  [" "] = "SnacksGhDiffContext",
  ["+"] = "SnacksGhDiffAdd",
  ["-"] = "SnacksGhDiffDelete",
}

---@param virt_text snacks.picker.Text[]
---@return snacks.picker.Extmark
local function vt(virt_text)
  return { virt_text = virt_text, virt_text_pos = "overlay", col = 0, hl_mode = "replace", priority = 200 }
end

---@param comment snacks.gh.Comment
---@param level number
---@param opts snacks.gh.Config
function M.new(comment, level, opts)
  local self = setmetatable({}, M)
  self.opts = opts
  self.level = level
  self.path = comment.path
  self.hunk = comment.diffHunk
  self.ft = ""
  self.comment = comment
  self.diff = {}
  self:compute()
  return self
end

function M:compute()
  -- lines and types
  local lines = vim.split(self.hunk, "\n", { plain = true })
  table.remove(lines, 1) -- remove hunk header
  local types = {} ---@type string[]
  for l, line in ipairs(lines) do
    types[l], lines[l] = line:sub(1, 1), line:sub(2)
  end
  local count = 1
  self.comment.originalLine = self.comment.originalLine or self.comment.line or 1
  if self.comment.originalStartLine then
    count = self.comment.originalLine - self.comment.originalStartLine + 1
  end
  self.context = math.min(#lines, math.max(self.opts.diff.min, math.abs(count)))

  -- filetype
  self.ft = vim.filetype.match({ filename = self.path, contents = lines }) or ""

  local virt_lines = Snacks.picker.highlight.get_virtual_lines(table.concat(lines, "\n"), { ft = self.ft })

  for l = 1, #lines do
    ---@type snacks.gh.diff.Line
    local line = {
      type = types[l],
      line = self.comment.originalLine - #lines + l,
      lines = { "" },
      virt_lines = { {} },
    }
    self.diff[l] = line
    local virt_line = virt_lines[l] or {}
    local w = 0
    for _, chunk in ipairs(virt_line) do
      local chunk_width = vim.api.nvim_strwidth(chunk[1])

      -- split chunk if too long
      while chunk_width > self.opts.diff.wrap do
        local left = vim.fn.strcharpart(chunk[1], 0, self.opts.diff.wrap)
        local right = chunk[1]:sub(#left + 1)
        vim.list_extend(line.virt_lines, { { { left, chunk[2] } }, {} })
        vim.list_extend(line.lines, { left, "" })
        w = 0
        chunk = { right, chunk[2] }
        chunk_width = vim.api.nvim_strwidth(chunk[1])
      end

      -- wrap line if needed
      if w > 0 and w + chunk_width > self.opts.diff.wrap then
        w = 0
        table.insert(line.virt_lines, {})
        table.insert(line.lines, "")
      end

      w = w + chunk_width
      table.insert(line.virt_lines[#line.virt_lines], chunk)
      line.lines[#line.lines] = line.lines[#line.lines] .. chunk[1]
    end
  end
end

-- Plugins like render-markdown or markview.nvim, may interfere with virtual text rendering.
-- To avoid that, we use 'overlay' virt_text position with 'replace' hl_mode,
-- to render the whole diff block.
-- The regular text is still added in a code block, so that it can be copied correctly.
-- The rendered diff, has filetype specific highlights, and line numbers, and diff highlights.
function M:format()
  local ret = {} ---@type snacks.picker.Highlight[][]
  local offset = math.max(1, #self.diff - self.context + 1)
  local indent_extmark = require("snacks.gh.render").indent(self.level)
  local indent = indent_extmark.virt_text ---@type snacks.picker.Text[]
  local indent_width = Snacks.picker.highlight.offset(indent)
  local a = Snacks.picker.util.align
  local lino_width = #tostring(self.comment.originalLine) + 2
  local hl_header = "SnacksGhDiffHeader"

  ret[#ret + 1] = { indent_extmark }
  ret[#ret + 1] = {
    vt(vim.list_extend(vim.deepcopy(indent), {
      { a("", self.opts.diff.wrap + 3 + lino_width), hl_header },
    })),
  }
  local icon, icon_hl = Snacks.util.icon(self.path)

  ret[#ret + 1] = {
    vt(vim.list_extend(vim.deepcopy(indent), {
      { "  ", hl_header },
      { icon, icon_hl and { hl_header, icon_hl } or icon_hl },
      { "  ", hl_header },
      {
        self.path .. a(
          "",
          self.opts.diff.wrap + lino_width - vim.api.nvim_strwidth(self.path) + vim.api.nvim_strwidth(icon) - 3
        ),
        "SnacksGhDiffHeader",
      },
    })),
    { a("", vim.api.nvim_strwidth(icon) + indent_width) .. self.path },
  }
  ret[#ret + 1] = ret[#ret - 1] -- repeat border
  ret[#ret + 1] = { indent_extmark, { "```" } }

  for l = offset, #self.diff do
    local diff = self.diff[l]
    local hl = diff_types[diff.type] or diff_types[" "]

    for i, str in ipairs(diff.lines) do
      local virt_text = {} ---@type snacks.picker.Text[]
      local id = a("", lino_width, { align = "right" })
      vim.list_extend(virt_text, indent)
      if i == 1 then -- first visual line
        table.insert(virt_text, { a(tostring(diff.line) .. " ", lino_width, { align = "right" }), hl .. "LineNr" })
        table.insert(virt_text, { " " .. diff.type .. " ", hl })
      else -- wrapped line
        table.insert(virt_text, { id, hl .. "LineNr" })
        table.insert(virt_text, { "   ", hl })
      end
      for _, chunk in ipairs(diff.virt_lines[i] or {}) do
        if type(chunk[2]) == "string" then
          chunk[2] = { chunk[2], hl }
        elseif chunk[2] == nil then
          chunk[2] = hl
        end
        table.insert(virt_text, chunk)
      end
      table.insert(virt_text, { string.rep(" ", self.opts.diff.wrap - vim.api.nvim_strwidth(str)), hl })
      ret[#ret + 1] = { { a("", indent_width + lino_width - 1) .. str }, vt(virt_text) }
    end
  end
  ret[#ret + 1] = { indent_extmark, { "```" } }
  return ret
end

return M
