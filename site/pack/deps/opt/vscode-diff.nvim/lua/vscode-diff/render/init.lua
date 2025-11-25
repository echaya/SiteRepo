-- Render module facade
local M = {}

local highlights = require('vscode-diff.render.highlights')
local view = require('vscode-diff.render.view')
local core = require('vscode-diff.render.core')
local lifecycle = require('vscode-diff.render.lifecycle')

-- Public functions
M.setup_highlights = highlights.setup
M.create_diff_view = view.create
M.update_diff_view = view.update
M.render_diff = core.render_diff

-- Initialize lifecycle management
lifecycle.setup()

return M
