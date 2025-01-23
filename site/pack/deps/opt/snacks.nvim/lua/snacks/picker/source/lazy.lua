local M = {}

---@type snacks.picker.finder
function M.spec(opts, ctx)
  local spec = require("lazy.core.config").spec
  local Util = require("lazy.core.util")
  local paths = {} ---@type string[]
  for _, import in ipairs(spec.modules) do
    Util.lsmod(import, function(modname, modpath)
      paths[#paths + 1] = modpath
    end)
  end
  local names = {} ---@type string[]
  for _, frag in pairs(spec.meta.fragments.fragments) do
    local name = frag.spec[1] or frag.name
    if not vim.tbl_contains(names, name) then
      names[#names + 1] = name
    end
  end
  local matcher = require("snacks.picker.core.matcher").new(ctx.picker.opts.matcher)
  matcher:init(ctx.filter.search)
  local regex = {} ---@type string[]
  for _, name in ipairs(names) do
    local item = { text = name } ---@type snacks.picker.finder.Item
    if matcher:match(item) > 0 then
      table.insert(regex, '"' .. name .. '"')
    end
  end
  ctx.filter.search = "^(?:(?!\\s*--)).*(?:" .. table.concat(regex, "|") .. ")"
  opts = vim.tbl_extend("force", vim.deepcopy(opts), {
    dirs = paths,
    args = { "--pcre2" },
  })
  return require("snacks.picker.source.grep").grep(opts, ctx)
end

return M
