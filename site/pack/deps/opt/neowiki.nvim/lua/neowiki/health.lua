-- lua/neowiki/health.lua
local M = {}

-- Safely try to load the utility module to ensure path resolution matches the plugin core
local has_util, util = pcall(require, "neowiki.util")

local start = vim.health.start
local ok = vim.health.ok
local warn = vim.health.warn
local error = vim.health.error
local info = vim.health.info

--- Checks if a specific executable is available in the system path.
-- @param tool (string) The name of the executable to check (e.g., "rg").
-- @return (boolean) True if the tool is executable, false otherwise.
local function check_external_tool(tool)
  return vim.fn.executable(tool) == 1
end

---
-- Runs the health check for the neowiki plugin.
-- Validates external tools, dependencies, and configuration paths.
-- This function is invoked via `:checkhealth neowiki`.
--
M.check = function()
  start("neowiki: External Tools")

  local tool_status = {
    rg = check_external_tool("rg"),
    fd = check_external_tool("fd"),
    git = check_external_tool("git"),
  }

  if tool_status.rg then
    ok("ripgrep (rg): Installed")
  else
    warn("ripgrep (rg): Not found")
  end

  if tool_status.fd then
    ok("fd: Installed")
  else
    warn("fd: Not found")
  end

  if tool_status.git then
    ok("git: Installed")
  else
    warn("git: Not found")
  end

  if tool_status.rg then
    ok("Active Tool: [rg] (Optimal performance)")
  elseif tool_status.fd then
    ok("Active Tool: [fd] (Good performance)")
    info("'fd' is faster than native search but lacks content-searching optimizations of 'rg'.")
  elseif tool_status.git then
    warn("Active Tool: [git] (Restricted performance)")
    info("Performance relies on git ls-files. Only works inside git repositories.")
  else
    error("Active Tool: [Native Glob] (Slow)")
    info("No external tools found. Large wikis may experience significant lag.")
  end

  start("neowiki: Dependencies")

  local has_ts, _ = pcall(require, "nvim-treesitter")
  if not has_ts then
    warn("nvim-treesitter: Not installed")
    info("Link detection will use Regex fallback (less robust).")
  else
    ok("nvim-treesitter: Installed")
    local parsers = require("nvim-treesitter.parsers")
    local required_parsers = { "markdown", "markdown_inline" }
    for _, parser in ipairs(required_parsers) do
      if parsers.has_parser(parser) then
        ok(string.format(" - Parser '%s': Installed", parser))
      else
        warn(string.format(" - Parser '%s': Missing", parser))
        info(string.format("   Run :TSInstall %s", parser))
      end
    end
  end

  local repeat_loaded = vim.g.loaded_repeat
  local repeat_installed = vim.fn.globpath(vim.o.rtp, "autoload/repeat.vim") ~= ""

  if repeat_loaded then
    ok("vim-repeat: Installed and loaded")
  elseif repeat_installed then
    ok("vim-repeat: Installed")
  else
    warn("vim-repeat: Not found")
    info("GTD task toggling and other actions will NOT be repeatable with '.'.")
    info("Install 'tpope/vim-repeat' to enable this feature.")
  end

  start("neowiki: Configuration")

  if not has_util then
    error("Critical: Could not load 'neowiki.util'. Cannot validate paths.")
    return
  end

  local config_ok, config = pcall(require, "neowiki.config")
  if not config_ok then
    error("Could not load neowiki.config module.")
    return
  end

  local wiki_dirs = config.wiki_dirs

  if not wiki_dirs then
    -- Default path check
    local default_path = vim.fn.expand("~/wiki")
    if vim.fn.isdirectory(default_path) == 1 then
      ok("Using default wiki path: " .. default_path)
    else
      warn("Using default wiki path: " .. default_path .. " (Directory does not exist)")
      info("Run :neowiki or open a file in that path to create it.")
    end
  else
    if wiki_dirs.path and wiki_dirs[1] == nil then
      wiki_dirs = { wiki_dirs }
    end

    if #wiki_dirs == 0 then
      warn("wiki_dirs is empty in configuration.")
    else
      for _, wiki in ipairs(wiki_dirs) do
        local resolved_path = util.resolve_path(wiki.path)

        if resolved_path and vim.fn.isdirectory(resolved_path) == 1 then
          ok(string.format("Wiki '%s' found at: %s", wiki.name or "Unnamed", resolved_path))
        else
          local display_path = resolved_path or wiki.path
          error(string.format("Wiki '%s' path not found: %s", wiki.name or "Unnamed", display_path))
        end
      end
    end
  end
end

return M
