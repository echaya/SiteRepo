-- Conflict resolution actions for merge tool
-- Handles accept current/incoming/both/none actions
local M = {}

local lifecycle = require('vscode-diff.render.lifecycle')
local config = require('vscode-diff.config')
local auto_refresh = require('vscode-diff.auto_refresh')

local tracking_ns = vim.api.nvim_create_namespace("vscode-diff-conflict-tracking")
local result_signs_ns = vim.api.nvim_create_namespace("vscode-diff-result-signs")

-- State for dot-repeat
local _pending_action = nil

--- Operatorfunc callback for dot-repeat
--- @param type string Motion type (ignored)
function M.run_repeatable_action(type)
  if _pending_action then
    _pending_action()
  end
end

--- Wrap a function to be dot-repeatable via operatorfunc
--- @param fn function The action to perform
--- @return function The wrapper that sets operatorfunc and returns 'g@l'
local function make_repeatable(fn)
  return function()
    _pending_action = fn
    vim.go.operatorfunc = "v:lua.require'vscode-diff.render.conflict_actions'.run_repeatable_action"
    return "g@l"
  end
end

--- Check if a conflict block is currently active (content matches base)
--- @param session table The diff session
--- @param block table The conflict block
--- @return boolean is_active
local function is_block_active(session, block)
  if not block.extmark_id then return true end  -- Default to active if no tracking
  
  -- 1. Get current content from buffer via Extmark
  local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, { details = true })
  if not mark or #mark == 0 then return true end  -- Default to active if extmark invalid
  if not mark[3] or mark[3].end_row == nil then return true end  -- Default to active if details missing
  
  local start_row = mark[1]
  local end_row = mark[3].end_row
  
  local current_lines = vim.api.nvim_buf_get_lines(session.result_bufnr, start_row, end_row, false)
  
  -- 2. Get expected base content from session
  local base_lines = session.result_base_lines
  if not base_lines then return true end  -- Default to active if no base lines
  
  local expected_lines = {}
  -- base_range is 1-based, inclusive-exclusive logic?
  -- In `apply_to_result`, we used: for i = base_range.start_line, base_range.end_line - 1
  -- Let's match that.
  for i = block.base_range.start_line, block.base_range.end_line - 1 do
    table.insert(expected_lines, base_lines[i] or "")
  end
  
  -- 3. Compare
  if #current_lines ~= #expected_lines then return false end
  
  for i = 1, #current_lines do
    if current_lines[i] ~= expected_lines[i] then
      return false
    end
  end
  
  return true
end

