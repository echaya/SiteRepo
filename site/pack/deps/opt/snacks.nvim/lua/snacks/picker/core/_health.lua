local M = {}

---@private
function M.health()
  local config = Snacks.picker.config.get()
  if Snacks.config.get("picker", {}).enabled and config.ui_select then
    if vim.ui.select == Snacks.picker.select then
      Snacks.health.ok("`vim.ui.select` is set to `Snacks.picker.select`")
    else
      Snacks.health.error("`vim.ui.select` is not set to `Snacks.picker.select`")
    end
  else
    Snacks.health.warn("`vim.ui.select` for `Snacks.picker` is not enabled")
  end

  Snacks.health.has_lang("regex")

  Snacks.health.have_tool("git")
  local have_rg = Snacks.health.have_tool("rg")
  local have_fd = Snacks.health.have_tool({
    { cmd = { "fd", "fdfind" }, version = "v8.4" },
    { cmd = "find", enabled = jit.os:find("Windows") == nil },
  })

  if not have_rg then
    Snacks.health.warn("'rg' is required for `Snacks.picker.grep()`")
  end
  if not have_rg and not have_fd then
    Snacks.health.warn("'rg' or 'fd' is required for `Snacks.picker.files()`")
  end
  if not have_fd then
    Snacks.health.warn("'fd' is required for `Snacks.picker.explorer()`")
  end
end

return M
