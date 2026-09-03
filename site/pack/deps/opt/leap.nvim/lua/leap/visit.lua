local api = vim.api

local function visit(kwargs)
   kwargs = kwargs or {}
   local jumper = kwargs.jumper
   local input = kwargs.input
   if input == '' then
      input = nil
   end
   local use_count = kwargs.count ~= false
   local linewise = kwargs.linewise

   local state = {
      args = kwargs,
      -- `jumper` can mess with these below.
      mode = vim.fn.mode(1),
      count = vim.v.count,
      register = vim.v.register
   }

   local src_win = vim.fn.win_getid()
   local saved_view = vim.fn.winsaveview()  -- (1,0)
   -- Set an extmark as an anchor, so that we can execute remote delete
   -- commands in the backward direction, and move together with the text.
   local anch_ns = api.nvim_create_namespace('')
   local anch_id
   if state.mode:match('^[vV\22]') then
      -- In Visual mode, anchor both ends, as we want to reselect the
      -- area on return (so that we can replace the selection with text
      -- yanked/deleted at the destination).
      local start_pos  -- (1,1)
      local end_pos    -- (1,1)
      local _, o_lnum, o_col = unpack(vim.fn.getpos('v'))
      if
         saved_view.lnum < o_lnum
         or (saved_view.lnum == o_lnum and (saved_view.col + 1) < o_col)
      then
         start_pos = { saved_view.lnum, saved_view.col + 1 }
         end_pos = { o_lnum, o_col }
      else
         start_pos = { o_lnum, o_col }
         end_pos = { saved_view.lnum, saved_view.col + 1 }
      end
      local start_lnum, start_col = unpack(start_pos)
      local end_lnum, end_col = unpack(end_pos)
      anch_id = --[[(1,1)->(0,0)]] api.nvim_buf_set_extmark(
         0, anch_ns, start_lnum - 1, start_col - 1, {
            end_row = end_lnum - 1, end_col = end_col - 1,
         }
      )
   else
      anch_id = --[[(1,0)->(0,0)]] api.nvim_buf_set_extmark(
         0, anch_ns, saved_view.lnum - 1, saved_view.col, {}
      )
   end

   local function default_jumper()
      local function handle_visual_autojump()
         -- On autojump, we feed the given input (re-triggering Visual
         -- mode first if needed), and tell `visit()` to skip doing that
         -- again once we're done. In case we would move on to a labeled
         -- target, we go back to Normal mode (effectively removing the
         -- visual selection), and withdraw our previous instruction.
         local au_1, au_2
         au_1 = api.nvim_create_autocmd('User', {
            pattern = 'LeapAutojump',
            once = true,
            callback = function()
               -- Use `feedkeys()` with 'x' everywhere, else
               -- short-circuits `leap()`.
               if state.mode:match('^[vV\22]') then
                  api.nvim_feedkeys(state.mode, 'nx', false)
               end
               if input then
                  api.nvim_feedkeys(input, 'x', false)
               end
               state.visual_autojump = true

               au_2 = api.nvim_create_autocmd('User', {
                  pattern = 'LeapJumpPre',
                  once = true,
                  callback = function()
                     -- Back to Normal mode.
                     api.nvim_feedkeys(vim.keycode('<C-\\><C-N>'), 'nx', false)
                     state.visual_autojump = false
                  end
               })
            end,
         })
         api.nvim_create_autocmd('User', {
            pattern = 'LeapLeave',
            once = true,
            callback = function()
               pcall(api.nvim_del_autocmd, au_1)
               pcall(api.nvim_del_autocmd, au_2)
            end
         })
      end

      -- We are back in Normal mode when this call is executed, so Leap
      -- has no context to decide whether it is OK to autojump.
      local autojump = not state.mode:match('o')

      -- Note: `input` is assumed to be some visual selection command,
      -- else the behavior is undefined.
      if autojump and (input or state.mode:match('[vV\22]')) then
         handle_visual_autojump()
      end
      require('leap').leap {
         windows = require('leap.user').get_focusable_windows(),
         opts = (not autojump) and { safe_labels = '' } or nil,
         linewise = linewise or state.mode:match('V'),
      }
   end

   jumper = (jumper == nil) and default_jumper or jumper  -- false is meaningful

   local function to_normal_mode()
      if state.mode:match('^[vV\22]') then
         -- In Visual mode, yank the selection to the default register
         -- before jumping (like |v_p| does before pasting), making it
         -- easy to exchange regions.
         api.nvim_feedkeys('y', 'n', false)
      else
         -- I'm just cargo-culting this TBH, but the combination of
         -- the two indeed seems necessary for O-p mode.
         api.nvim_feedkeys(vim.keycode('<C-\\><C-N>'), 'nx', false)
         api.nvim_feedkeys(vim.keycode('<esc>'), 'n', false)
      end
   end

   local function back_to_pending_action()
      if state.mode:match('^[vV\22]') then
         api.nvim_feedkeys(state.mode, 'n', false)
      elseif state.mode:match('o') then
         local count = (use_count and state.count > 0) and state.count or ''
         local register = '"' .. state.register
         local op = vim.v.operator
         local force = state.mode:sub(3)
         api.nvim_feedkeys(count .. register .. op .. force, 'n', false)
      end
   end

   local function cursor_moved()
      -- We need to compare with the anchor instead of the saved cursor
      -- position in Visual mode anyway, because we start with a yank.
      local anch = api.nvim_buf_get_extmark_by_id(0, anch_ns, anch_id, {})
      return vim.fn.win_getid() ~= src_win
         or vim.fn.line('.') ~= anch[1] + 1
         or vim.fn.col('.') ~= anch[2] + 1
   end

   local function restore_cursor()
      if vim.fn.win_getid() ~= src_win then
         api.nvim_set_current_win(src_win)
      end
      vim.fn.winrestview(saved_view)
      local anch = api.nvim_buf_get_extmark_by_id(0, anch_ns, anch_id, {
        details = true
      })
      api.nvim_win_set_cursor(0, { anch[1] + 1, anch[2] })  -- (0,0)->(1,0)
      if state.mode:match('^[vV\22]') then
         -- Reselect the original area.
         api.nvim_feedkeys(state.mode, 'nx', false)
         -- (0,0)->(1,0)
         api.nvim_win_set_cursor(0, { anch[3].end_row + 1, anch[3].end_col })
      end
      api.nvim_buf_clear_namespace(0, anch_ns, 0, -1)
   end

   local function register_listeners()
      local action_canceled = false
      local cancel_key_listener = vim.on_key(function(key, _)
         if
            key == vim.keycode('<c-c>') or
            key == vim.keycode('<esc>') and vim.fn.mode(0) ~= 'i'
         then
            action_canceled = true
         end
      end)

      recur_listener = api.nvim_create_autocmd('User', {
         pattern = 'Visit',
         once = true,
         callback = function()
            state.recursed = true
         end,
      })

      -- Wait for going back to Normal, then restore.
      local mode_change_listener
      mode_change_listener = api.nvim_create_autocmd('ModeChanged', {
         pattern = (vim.bo.buftype == 'terminal') and '*:nt' or '*:n',
         callback = vim.schedule_wrap(function(ev)
            local function cleanup()
               pcall(api.nvim_del_autocmd, recur_listener)
               pcall(api.nvim_del_autocmd, mode_change_listener)
               vim.on_key(nil, cancel_key_listener)
            end

            if state.recursed then
               -- Use case of recursing and dropping the parent: start a
               -- "binary" operation (e.g. swap) remotely, that is,
               -- select the source object itself with an atomic command.
               cleanup()
               return
            elseif
               -- Edge case:
               --   1. start remote change op
               --   --- autocommand active now ---
               --   2. execute non-atomic movement, e.g., a `leap()` call
               --   --- false alarm here, would return early ---
               --   [3. insert replacement text]
               -- Solution: Wait until leaving from Insert mode.
               state.mode:match('o') and (vim.v.operator == 'c')
               and not ev.match:match('i:')
            then
               return
            else
               cleanup()
               restore_cursor()
               if not action_canceled then
                  api.nvim_exec_autocmds('User', {
                     pattern = { 'VisitDone', 'RemoteOperationDone' },
                     data = state
                  })
               end
            end
         end)
      })
   end

   local function after_jump()
      if not cursor_moved() then
         -- For cleaning up extmarks, and restoring the visual selection.
         restore_cursor()
         return
      end
      -- Add target postion to jumplist.
      vim.cmd('norm! m`')
      if not state.visual_autojump then
         back_to_pending_action()  -- (feedkeys...)
      -- No 'n' flag, custom mappings should work here.
         if input then api.nvim_feedkeys(input, '', false) end
      end
      -- Wait for `feedkeys`.
      vim.schedule(register_listeners)
   end

   -- Execute "spooky" action: jump - operate - restore.

   api.nvim_exec_autocmds('User', { pattern = 'Visit', modeline = false })
   to_normal_mode()  -- (feedkeys...)
   -- Wait for `feedkeys`.
   vim.schedule(function()
      if jumper == false then
         -- Use case: exchanging nearby regions (Visual mode).
         register_listeners()
      elseif type(jumper) == 'function' then
         jumper()
         -- Wait for `jumper` to finish its business.
         vim.schedule(function() after_jump() end)
      elseif type(jumper) == 'string' then
         -- API note: `jumper` could of course call `feedkeys` itself,
         -- but then we would need an independent parameter that tells
         -- whether to wait for `CmdlineLeave`.
         api.nvim_feedkeys(jumper, 'n', false)
         vim.schedule(function()
            -- Wait for finishing the search command (autocmd), and then
            -- for actually leaving the command line (schedule wrap).
            api.nvim_create_autocmd('CmdlineLeave', {
               once = true,
               callback = vim.schedule_wrap(after_jump)
            })
         end)
      end
   end)
end

return {
   action = visit,
   visit = visit,
}
