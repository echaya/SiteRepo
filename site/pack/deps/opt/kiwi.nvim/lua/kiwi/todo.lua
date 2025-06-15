local todo = {}

---
-- Retrieves the indentation level of a task on a given line.
-- @param line (string): The line content to inspect.
-- @return (number|nil): The indentation level, or nil if not a recognized task.
local function get_bound(line)
	if not line then
		return nil
	end

	-- Check for unordered list tasks, e.g., "* [ ] task" or "- [ ] task"
	local indent_str = line:match("^(%s*)[%*%-+]%s*%[.%]%s")
	if indent_str then
		return #indent_str
	end

	-- Check for ordered list tasks, e.g., "1. [ ] task" or "10) [ ] task"
	indent_str = line:match("^(%s*)%d+[.%)%)]%s*%[.%]%s")
	if indent_str then
		return #indent_str
	end

	return nil
end

---
-- If a line is a markdown list item, finds the column where the text content begins.
-- @param line (string): The line content to inspect.
-- @return (number|nil): The 1-based column number for insertion, or nil if not a list item.
local function get_list_marker_info(line)
	if not line then
		return nil
	end

	-- Regex for unordered lists
	local _, match_end = line:find("^%s*[%*%-+]%s+")
	if match_end then
		return match_end + 1
	end

	-- Regex for ordered lists
	_, match_end = line:find("^%s*%d+[.%)%)]%s+")
	if match_end then
		return match_end + 1
	end

	return nil
end

---
-- Checks if a task is marked as done.
-- @param line (string): The line content.
-- @return (boolean|nil): True if done, false if not, nil if indeterminate.
local function is_marked_done(line)
	local state = line:match("%[(.)%]")
	if state == "x" then
		return true
	elseif state == " " then
		return false
	end
	return nil
end

---
-- Marks a task as done or undone in the provided lines table.
-- @param lines (table): The table of buffer lines.
-- @param line_nr (number): The 1-based line number to modify.
-- @param should_be_done (boolean): The new state to apply.
local function set_task_state(lines, line_nr, should_be_done)
	local line = lines[line_nr]
	if not line or get_bound(line) == nil then
		return
	end

	local currently_done = is_marked_done(line)
	if currently_done == should_be_done then
		return -- Already in the desired state.
	end

	if should_be_done then
		lines[line_nr] = line:gsub("%[ %]", "[x]", 1)
	else
		lines[line_nr] = line:gsub("%[x%]", "[ ]", 1)
	end
end

---
-- Toggles the state of all descendant tasks in the lines table.
-- @param lines (table): The table of buffer lines.
-- @param line_number (number): The 1-based line number of the parent task.
-- @param bound (number): The indentation level of the parent task.
-- @param state (boolean): The new state to apply (true for done, false for undone).
local function toggle_children(lines, line_number, bound, state)
	for ln = line_number + 1, #lines do
		local line = lines[ln]
		local new_bound = get_bound(line)

		if new_bound then
			if new_bound > bound then
				set_task_state(lines, ln, state)
			else
				break -- Exited the child block.
			end
		end
	end
end

---
-- Finds the line number of the parent task.
-- @param lines (table): The table of buffer lines.
-- @param cursor (number): The 1-based line number of the child task.
-- @param bound (number): The indentation level of the child task.
-- @return (number|nil): The line number of the parent task or nil.
local function find_parent(lines, cursor, bound)
	for ln = cursor - 1, 1, -1 do
		local line = lines[ln]
		local new_bound = get_bound(line)
		if new_bound and new_bound < bound then
			return ln
		end
	end
	return nil
end

---
-- Checks if all immediate children of a task are complete.
-- @param lines (table): The table of buffer lines.
-- @param cursor (number): The 1-based line number of the parent task.
-- @param bound (number): The indentation level of the parent task.
-- @return (boolean): True if all children are complete, otherwise false.
local function is_children_complete(lines, cursor, bound)
	local child_bound = nil
	local found_a_child = false
	local all_done = true

	for ln = cursor + 1, #lines do
		local line = lines[ln]
		local new_bound = get_bound(line)

		if new_bound then
			if new_bound <= bound then
				break -- Exited the child block.
			end

			if not child_bound then
				child_bound = new_bound
			end

			if new_bound == child_bound then
				found_a_child = true
				if not is_marked_done(line) then
					all_done = false
					-- No need to check further, we found an undone child.
				end
			end
		end
	end
	return not found_a_child or all_done
end

---
-- Updates the status of all ancestor tasks based on their children.
-- @param lines (table): The table of buffer lines.
-- @param cursor (number): The 1-based line number of the task that was changed.
-- @param bound (number): The indentation level of the task that was changed.
local function validate_parent_tasks(lines, cursor, bound)
	local current_ln = cursor
	local current_bound = bound

	while true do
		local parent_ln = find_parent(lines, current_ln, current_bound)
		if not parent_ln then
			break
		end

		local parent_line = lines[parent_ln]
		local parent_bound = get_bound(parent_line)

		if is_children_complete(lines, parent_ln, parent_bound) then
			set_task_state(lines, parent_ln, true)
		else
			set_task_state(lines, parent_ln, false)
		end

		current_ln = parent_ln
		current_bound = parent_bound
	end
end

---
-- Main function to toggle a task's state or create a new task from a list item.
todo.toggle = function()
	--- Read all lines from the current buffer into a table. This is the core performance improvement.
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local original_cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_ln = original_cursor[1]
	local line = lines[cursor_ln]

	local bound = get_bound(line)

	if bound == nil then
		local text_start_col = get_list_marker_info(line)
		if text_start_col then
			local prefix = line:sub(1, text_start_col - 1)
			local suffix = line:sub(text_start_col)
			local new_line = prefix .. "[ ] " .. suffix
			lines[cursor_ln] = new_line -- Modify the in-memory table.

			local new_bound = get_bound(new_line)
			if new_bound then
				validate_parent_tasks(lines, cursor_ln, new_bound)
			end
			--- Write the modified lines back to the buffer in a single API call.
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
			return
		end
		vim.notify("Not a valid todo task or list item.", vim.log.levels.WARN)
		return
	end

	local currently_done = is_marked_done(line)
	if currently_done == nil then
		vim.notify("Could not determine task state.", vim.log.levels.WARN)
		return
	end
	local new_state_is_done = not currently_done

	set_task_state(lines, cursor_ln, new_state_is_done)
	toggle_children(lines, cursor_ln, bound, new_state_is_done)
	validate_parent_tasks(lines, cursor_ln, bound)

	--- Write all accumulated changes back to the buffer at once.
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, original_cursor)
end

return todo