--- Determine which side was accepted for a resolved conflict block
--- @param session table The diff session
--- @param block table The conflict block
--- @return string|nil "incoming", "current", "both", or nil if unresolved/unknown
local function get_accepted_side(session, block)
  if not block.extmark_id then return nil end
  if is_block_active(session, block) then return nil end  -- Still unresolved
  
  -- Get current content from result buffer
  local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, { details = true })
  if not mark or #mark < 3 then return nil end
  
  local start_row = mark[1]
  local end_row = mark[3].end_row
  local current_lines = vim.api.nvim_buf_get_lines(session.result_bufnr, start_row, end_row, false)
  
  -- Get incoming (left) content
  local incoming_lines = {}
  if session.original_bufnr and vim.api.nvim_buf_is_valid(session.original_bufnr) then
    local left_start = block.output1_range.start_line
    local left_end = block.output1_range.end_line
    incoming_lines = vim.api.nvim_buf_get_lines(session.original_bufnr, left_start - 1, left_end - 1, false)
  end
  
  -- Get current (right) content
  local current_side_lines = {}
  if session.modified_bufnr and vim.api.nvim_buf_is_valid(session.modified_bufnr) then
    local right_start = block.output2_range.start_line
    local right_end = block.output2_range.end_line
    current_side_lines = vim.api.nvim_buf_get_lines(session.modified_bufnr, right_start - 1, right_end - 1, false)
  end
  
  -- Helper to compare line arrays
  local function lines_equal(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
      if a[i] ~= b[i] then return false end
    end
    return true
  end
  
  -- Check which side matches
  local matches_incoming = lines_equal(current_lines, incoming_lines)
  local matches_current = lines_equal(current_lines, current_side_lines)
  
  if matches_incoming and matches_current then
    return "both"  -- Both sides are the same (shouldn't happen in conflict, but handle it)
  elseif matches_incoming then
    return "incoming"
  elseif matches_current then
    return "current"
  else
    -- Content doesn't match either side exactly (could be "both" concatenated or manual edit)
    -- Check if it's both sides concatenated
    local both_lines = {}
    for _, line in ipairs(incoming_lines) do
      table.insert(both_lines, line)
    end
    for _, line in ipairs(current_side_lines) do
      table.insert(both_lines, line)
    end
    if lines_equal(current_lines, both_lines) then
      return "both"
    end
    return "edited"  -- Manual edit or unknown
  end
end

--- Find which conflict block the cursor is in
--- @param session table The diff session
--- @param cursor_line number 1-based line number
--- @param side string "left" or "right"
--- @param allow_resolved boolean? If true, return block even if resolved (for discard/reset)
--- @return table|nil The conflict block containing the cursor
local function find_conflict_at_cursor(session, cursor_line, side, allow_resolved)
  local blocks = session.conflict_blocks
  local range_key = side == "left" and "output1_range" or "output2_range"
  
  for _, block in ipairs(blocks) do
    local is_match = false
    
    if allow_resolved then
      -- Just check if extmark exists (valid block tracking)
      if block.extmark_id then
        local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, {})
        if mark and #mark > 0 then
          is_match = true
        end
      end
    else
      -- Check strictly if active (content matches base)
      if is_block_active(session, block) then
        is_match = true
      end
    end

    if is_match then
      local range = block[range_key]
      if range and cursor_line >= range.start_line and cursor_line < range.end_line then
        return block
      end
    end
  end
  return nil
end

--- Find conflict block at cursor position in result buffer (using extmarks)
--- @param session table The diff session
--- @param cursor_line number 1-based line number in result buffer
--- @return table|nil The conflict block containing the cursor
local function find_conflict_at_cursor_in_result(session, cursor_line)
  local blocks = session.conflict_blocks
  if not blocks then return nil end
  
  for _, block in ipairs(blocks) do
    if block.extmark_id then
      local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, { details = true })
      if mark and #mark > 0 then
        local start_row = mark[1] + 1  -- Convert to 1-based
        local end_row = mark[3] and mark[3].end_row and (mark[3].end_row + 1) or start_row
        
        -- Check if cursor is within this block's range in result buffer
        if cursor_line >= start_row and cursor_line <= end_row then
          -- Also check if block is still active (not resolved)
          if is_block_active(session, block) then
            return block
          end
        end
      end
    end
  end
  return nil
end

--- Get lines from a buffer for a given range
--- @param bufnr number Buffer number
--- @param start_line number 1-based start line (inclusive)
--- @param end_line number 1-based end line (exclusive)
--- @return table Lines
local function get_lines_for_range(bufnr, start_line, end_line)
  if start_line >= end_line then
    return {}
  end
  return vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line - 1, false)
end

--- Initialize extmark tracking for conflict blocks in the result buffer
--- @param result_bufnr number Result buffer handle
--- @param conflict_blocks table List of conflict blocks
function M.initialize_tracking(result_bufnr, conflict_blocks)
  if not result_bufnr or not vim.api.nvim_buf_is_valid(result_bufnr) then return end
  
  -- Clear existing extmarks in our namespace
  vim.api.nvim_buf_clear_namespace(result_bufnr, tracking_ns, 0, -1)
  
  for _, block in ipairs(conflict_blocks) do
    local start_line = block.base_range.start_line - 1
    local end_line = block.base_range.end_line - 1
    
    -- Create extmark with gravity: right (adjusts as text is inserted before it)
    -- We want to track the *range* of this block.
    -- Since we replace the whole block content, tracking the start point is most critical.
    -- We use end_right_gravity=false so that if we insert *at* the end, it doesn't expand (though we replace usually).
    local id = vim.api.nvim_buf_set_extmark(result_bufnr, tracking_ns, start_line, 0, {
      end_row = end_line,
      end_col = 0,
      right_gravity = false,
      end_right_gravity = true
    })
    
    block.extmark_id = id
  end
end

