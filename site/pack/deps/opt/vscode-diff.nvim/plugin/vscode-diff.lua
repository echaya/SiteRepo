-- Plugin entry point - auto-loaded by Neovim
if vim.g.loaded_vscode_diff then
  return
end
vim.g.loaded_vscode_diff = 1

local render = require("vscode-diff.render")
local commands = require("vscode-diff.commands")
local virtual_file = require("vscode-diff.virtual_file")

-- Setup virtual file scheme
virtual_file.setup()

-- Setup highlights
render.setup_highlights()

-- Re-apply highlights on ColorScheme change
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("VscodeDiffHighlights", { clear = true }),
  callback = function()
    render.setup_highlights()
  end,
})

-- Register user command with subcommand completion
local function complete_codediff(arg_lead, cmd_line, cursor_pos)
  local args = vim.split(cmd_line, "%s+", { trimempty = true })
  
  -- If no args or just ":CodeDiff", suggest subcommands and common revisions
  if #args <= 1 then
    return { "file", "install", "HEAD", "HEAD~1", "main", "master" }
  end
  
  -- If first arg is "file", complete with file paths for remaining args
  if args[2] == "file" then
    return vim.fn.getcompletion(arg_lead, "file")
  end
  
  -- Otherwise default file completion
  return vim.fn.getcompletion(arg_lead, "file")
end

vim.api.nvim_create_user_command("CodeDiff", commands.vscode_diff, {
  nargs = "*",
  bang = true,
  complete = complete_codediff,
  desc = "VSCode-style diff view: :CodeDiff [<revision>] | file <revision> | file <file_a> <file_b> | install"
})
