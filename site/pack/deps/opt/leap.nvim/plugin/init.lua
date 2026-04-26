local map = vim.keymap.set

map({ 'n', 'x', 'o' }, '<Plug>(leap-forward)', function()
   require('leap').leap { inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward)', function()
   require('leap').leap { backward = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-forward-till)', function()
   require('leap').leap { offset = -1, inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward-till)', function()
   require('leap').leap { backward = true, offset = 1 }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap)', function()
   require('leap').leap { windows = { vim.api.nvim_get_current_win() }, inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-from-window)', function()
   require('leap').leap { windows = require('leap.user').get_enterable_windows() }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-anywhere)', function()
   require('leap').leap { windows = require('leap.user').get_focusable_windows() }
end)

map({ 'n', 'o' }, '<Plug>(leap-remote)', function()
   local input = vim.fn.mode(true):match('o') and '' or 'v'
   require('leap.remote').action { input = input }
end)
map({ 'n', 'o' }, '<Plug>(leap-remote-linewise)', function()
   local input = 'V' .. (
      vim.v.count > 1 and (vim.v.count - 1 .. 'j')
      -- Move to trigger the operation.
      or vim.v.count == 1 and vim.fn.mode(true):match('o') and 'l'
      or ''
   )
   require('leap.remote').action { input = input, count = false }
end)