--- Refresh all conflict signs based on current state (event-driven approach)
--- Called on TextChanged to keep signs in sync with actual buffer content
--- Also used for initial sign setup after initialize_tracking
--- @param session table The diff session
function M.refresh_all_conflict_signs(session)
  if not session or not session.conflict_blocks then return end
  
  local highlights = require('vscode-diff.render.highlights')
  local ns_conflict = highlights.ns_conflict
  
  -- Check if extmarks need re-initialization (e.g., after undo to original state)
  -- If any extmark is missing or invalid, re-initialize all tracking
  local needs_reinit = false
  for _, block in ipairs(session.conflict_blocks) do
    if not block.extmark_id then
      needs_reinit = true
      break
    end
    local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, { details = true })
    if not mark or #mark < 3 or not mark[3] then
      needs_reinit = true
      break
    end
    -- Check if extmark position is reasonable (not spanning entire buffer or starting at 0 when it shouldn't)
    local mark_start = mark[1]
    local mark_end = mark[3].end_row
    local expected_start = block.base_range.start_line - 1
    -- If extmark start moved to 0 but expected start is not 0, it's corrupted (common after undo/redo)
    if mark_start == 0 and expected_start > 0 then
      needs_reinit = true
      break
    end
  end
  
  if needs_reinit and session.result_bufnr and vim.api.nvim_buf_is_valid(session.result_bufnr) then
    M.initialize_tracking(session.result_bufnr, session.conflict_blocks)
  end
  
  -- Helper to set signs for a buffer range (for non-empty ranges)
  local function set_signs_for_range(bufnr, start_line, end_line, namespace, hl_group, is_active)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
    
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    
    if start_line == end_line then
      -- Empty range: show a top-aligned horizontal bar sign to indicate "something goes here"
      if start_line >= 0 and start_line < line_count then
        local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, {start_line, 0}, {start_line, -1}, {})
        for _, mark in ipairs(marks) do
          vim.api.nvim_buf_del_extmark(bufnr, namespace, mark[1])
        end
        vim.api.nvim_buf_set_extmark(bufnr, namespace, start_line, 0, {
          sign_text = "▔▔",  -- Upper block - appears at top of line, like between two lines
          sign_hl_group = hl_group,
          priority = 50,
        })
      end
    else
      for line = start_line, end_line - 1 do
        if line >= 0 and line < line_count then
          local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, {line, 0}, {line, -1}, {})
          for _, mark in ipairs(marks) do
            vim.api.nvim_buf_del_extmark(bufnr, namespace, mark[1])
          end
          vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
            sign_text = "▌",
            sign_hl_group = hl_group,
            priority = 50,
          })
        end
      end
    end
  end
  
  -- Clear result buffer signs (they move with content, so clear and re-add)
  if session.result_bufnr and vim.api.nvim_buf_is_valid(session.result_bufnr) then
    vim.api.nvim_buf_clear_namespace(session.result_bufnr, result_signs_ns, 0, -1)
  end
  
  -- Update signs for each block based on is_block_active state
  for _, block in ipairs(session.conflict_blocks) do
    local is_active = is_block_active(session, block)
    
    -- Determine highlight groups for left/right/result based on accepted side
    local left_hl, right_hl, result_hl
    if is_active then
      -- Unresolved: all orange
      left_hl = "CodeDiffConflictSign"
      right_hl = "CodeDiffConflictSign"
      result_hl = "CodeDiffConflictSign"
    else
      -- Resolved: check which side was accepted
      local accepted = get_accepted_side(session, block)
      if accepted == "incoming" then
        left_hl = "CodeDiffConflictSignAccepted"   -- Green (chosen)
        right_hl = "CodeDiffConflictSignRejected"  -- Red (not chosen)
      elseif accepted == "current" then
        left_hl = "CodeDiffConflictSignRejected"   -- Red (not chosen)
        right_hl = "CodeDiffConflictSignAccepted"  -- Green (chosen)
      elseif accepted == "both" then
        left_hl = "CodeDiffConflictSignAccepted"   -- Green (both chosen)
        right_hl = "CodeDiffConflictSignAccepted"  -- Green (both chosen)
      else
        -- Manual edit or unknown - use gray
        left_hl = "CodeDiffConflictSignResolved"
        right_hl = "CodeDiffConflictSignResolved"
      end
      -- Result buffer always uses gray for resolved
      result_hl = "CodeDiffConflictSignResolved"
    end
    
    -- Update left buffer (incoming)
    local left_start = block.output1_range.start_line - 1
    local left_end = block.output1_range.end_line - 1
    set_signs_for_range(session.original_bufnr, left_start, left_end, ns_conflict, left_hl, is_active)
    
    -- Update right buffer (current)
    local right_start = block.output2_range.start_line - 1
    local right_end = block.output2_range.end_line - 1
    set_signs_for_range(session.modified_bufnr, right_start, right_end, ns_conflict, right_hl, is_active)
    
    -- Update result buffer (use tracked extmark position)
    if session.result_bufnr and vim.api.nvim_buf_is_valid(session.result_bufnr) and block.extmark_id then
      local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, { details = true })
      if mark and #mark >= 3 then
        local result_start = mark[1]
        local result_end = mark[3].end_row
        local line_count = vim.api.nvim_buf_line_count(session.result_bufnr)
        
        if result_start == result_end then
          -- Empty conflict region: show a top-aligned horizontal bar sign
          if result_start >= 0 and result_start < line_count then
            vim.api.nvim_buf_set_extmark(session.result_bufnr, result_signs_ns, result_start, 0, {
              sign_text = "▔▔",  -- Upper block - appears at top of line, like between two lines
              sign_hl_group = result_hl,
              priority = 50,
            })
          end
        else
          for line = result_start, result_end - 1 do
            if line >= 0 and line < line_count then
              vim.api.nvim_buf_set_extmark(session.result_bufnr, result_signs_ns, line, 0, {
                sign_text = "▌",
                sign_hl_group = result_hl,
                priority = 50,
              })
            end
          end
        end
      end
    end
  end
