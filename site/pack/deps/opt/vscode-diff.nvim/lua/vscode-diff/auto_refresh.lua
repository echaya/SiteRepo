-- Auto-refresh mechanism for diff views
-- Watches buffer changes (internal and external) and triggers diff recomputation
local M = {}

local diff = require("vscode-diff.diff")
local core = require("vscode-diff.render.core")

-- Throttle delay in milliseconds
local THROTTLE_DELAY_MS = 200

-- Track active auto-refresh sessions
-- Structure: { bufnr = { timer } }
-- Buffer pair info is retrieved from lifecycle
local active_sessions = {}

-- Cancel pending timer for a buffer
local function cancel_timer(bufnr)
  local session = active_sessions[bufnr]
  if session and session.timer then
    vim.fn.timer_stop(session.timer)
    session.timer = nil
  end
end

-- Perform diff computation and update decorations
local function do_diff_update(bufnr)
  local session = active_sessions[bufnr]
  if not session then
    return
  end

  -- Clear timer reference
  session.timer = nil

  -- Validate buffers still exist
  if not vim.api.nvim_buf_is_valid(bufnr) then
    active_sessions[bufnr] = nil
    return
  end
  
  -- Get buffer pair from lifecycle
  local lifecycle = require('vscode-diff.render.lifecycle')
  local tabpage = lifecycle.find_tabpage_by_buffer(bufnr)
  if not tabpage then
    active_sessions[bufnr] = nil
    return
  end
  
  local original_bufnr, modified_bufnr = lifecycle.get_buffers(tabpage)
  if not original_bufnr or not modified_bufnr then
    active_sessions[bufnr] = nil
    return
  end
  
  if not vim.api.nvim_buf_is_valid(original_bufnr) or not vim.api.nvim_buf_is_valid(modified_bufnr) then
    active_sessions[bufnr] = nil
    return
  end

  -- Get fresh buffer content
  local original_lines = vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)
  local modified_lines = vim.api.nvim_buf_get_lines(modified_bufnr, 0, -1, false)

  -- Async diff computation
  vim.schedule(function()
    -- Check if session was cleaned up while scheduled
    if not active_sessions[bufnr] then
      return
    end
    
    -- Double-check buffer validity after schedule
    if not vim.api.nvim_buf_is_valid(original_bufnr) or not vim.api.nvim_buf_is_valid(modified_bufnr) then
      active_sessions[bufnr] = nil
      return
    end

    -- Compute diff
    local config = require("vscode-diff.config")
    local diff_options = {
      max_computation_time_ms = config.options.diff.max_computation_time_ms,
    }
    local lines_diff = diff.compute_diff(original_lines, modified_lines, diff_options)
    if not lines_diff then
      return
    end

    -- Update decorations on both buffers
    core.render_diff(original_bufnr, modified_bufnr, original_lines, modified_lines, lines_diff)
    
    -- Re-sync scrollbind after filler changes
    -- This ensures both windows stay aligned even if fillers were added/removed
    local original_win, modified_win = nil, nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if buf == original_bufnr then
        original_win = win
      elseif buf == modified_bufnr then
        modified_win = win
      end
    end
    
    if original_win and modified_win then
      local current_win = vim.api.nvim_get_current_win()
      
      -- Only resync if user is in one of the diff windows
      if current_win == original_win or current_win == modified_win then
        -- Step 1: Remember cursor position (line AND column) after render
        local saved_cursor = vim.api.nvim_win_get_cursor(current_win)
        
        -- Step 2: Reset both windows to line 1 (baseline)
        vim.api.nvim_win_set_cursor(original_win, {1, 0})
        vim.api.nvim_win_set_cursor(modified_win, {1, 0})
        
        -- Step 3: Re-establish scrollbind (reset sync state)
        vim.wo[original_win].scrollbind = false
        vim.wo[modified_win].scrollbind = false
        vim.wo[original_win].scrollbind = true
        vim.wo[modified_win].scrollbind = true
        
        -- Step 4: Restore cursor position with both line and column
        pcall(vim.api.nvim_win_set_cursor, original_win, saved_cursor)
        pcall(vim.api.nvim_win_set_cursor, modified_win, saved_cursor)
      end
    end
  end)
end

-- Trigger diff update with throttling
local function trigger_diff_update(bufnr)
  local session = active_sessions[bufnr]
  if not session then
    return
  end

  -- Cancel existing timer
  cancel_timer(bufnr)

  -- Start new timer
  session.timer = vim.fn.timer_start(THROTTLE_DELAY_MS, function()
    do_diff_update(bufnr)
  end)
end

-- Setup auto-refresh for a buffer
-- @param bufnr number: Buffer to watch for changes
-- Note: Buffer pair info is retrieved from lifecycle when needed
function M.enable(bufnr)
  -- Store session info (just timer)
  active_sessions[bufnr] = {
    timer = nil,
  }

  -- Setup autocmds for this buffer
  local buf_augroup = vim.api.nvim_create_augroup('vscode_diff_auto_refresh_' .. bufnr, { clear = true })

  -- Internal changes (user editing)
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP' }, {
    group = buf_augroup,
    buffer = bufnr,
    callback = function()
      trigger_diff_update(bufnr)
    end,
  })

  -- External changes (file modified on disk)
  vim.api.nvim_create_autocmd({ 'FileChangedShellPost', 'FocusGained' }, {
    group = buf_augroup,
    buffer = bufnr,
    callback = function()
      trigger_diff_update(bufnr)
    end,
  })

  -- Cleanup on buffer delete/wipe
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = buf_augroup,
    buffer = bufnr,
    callback = function()
      M.disable(bufnr)
    end,
  })
end

-- Disable auto-refresh for a buffer
function M.disable(bufnr)
  cancel_timer(bufnr)
  active_sessions[bufnr] = nil

  -- Clear autocmd group
  pcall(vim.api.nvim_del_augroup_by_name, 'vscode_diff_auto_refresh_' .. bufnr)
end

-- Cleanup all active sessions
function M.cleanup_all()
  for bufnr, _ in pairs(active_sessions) do
    M.disable(bufnr)
  end
end

return M
