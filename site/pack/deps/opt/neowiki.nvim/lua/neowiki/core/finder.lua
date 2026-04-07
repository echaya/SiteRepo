-- lua/neowiki/core/finder.lua
local util = require("neowiki.util")
local config = require("neowiki.config")
local state = require("neowiki.state")

local M = {}

-- Variable to ensure the fallback notification is only shown once per session.
local native_fallback_notified = false

local tools = {
  rg = { name = "rg" },
}

local rg = util.check_binary_installed(tools.rg)

---
-- Generic file finder that uses fast command-line tool (rg) if available.
-- All returned paths are made absolute.
-- @param search_path (string) The absolute path of the directory to search.
-- @param search_term (string|table) The filename string (for 'name') or table of patterns (for 'ext').
-- @param search_type (string) 'name' to find by exact filename, or 'ext' for extension.
-- @return (table) A list of absolute paths to the found files.
--
local find_files = function(search_path, search_term, search_type)
  local command
  local files
  local glob_pattern

  if rg then
    command = { rg.binary, "--files", "--no-follow", "--crlf" }
    if search_type == "ext" then
      for _, pat in ipairs(search_term) do
        table.insert(command, "--iglob")
        table.insert(command, pat)
      end
    else -- 'name'
      table.insert(command, "--iglob")
      table.insert(command, search_term)
    end
    table.insert(command, search_path)

    files = vim.fn.systemlist(command)
    if vim.v.shell_error == 0 or vim.v.shell_error == 1 then
      -- rg can return relative paths; ensure they are absolute.
      local absolute_files = {}
      for _, file in ipairs(files) do
        table.insert(absolute_files, vim.fn.fnamemodify(file, ":p"))
      end
      -- vim.notify("rg is used")
      return absolute_files
    end
  end
  -- Fallback to native globpath if all CLI tools failed.
  if not native_fallback_notified then
    vim.notify(
      "rg is not available or failed. Falling back to slower native search.",
      vim.log.levels.INFO,
      { title = "neowiki" }
    )
    native_fallback_notified = true
  end

  if search_type == "ext" then
    local results = {}
    for _, pat in ipairs(search_term) do
      glob_pattern = "**/" .. pat
      local matches = vim.fn.globpath(search_path, glob_pattern, false, true)
      vim.list_extend(results, matches)
    end
    return results
  else -- 'name'
    glob_pattern = "**/" .. search_term
    -- globpath returns absolute paths when the base path is absolute.
    return vim.fn.globpath(search_path, glob_pattern, false, true)
  end
end

---
-- Finds all wiki pages within a directory by calling the generic file finder.
-- @param search_path (string) The absolute path of the directory to search.
-- @return (table) A list of absolute paths to the found wiki pages.
--
M.find_wiki_pages = function(search_path)
  -- Delegate to the main file-finding function with 'ext' type and dynamic patterns.
  return find_files(search_path, config.markdown_patterns, "ext")
end

---
-- Finds all directories under a given search_path that contain the specified index_filename.
-- @param search_path (string): The base path to search from.
-- @param index_filename (string): The name of the index file (e.g., "index.md").
-- @return (table): A list of absolute paths to the directories containing the index file.
--
M.find_nested_roots = function(search_path, index_filename)
  local roots = {}
  if not search_path or search_path == "" then
    return roots
  end

  local index_files = find_files(search_path, index_filename, "name")

  for _, file_path in ipairs(index_files) do
    local root_path = vim.fn.fnamemodify(file_path, ":p:h")
    table.insert(roots, root_path)
  end

  return roots
end

