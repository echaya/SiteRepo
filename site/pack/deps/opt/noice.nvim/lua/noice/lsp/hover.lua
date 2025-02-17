local require = require("noice.util.lazy")

local Config = require("noice.config")
local Docs = require("noice.lsp.docs")
local Format = require("noice.lsp.format")
local Util = require("noice.util")

local M = {}

function M.on_hover(_, result, ctx)
  if not (result and result.contents) then
    if Config.options.lsp.hover.silent ~= true then
      vim.notify("No information available")
    end
    return
  end

  local message = Docs.get("hover")

  if not message:focus() then
    Format.format(message, result.contents, { ft = vim.bo[ctx.bufnr].filetype })
    if message:is_empty() then
      if Config.options.lsp.hover.silent ~= true then
        vim.notify("No information available")
      end
      return
    end
    Docs.show(message)
  end
end
M.on_hover = Util.protect(M.on_hover)

return M
