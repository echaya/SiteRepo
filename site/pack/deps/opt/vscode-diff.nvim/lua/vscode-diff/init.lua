-- vscode-diff main API
local M = {}

-- Configuration setup - the ONLY public API users need
function M.setup(opts)
  local config = require("vscode-diff.config")
  config.setup(opts)
  
  local render = require("vscode-diff.render")
  render.setup_highlights()
end

return M
