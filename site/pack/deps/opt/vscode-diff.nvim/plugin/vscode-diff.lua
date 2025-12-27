-- Backward compatibility plugin entry point
-- Ensures old :VscodeDiff command still works
if vim.g.loaded_vscode_diff then
  return
end
vim.g.loaded_vscode_diff = 1

-- Ensure codediff is loaded first (it sets up everything)
require("codediff")

-- Create legacy command alias
local commands = require("codediff.commands")

vim.api.nvim_create_user_command("VscodeDiff", commands.vscode_diff, {
  nargs = "*",
  bang = true,
  complete = function(arg_lead, cmd_line, cursor_pos)
    -- Reuse the same completion from CodeDiff
    local git = require('codediff.core.git')
    local cwd = vim.fn.getcwd()
    local git_root = git.get_git_root_sync(cwd)
    local candidates = vim.list_extend({}, commands.SUBCOMMANDS)
    local rev_candidates = git.get_rev_candidates(git_root)
    return vim.list_extend(candidates, rev_candidates)
  end,
  desc = "VSCode-style diff view (legacy alias for :CodeDiff)"
})
