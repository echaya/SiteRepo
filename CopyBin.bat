@echo
robocopy site-old\.git site\.git /S
cd site
lazygit
exitMMMMM.create_page_from_filename = function(filename, open_cmd)
  -- Get the context from the current buffer's variables.
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local active_wiki_path = vim.b[current_buf_nr].active_wiki_path

  if not active_wiki_path then
    vim.notify(
      "Could not determine active wiki path. Action aborted.",
      vim.log.levels.ERROR,
      { title = "neowiki" }
    )
    return
  end

  local full_path = util.join_path(active_wiki_path, filename)
  local dir_path = vim.fn.fnamemodify(full_path, ":h")

  -- If the new file is an index file, register its directory as a new nested wiki root.
  if vim.fn.fnamemodify(filename, ":t") == config.index_file then
    if config.discover_nested_wiki then
      M.add_wiki_root(dir_path)
    end
  end

  util.ensure_path_exists(dir_path)
  if vim.fn.filereadable(full_path) == 0 then
    local ok, err = pcall(function()
      local file = assert(io.open(full_path, "w"), "Failed to open file for writing.")
      file:close()
    end)
    if not ok then
      vim.notify("Error creating file: " .. err, vim.log.levels.ERROR, { title = "neowiki" })
      return
    end
  end

  add_to_history(full_path)
  -- Use the existing open_file action to handle opening in different ways.
  open_file(full_path, open_cmd)
end.create_page_from_filename = function(filename, open_cmd)
  -- Get the context from the current buffer's variables.
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local active_wiki_path = vim.b[current_buf_nr].active_wiki_path

  if not active_wiki_path then
    vim.notify(
      "Could not determine active wiki path. Action aborted.",
      vim.log.levels.ERROR,
      { title = "neowiki" }
    )
    return
  end

  local full_path = util.join_path(active_wiki_path, filename)
  local dir_path = vim.fn.fnamemodify(full_path, ":h")

  -- If the new file is an index file, register its directory as a new nested wiki root.
  if vim.fn.fnamemodify(filename, ":t") == config.index_file then
    if config.discover_nested_wiki then
      M.add_wiki_root(dir_path)
    end
  end

  util.ensure_path_exists(dir_path)
  if vim.fn.filereadable(full_path) == 0 then
    local ok, err = pcall(function()
      local file = assert(io.open(full_path, "w"), "Failed to open file for writing.")
      file:close()
    end)
    if not ok then
      vim.notify("Error creating file: " .. err, vim.log.levels.ERROR, { title = "neowiki" })
      return
    end
  end

  add_to_history(full_path)
  -- Use the existing open_file action to handle opening in different ways.
  open_file(full_path, open_cmd)
end.create_page_from_filename = function(filename, open_cmd)
  -- Get the context from the current buffer's variables.
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local active_wiki_path = vim.b[current_buf_nr].active_wiki_path

  if not active_wiki_path then
    vim.notify(
      "Could not determine active wiki path. Action aborted.",
      vim.log.levels.ERROR,
      { title = "neowiki" }
    )
    return
  end

  local full_path = util.join_path(active_wiki_path, filename)
  local dir_path = vim.fn.fnamemodify(full_path, ":h")

  -- If the new file is an index file, register its directory as a new nested wiki root.
  if vim.fn.fnamemodify(filename, ":t") == config.index_file then
    if config.discover_nested_wiki then
      M.add_wiki_root(dir_path)
    end
  end

  util.ensure_path_exists(dir_path)
  if vim.fn.filereadable(full_path) == 0 then
    local ok, err = pcall(function()
      local file = assert(io.open(full_path, "w"), "Failed to open file for writing.")
      file:close()
    end)
    if not ok then
      vim.notify("Error creating file: " .. err, vim.log.levels.ERROR, { title = "neowiki" })
      return
    end
  end

  add_to_history(full_path)
  -- Use the existing open_file action to handle opening in different ways.
  open_file(full_path, open_cmd)
end.create_page_from_filename = function(filename, open_cmd)
  -- Get the context from the current buffer's variables.
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local active_wiki_path = vim.b[current_buf_nr].active_wiki_path

  if not active_wiki_path then
    vim.notify(
      "Could not determine active wiki path. Action aborted.",
      vim.log.levels.ERROR,
      { title = "neowiki" }
    )
    return
  end

  local full_path = util.join_path(active_wiki_path, filename)
  local dir_path = vim.fn.fnamemodify(full_path, ":h")

  -- If the new file is an index file, register its directory as a new nested wiki root.
  if vim.fn.fnamemodify(filename, ":t") == config.index_file then
    if config.discover_nested_wiki then
      M.add_wiki_root(dir_path)
    end
  end

  util.ensure_path_exists(dir_path)
  if vim.fn.filereadable(full_path) == 0 then
    local ok, err = pcall(function()
      local file = assert(io.open(full_path, "w"), "Failed to open file for writing.")
      file:close()
    end)
    if not ok then
      vim.notify("Error creating file: " .. err, vim.log.levels.ERROR, { title = "neowiki" })
      return
    end
  end

  add_to_history(full_path)
  -- Use the existing open_file action to handle opening in different ways.
  open_file(full_path, open_cmd)
end.create_page_from_filename = function(filename, open_cmd)
  -- Get the context from the current buffer's variables.
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local active_wiki_path = vim.b[current_buf_nr].active_wiki_path

  if not active_wiki_path then
    vim.notify(
      "Could not determine active wiki path. Action aborted.",
      vim.log.levels.ERROR,
      { title = "neowiki" }
    )
    return
  end

  local full_path = util.join_path(active_wiki_path, filename)
  local dir_path = vim.fn.fnamemodify(full_path, ":h")

  -- If the new file is an index file, register its directory as a new nested wiki root.
  if vim.fn.fnamemodify(filename, ":t") == config.index_file then
    if config.discover_nested_wiki then
      M.add_wiki_root(dir_path)
    end
  end

  util.ensure_path_exists(dir_path)
  if vim.fn.filereadable(full_path) == 0 then
    local ok, err = pcall(function()
      local file = assert(io.open(full_path, "w"), "Failed to open file for writing.")
      file:close()
    end)
    if not ok then
      vim.notify("Error creating file: " .. err, vim.log.levels.ERROR, { title = "neowiki" })
      return
    end
  end

  add_to_history(full_path)
  -- Use the existing open_file action to handle opening in different ways.
  open_file(full_path, open_cmd)
end
