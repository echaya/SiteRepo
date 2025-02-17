local Markdown = require("noice.text.markdown")
local require = require("noice.util.lazy")

local Config = require("noice.config")
local Format = require("noice.lsp.format")
local Hacks = require("noice.util.hacks")
local Message = require("noice.message")

local M = {}

function M.setup()
  if Config.options.lsp.override["cmp.entry.get_documentation"] then
    Hacks.on_module("cmp.entry", function(mod)
      mod.get_documentation = M.cmp_get_documentation
    end)
  end

  if Config.options.lsp.override["vim.lsp.util.convert_input_to_markdown_lines"] then
    vim.lsp.util.convert_input_to_markdown_lines = M.convert_input_to_markdown_lines
  end

  if Config.options.lsp.override["vim.lsp.util.stylize_markdown"] then
    vim.lsp.util.stylize_markdown = M.stylize_markdown
  end
end

function M.cmp_get_documentation(self)
  local item = self:get_completion_item()

  local lines = item.documentation and Format.format_markdown(item.documentation) or {}
  local ret = table.concat(lines, "\n")
  local detail = item.detail
  if detail and type(detail) == "table" then
    detail = table.concat(detail, "\n")
  end

  if detail and not ret:find(detail, 1, true) then
    local ft = self.context.filetype
    local dot_index = string.find(ft, "%.")
    if dot_index ~= nil then
      ft = string.sub(ft, 0, dot_index - 1)
    end
    ret = ("```%s\n%s\n```\n%s"):format(ft, vim.trim(detail), ret)
  end
  return vim.split(ret, "\n")
end

function M.convert_input_to_markdown_lines(input, contents)
  contents = contents or {}
  local ret = Format.format_markdown(input)
  vim.list_extend(contents, ret)
  return contents
end

function M.stylize_markdown(buf, contents, _opts)
  vim.api.nvim_buf_clear_namespace(buf, Config.ns, 0, -1)
  local text = table.concat(contents, "\n")
  local message = Message("lsp")
  Markdown.format(message, text)
  message:render(buf, Config.ns)
  Markdown.keys(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

return M
