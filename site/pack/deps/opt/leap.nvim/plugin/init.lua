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

local function visit(start_visual)
   local input, linewise
   if vim.v.count >= 1 then
      linewise = true
      if vim.v.count == 1 then
         -- (Attempt to) move to trigger the operation.
         input = vim.fn.mode(true):match('o') and 'Vl' or 'V'
      else
         input = (start_visual and 'V' or '') .. ((vim.v.count - 1) .. 'j')
      end
   elseif start_visual then
      input = 'v'
   end
   require('leap').visit { input = input, count = false, linewise = linewise }
end
map({ 'n', 'i' }, '<Plug>(leap-visit)', function() visit(true) end)
map({ 'x', 'o' }, '<Plug>(leap-visit)', function() visit() end)

local function visit_text_object(prefix)
   local ok, c = pcall(vim.fn.getcharstr)  -- handling <C-c>
   if not ok or (c == vim.keycode('<esc>')) then
      return
   end
   local mode = vim.fn.mode(true)
   local input = prefix .. c
   -- MAGIC: Handle single-character charwise Visual selection
   -- specially, like a Normal-mode invocation with `input=v`.
   -- Motivation: Yanking the selection or pasting into it is not
   -- terribly useful in such cases, while Visual mode has the advantage
   -- of a possible autojump.
   if (mode == 'v') and vim.deep_equal(vim.fn.getpos('v'), vim.fn.getpos('.')) then
      vim.api.nvim_feedkeys('v', 'nx', false)  -- back to Normal
      input = 'v' .. input
   end
   require('leap').visit {
      input = input,
      linewise = mode:match('V') or (
         -- `p` forces linewise, while `l` is aboult lines in the first
         -- place (check remappings though).
         (c == 'p' or c == 'l') and (vim.fn.maparg(prefix .. c) == '')
      ),
   }
end
map({ 'x', 'o' }, '<Plug>(leap-visit-text-object)', function()
   visit_text_object('a')
end)
map({ 'x', 'o' }, '<Plug>(leap-visit-inner-text-object)', function()
   visit_text_object('i')
end)

-- Deprecated.
local function visit_linewise(autotrigger)
   local input = (vim.fn.mode(true) == 'V') and '' or 'V'
   if vim.v.count > 1 then
      input = input .. ((vim.v.count - 1) .. 'j')
   elseif ((vim.v.count == 1) or autotrigger) and vim.fn.mode(true):match('o') then
      -- Move to trigger the operation.
      input = input .. 'l'
   end
   require('leap').visit { input = input, count = false, linewise = true }
end
map({ 'n', 'x', 'o' }, '<Plug>(leap-visit-linewise)', function()
   visit_linewise()
end)
map({ 'n', 'x', 'o' }, '<Plug>(leap-visit-line)', function()
   visit_linewise(true)
end)

map({ 'n', 'o' }, '<Plug>(leap-remote)', '<Plug>(leap-visit)')
map({ 'n', 'o' }, '<Plug>(leap-remote-linewise)', '<Plug>(leap-visit-linewise)')
map({ 'o' }, '<Plug>(leap-remote-line)', '<Plug>(leap-visit-line)')
map({ 'x', 'o' }, '<Plug>(leap-remote-text-object)', '<Plug>(leap-visit-text-object)')
map({ 'x', 'o' }, '<Plug>(leap-remote-inner-text-object)', '<Plug>(leap-visit-inner-text-object)')

map({ 'n', 'x', 'o' }, '<Plug>(leap-till)', '<Plug>(leap-next-to)')
map({ 'n', 'x', 'o' }, '<Plug>(leap-forward-till)', '<Plug>(leap-forward-next-to)')
map({ 'n', 'x', 'o' }, '<Plug>(leap-backward-till)', '<Plug>(leap-backward-next-to)')