end

--- Setup autocmd to refresh signs when result buffer changes
--- @param tabpage number The tabpage ID
--- @param result_bufnr number The result buffer handle
function M.setup_sign_refresh_autocmd(tabpage, result_bufnr)
  if not result_bufnr or not vim.api.nvim_buf_is_valid(result_bufnr) then return end
  
  local group = vim.api.nvim_create_augroup("VscodeDiffConflictSigns_" .. tabpage, { clear = true })
  
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    group = group,
    buffer = result_bufnr,
    callback = function()
      local session = lifecycle.get_session(tabpage)
      if session then
        M.refresh_all_conflict_signs(session)
      end
    end,
  })
end

--- Apply text to result buffer at the conflict's range
--- @param result_bufnr number Result buffer
--- @param block table Conflict block with base_range and optional extmark_id
--- @param lines table Lines to insert
--- @param base_lines table Original BASE content (for fallback)
local function apply_to_result(result_bufnr, block, lines, base_lines)
  local start_row, end_row
  
  -- Method 1: Try using extmarks (robust against edits)
  if block.extmark_id then
    local mark = vim.api.nvim_buf_get_extmark_by_id(result_bufnr, tracking_ns, block.extmark_id, { details = true })
    if mark and #mark >= 3 then
      start_row = mark[1]
      end_row = mark[3].end_row
    end
  end
  
  -- Method 2: Fallback to content search or original range
  if not start_row then
    local base_range = block.base_range
    -- We need to find where this base_range maps to in the current result buffer
    -- The result buffer starts as BASE, so initially base_range maps 1:1
    -- After edits, we need to track the offset
  
    -- For simplicity, we'll re-apply based on content matching
    -- Find the base content in the result buffer
    local base_content = {}
    for i = base_range.start_line, base_range.end_line - 1 do
      table.insert(base_content, base_lines[i] or "")
    end
  
    local result_lines = vim.api.nvim_buf_get_lines(result_bufnr, 0, -1, false)
  
    -- Search for the base content in result buffer
    -- This is a simple approach; VSCode uses more sophisticated tracking
    local found_start = nil
    for i = 1, #result_lines - #base_content + 1 do
      local match = true
      for j = 1, #base_content do
        if result_lines[i + j - 1] ~= base_content[j] then
          match = false
          break
        end
      end
      if match then
        found_start = i
        break
      end
    end
  
    if found_start then
      start_row = found_start - 1
      end_row = found_start - 1 + #base_content
    else
      -- Fallback: try to find by approximate position
      -- Use base_range directly (works if no prior edits)
      start_row = math.min(base_range.start_line - 1, #result_lines)
      end_row = math.min(base_range.end_line - 1, #result_lines)
    end
  end
  
  if start_row and end_row then
    vim.api.nvim_buf_set_lines(result_bufnr, start_row, end_row, false, lines)
  end
end

--- Accept incoming (left/input1) side for the conflict under cursor
--- @param tabpage number
--- @return boolean success
function M.accept_incoming(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  -- Determine which buffer cursor is in and find the conflict
  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local side = nil

  if current_buf == session.original_bufnr then
    side = "left"
  elseif current_buf == session.modified_bufnr then
    side = "right"
  else
    vim.notify("[vscode-diff] Cursor not in diff buffer", vim.log.levels.WARN)
    return false
  end

  local block = find_conflict_at_cursor(session, cursor_line, side, false)
  if not block then
    vim.notify("[vscode-diff] No active conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get incoming (left) content
  local incoming_lines = get_lines_for_range(session.original_bufnr, block.output1_range.start_line, block.output1_range.end_line)

  -- Apply to result
  local result_bufnr = session.result_bufnr
  local base_lines = session.result_base_lines
  if not result_bufnr or not base_lines then
    vim.notify("[vscode-diff] No result buffer or base lines", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, incoming_lines, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Accept current (right/input2) side for the conflict under cursor
--- @param tabpage number
--- @return boolean success
function M.accept_current(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local side = nil

  if current_buf == session.original_bufnr then
    side = "left"
  elseif current_buf == session.modified_bufnr then
    side = "right"
  else
    vim.notify("[vscode-diff] Cursor not in diff buffer", vim.log.levels.WARN)
    return false
  end

  local block = find_conflict_at_cursor(session, cursor_line, side, false)
  if not block then
    vim.notify("[vscode-diff] No active conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get current (right) content
  local current_lines = get_lines_for_range(session.modified_bufnr, block.output2_range.start_line, block.output2_range.end_line)

  local result_bufnr = session.result_bufnr
  local base_lines = session.result_base_lines
  if not result_bufnr or not base_lines then
    vim.notify("[vscode-diff] No result buffer or base lines", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, current_lines, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Accept both sides (incoming first, then current) for the conflict under cursor
--- @param tabpage number
--- @return boolean success
function M.accept_both(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local side = nil

  if current_buf == session.original_bufnr then
    side = "left"
  elseif current_buf == session.modified_bufnr then
    side = "right"
  else
    vim.notify("[vscode-diff] Cursor not in diff buffer", vim.log.levels.WARN)
    return false
  end

  local block = find_conflict_at_cursor(session, cursor_line, side, false)
  if not block then
    vim.notify("[vscode-diff] No active conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get both contents
  local incoming_lines = get_lines_for_range(session.original_bufnr, block.output1_range.start_line, block.output1_range.end_line)
  local current_lines = get_lines_for_range(session.modified_bufnr, block.output2_range.start_line, block.output2_range.end_line)

  -- Combine: incoming first, then current
  local combined = {}
  for _, line in ipairs(incoming_lines) do
    table.insert(combined, line)
  end
  for _, line in ipairs(current_lines) do
    table.insert(combined, line)
  end

  local result_bufnr = session.result_bufnr
  local base_lines = session.result_base_lines
  if not result_bufnr or not base_lines then
    vim.notify("[vscode-diff] No result buffer or base lines", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, combined, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Discard both sides (reset to base) for the conflict under cursor
--- @param tabpage number
--- @return boolean success
function M.discard(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local side = nil

  if current_buf == session.original_bufnr then
    side = "left"
  elseif current_buf == session.modified_bufnr then
    side = "right"
  else
    vim.notify("[vscode-diff] Cursor not in diff buffer", vim.log.levels.WARN)
    return false
  end

  local block = find_conflict_at_cursor(session, cursor_line, side, true) -- Allow resolved
  if not block then
    vim.notify("[vscode-diff] No conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get base content for this range
  local base_lines = session.result_base_lines
  if not base_lines then
    vim.notify("[vscode-diff] No base lines available", vim.log.levels.ERROR)
    return false
  end

  local base_content = {}
  for i = block.base_range.start_line, block.base_range.end_line - 1 do
    table.insert(base_content, base_lines[i] or "")
  end

  local result_bufnr = session.result_bufnr
  if not result_bufnr then
    vim.notify("[vscode-diff] No result buffer", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, base_content, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Vimdiff-style diffget from incoming (2do): get hunk from incoming/theirs buffer to result
--- Works from result buffer only (like vimdiff's :diffget 2)
--- @param tabpage number
--- @return boolean success
function M.diffget_incoming(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  local current_buf = vim.api.nvim_get_current_buf()

  if current_buf ~= session.result_bufnr then
    vim.notify("[vscode-diff] 2do only works from result buffer", vim.log.levels.INFO)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  -- Find conflict at cursor position in result buffer
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local block = find_conflict_at_cursor_in_result(session, cursor_line)
  if not block then
    vim.notify("[vscode-diff] No active conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get incoming (left) content
  local incoming_lines = get_lines_for_range(session.original_bufnr, block.output1_range.start_line, block.output1_range.end_line)

  -- Apply to result
  local result_bufnr = session.result_bufnr
  local base_lines = session.result_base_lines
  if not result_bufnr or not base_lines then
    vim.notify("[vscode-diff] No result buffer or base lines", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, incoming_lines, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Vimdiff-style diffget from current (3do): get hunk from current/ours buffer to result
--- Works from result buffer only (like vimdiff's :diffget 3)
--- @param tabpage number
--- @return boolean success
function M.diffget_current(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("[vscode-diff] No active session", vim.log.levels.WARN)
    return false
  end

  local current_buf = vim.api.nvim_get_current_buf()

  if current_buf ~= session.result_bufnr then
    vim.notify("[vscode-diff] 3do only works from result buffer", vim.log.levels.INFO)
    return false
  end

  if not session.conflict_blocks or #session.conflict_blocks == 0 then
    vim.notify("[vscode-diff] No conflicts in this session", vim.log.levels.WARN)
    return false
  end

  -- Find conflict at cursor position in result buffer
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local block = find_conflict_at_cursor_in_result(session, cursor_line)
  if not block then
    vim.notify("[vscode-diff] No active conflict at cursor position", vim.log.levels.INFO)
    return false
  end

  -- Get current (right) content
  local current_lines = get_lines_for_range(session.modified_bufnr, block.output2_range.start_line, block.output2_range.end_line)

  -- Apply to result
  local result_bufnr = session.result_bufnr
  local base_lines = session.result_base_lines
  if not result_bufnr or not base_lines then
    vim.notify("[vscode-diff] No result buffer or base lines", vim.log.levels.ERROR)
    return false
  end

  apply_to_result(result_bufnr, block, current_lines, base_lines)
  M.refresh_all_conflict_signs(session)
  auto_refresh.refresh_result_now(result_bufnr)
  return true
end

--- Get the start line of a block in the current buffer
--- @param session table Session object
--- @param block table Conflict block
--- @param bufnr number Current buffer number
--- @return number|nil start_line 1-based
local function get_block_start_line(session, block, bufnr)
  if bufnr == session.result_bufnr then
    -- Result buffer: use extmark
    if block.extmark_id then
      local mark = vim.api.nvim_buf_get_extmark_by_id(session.result_bufnr, tracking_ns, block.extmark_id, {})
      if mark and #mark > 0 then
        return mark[1] + 1 -- Extmarks are 0-based, return 1-based
      end
    end
  elseif bufnr == session.original_bufnr then
    -- Incoming (left): use output1_range
    if block.output1_range then
      return block.output1_range.start_line
    end
  elseif bufnr == session.modified_bufnr then
    -- Current (right): use output2_range
    if block.output2_range then
      return block.output2_range.start_line
    end
  end
  return nil
end

--- Navigate to next conflict
--- @param tabpage number
function M.navigate_next_conflict(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session or not session.conflict_blocks then return end

  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  
  local target_block = nil
  local target_line = nil
  local target_index = 0
  local total_active = 0
  local active_indices = {}

  -- Pre-calculate active conflicts
  for i, block in ipairs(session.conflict_blocks) do
    if is_block_active(session, block) then
      total_active = total_active + 1
      table.insert(active_indices, { block = block, index = i })
    end
  end

  if total_active == 0 then
    vim.notify("No active conflicts", vim.log.levels.INFO)
    return
  end

  -- Find next
  for i, item in ipairs(active_indices) do
    local start = get_block_start_line(session, item.block, current_buf)
    if start and start > cursor_line then
      target_block = item.block
      target_line = start
      target_index = i
      break
    end
  end

  -- Wrap around
  if not target_line then
    local item = active_indices[1]
    local start = get_block_start_line(session, item.block, current_buf)
    if start then
      target_block = item.block
      target_line = start
      target_index = 1
    end
    
    if target_line and target_line < cursor_line then
       -- Wrapped
    else
       -- Should not happen if total_active > 0
       return
    end
  end

  if target_line then
    vim.api.nvim_win_set_cursor(0, {target_line, 0})
    vim.cmd("normal! zz")
    vim.api.nvim_echo({{string.format('Conflict %d of %d', target_index, total_active), 'None'}}, false, {})
  end
end

--- Navigate to previous conflict
--- @param tabpage number
function M.navigate_prev_conflict(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session or not session.conflict_blocks then return end

  local current_buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  
  local target_block = nil
  local target_line = nil
  local target_index = 0
  local total_active = 0
  local active_indices = {}

  -- Pre-calculate active conflicts
  for i, block in ipairs(session.conflict_blocks) do
    if is_block_active(session, block) then
      total_active = total_active + 1
      table.insert(active_indices, { block = block, index = i })
    end
  end

  if total_active == 0 then
    vim.notify("No active conflicts", vim.log.levels.INFO)
    return
  end

  -- Find previous (iterate backwards through active list)
  for i = #active_indices, 1, -1 do
    local item = active_indices[i]
    local start = get_block_start_line(session, item.block, current_buf)
    if start and start < cursor_line then
      target_block = item.block
      target_line = start
      target_index = i
      break
    end
  end

  -- Wrap around
  if not target_line then
    local item = active_indices[#active_indices]
    local start = get_block_start_line(session, item.block, current_buf)
    if start then
      target_block = item.block
      target_line = start
      target_index = #active_indices
    end
    
    if target_line and target_line > cursor_line then
       -- Wrapped
    else
       return
    end
  end

  if target_line then
    vim.api.nvim_win_set_cursor(0, {target_line, 0})
    vim.cmd("normal! zz")
    vim.api.nvim_echo({{string.format('Conflict %d of %d', target_index, total_active), 'None'}}, false, {})
  end
end

--- Setup conflict keymaps for a session
--- @param tabpage number
function M.setup_keymaps(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then return end

  local keymaps = config.options.keymaps.conflict or {}
  local view_keymaps = config.options.keymaps.view or {}

  -- Bind to incoming (left), current (right), AND result buffers
  local buffers = { session.original_bufnr, session.modified_bufnr, session.result_bufnr }

  local base_opts = { noremap = true, silent = true, nowait = true }

  for _, bufnr in ipairs(buffers) do
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      -- Unbind normal mode do/dp from view keymaps (they don't apply in merge conflict mode)
      if view_keymaps.diff_get then
        pcall(vim.keymap.del, "n", view_keymaps.diff_get, { buffer = bufnr })
      end
      if view_keymaps.diff_put then
        pcall(vim.keymap.del, "n", view_keymaps.diff_put, { buffer = bufnr })
      end

      -- Accept incoming
      if keymaps.accept_incoming then
        vim.keymap.set("n", keymaps.accept_incoming, make_repeatable(function()
          M.accept_incoming(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Accept incoming change", expr = true }))
      end

      -- Accept current
      if keymaps.accept_current then
        vim.keymap.set("n", keymaps.accept_current, make_repeatable(function()
          M.accept_current(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Accept current change", expr = true }))
      end

      -- Accept both
      if keymaps.accept_both then
        vim.keymap.set("n", keymaps.accept_both, make_repeatable(function()
          M.accept_both(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Accept both changes", expr = true }))
      end

      -- Discard
      if keymaps.discard then
        vim.keymap.set("n", keymaps.discard, make_repeatable(function()
          M.discard(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Discard changes (keep base)", expr = true }))
      end
      
      -- Navigation
      if keymaps.next_conflict then
        vim.keymap.set("n", keymaps.next_conflict, function()
          M.navigate_next_conflict(tabpage)
        end, vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Next conflict" }))
      end
      
      if keymaps.prev_conflict then
        vim.keymap.set("n", keymaps.prev_conflict, function()
          M.navigate_prev_conflict(tabpage)
        end, vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Previous conflict" }))
      end

      -- Vimdiff-style diffget from incoming (2do) - only on result buffer
      if keymaps.diffget_incoming and bufnr == session.result_bufnr then
        vim.keymap.set("n", keymaps.diffget_incoming, make_repeatable(function()
          M.diffget_incoming(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Get hunk from incoming (2do)", expr = true }))
      end

      -- Vimdiff-style diffget from current (3do) - only on result buffer
      if keymaps.diffget_current and bufnr == session.result_bufnr then
        vim.keymap.set("n", keymaps.diffget_current, make_repeatable(function()
          M.diffget_current(tabpage)
        end), vim.tbl_extend('force', base_opts, { buffer = bufnr, desc = "Get hunk from current (3do)", expr = true }))
      end
    end
  end
end

return M