---
-- Finds the most specific wiki root that contains the given buffer path.
-- @param buf_path (string) The absolute path of the buffer to check.
-- @return (string|nil, string|nil, string|nil) Returns three paths:
--   - **wiki_root** (string|nil): The primary root for navigation (e.g., for `jump_to_index`). This may point to a parent wiki if the buffer is a nested index.
--   - **active_wiki_path** (string|nil): The most specific wiki root that contains the buffer. This is the directory where new pages from the current buffer would be created.
--   - **ultimate_wiki_root** (string|nil): The top-most parent wiki in a nested structure, used as the search scope for actions like inserting links.
--
M.find_wiki_for_buffer = function(buf_path)
  local current_file_path = vim.fn.fnamemodify(buf_path, ":p")
  local normalized_current_path = util.normalize_path_for_comparison(current_file_path)
  local current_filename = vim.fn.fnamemodify(buf_path, ":t"):lower()

  -- Find all wiki roots that contain the current file.
  local matching_wikis = {}
  for _, wiki_info in ipairs(state.processed_wiki_paths) do
    local dir_to_check = wiki_info.normalized
    if not dir_to_check:find("/$") then
      dir_to_check = dir_to_check .. "/"
    end

    if normalized_current_path:find(dir_to_check, 1, true) == 1 then
      table.insert(matching_wikis, wiki_info)
    end
  end

  if #matching_wikis == 0 then
    return nil, nil, nil -- No matching wiki found
  end

  -- The list is pre-sorted by path length (desc), so the first match is the most specific.
  local most_specific_match = matching_wikis[1]
  local wiki_root
  local active_wiki_path = most_specific_match.resolved
  -- The last match is the shortest path, making it the ultimate parent root.
  local ultimate_wiki_root = matching_wikis[#matching_wikis].resolved

  -- If we are in an index file of a nested wiki, the effective root for jumping
  -- to index should be the parent wiki's root.
  if current_filename == config.index_file:lower() and #matching_wikis >= 2 then
    wiki_root = matching_wikis[2].resolved
  else
    -- Otherwise, the most specific path is the root.
    wiki_root = most_specific_match.resolved
  end

  return wiki_root, active_wiki_path, ultimate_wiki_root
end

---
-- Uses Ripgrep (rg) to find all backlinks to a specific file.
-- It searches for markdown links `[text](target)` and wikilinks `[[target]]`.
-- @param search_path (string) The absolute path of the directory to search within.
-- @param target_filename (string) The filename to search for in links.
-- @return (table|nil) A list of match objects, or nil if rg is not available or finds nothing.
--   Each object contains: { file = absolute_path, lnum = line_number, text = text_of_line }
M.find_backlinks = function(search_path, target_filename)
  if not rg then
    return nil -- Ripgrep is required for this enhanced search.
  end

  local fname_no_ext = vim.fn.fnamemodify(target_filename, ":t:r")
  local fname_pattern = fname_no_ext:gsub("([%(%)%.%+%[%]])", "\\%1"):gsub("/", "[\\/]")

  -- Dynamically build the regex group for all valid extensions
  local valid_exts = {}
  for _, pattern in ipairs(config.markdown_patterns) do
    local ext_part = pattern:match("%*%.(.+)")
    if ext_part then
      table.insert(valid_exts, "\\." .. ext_part)
    end
  end

  local dynamic_ext_pattern = "(?:" .. table.concat(valid_exts, "|") .. ")?"
  local strict_target_content = "(?:[\\w./\\\\]*)" .. fname_pattern .. dynamic_ext_pattern
  local wikilink_format = "\\[\\[%s\\]\\]"
  local mdlink_format = "\\[[^\\]]+\\]\\(%s\\)"
  local wikilink_part = string.format(wikilink_format, strict_target_content)
  local mdlink_part = string.format(mdlink_format, strict_target_content)
  local pattern = wikilink_part .. "|" .. mdlink_part

  local command = {
    rg.binary,
    "--vimgrep",
    "--type",
    "markdown",
    "-e",
    pattern,
    search_path,
  }

  local results = vim.fn.systemlist(command)
  if vim.v.shell_error ~= 0 and vim.v.shell_error ~= 1 then
    return nil -- rg command failed or returned no results.
  end

  local matches = {}
  for _, line in ipairs(results) do
    local file_path, lnum_str, _, line_content = line:match("^(.-):(%d+):(%d+):(.*)$")

    if file_path and lnum_str and line_content then
      -- for debug
      -- vim.notify(file_path .. " " .. lnum_str .. " " .. line_content)
      line_content = line_content:gsub("\r$", "")
      table.insert(matches, {
        file = file_path,
        lnum = tonumber(lnum_str),
        text = line_content,
      })
    end
  end

  return #matches > 0 and matches or nil
end

---
-- Uses native lua to find all backlinks to wiki index file
-- @param search_targets (table) A list of search target files
-- @return (table|nil) A list of match objects, or nil if none is found
--   Each object contains: { file = absolute_path, lnum = line_number, text = text_of_line }
M.find_backlink_fallback = function(search_targets, search_term)
  vim.notify(
    "rg not found. Falling back to search the immediate index file.",
    vim.log.levels.INFO,
    { title = "neowiki" }
  )
  local matches = {}
  for file_path, _ in pairs(search_targets) do
    if vim.fn.filereadable(file_path) == 1 then
      local all_lines = vim.fn.readfile(file_path)
      for i, line in ipairs(all_lines) do
        if line:find(search_term, 1, true) then
          line = line:gsub("\r$", "")
          table.insert(matches, {
            file = file_path,
            lnum = i,
            text = line,
          })
        end
      end
    else
      vim.notify(
        "Could not read " .. file_path .. " for backlink search: " .. file_path,
        vim.log.levels.WARN,
        { title = "neowiki" }
      )
    end
  end
  return #matches > 0 and matches or nil
end

return M
