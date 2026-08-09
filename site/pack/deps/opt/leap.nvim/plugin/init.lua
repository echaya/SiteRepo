local map = vim.keymap.set

map({ 'n', 'x', 'o' }, '<Plug>(leap-forward)', function()
   require('leap').leap { inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-forward-next-to)', function()
   require('leap').leap { offset = -1, inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward)', function()
   require('leap').leap { backward = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward-next-to)', function()
   require('leap').leap { backward = true, offset = 1 }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap)', function()
   require('leap').leap { windows = { vim.fn.win_getid() }, inclusive = true }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-next-to)', function()
   require('leap').leap { windows = { vim.fn.win_getid() }, inclusive = true, offset = { -1 }, }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-from-window)', function()
   require('leap').leap { windows = require('leap.user').get_enterable_windows() }
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-anywhere)', function()
   require('leap').leap { windows = require('leap.user').get_focusable_windows() }
end)

map({ 'n', 'o' }, '<Plug>(leap-visit)', function()
   local input = vim.fn.mode(true):match('o') and '' or 'v'
   require('leap').visit { input = input }
end)

local function visit_linewise(autotrigger)
   local input = 'V' .. (
      vim.v.count > 1 and (vim.v.count - 1 .. 'j')
      -- Move to trigger the operation.
      or (vim.fn.mode(true):match('o') and (vim.v.count == 1 or autotrigger)) and 'l'
      or ''
   )
   require('leap').visit { input = input, count = false }
end
map({ 'n', 'o' }, '<Plug>(leap-visit-linewise)', function()
   visit_linewise()
end)
map({ 'o' }, '<Plug>(leap-visit-line)', function()
   visit_linewise(true)
end)

local function visit_text_object(prefix)
   local ok, c = pcall(vim.fn.getcharstr)  -- handling <C-c>
   if not ok or (c == vim.keycode('<esc>')) then
      return
   end
   require('leap').visit { input = prefix .. c }
end
map({ 'x', 'o' }, '<Plug>(leap-visit-text-object)', function()
   visit_text_object('a')
end)
map({ 'x', 'o' }, '<Plug>(leap-visit-inner-text-object)', function()
   visit_text_object('i')
end)

map({ 'n', 'o' }, '<Plug>(leap-remote)', '<Plug>(leap-visit)')
map({ 'n', 'o' }, '<Plug>(leap-remote-linewise)', '<Plug>(leap-visit-linewise)')
map({ 'o' }, '<Plug>(leap-remote-line)', '<Plug>(leap-visit-line)')
map({ 'x', 'o' }, '<Plug>(leap-remote-text-object)', '<Plug>(leap-visit-text-object)')
map({ 'x', 'o' }, '<Plug>(leap-remote-inner-text-object)', '<Plug>(leap-visit-inner-text-object)')

map({ 'n', 'x', 'o' }, '<Plug>(leap-till)', '<Plug>(leap-next-to)')
map({ 'n', 'x', 'o' }, '<Plug>(leap-forward-till)', '<Plug>(leap-forward-next-to)')
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward-till)', '<Plug>(leap-backward-next-to)')
