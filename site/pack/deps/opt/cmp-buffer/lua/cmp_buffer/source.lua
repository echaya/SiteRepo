local buffer = require("cmp_buffer.buffer")
local case_lookup = require("cmp_buffer.cases")

---@class cmp_buffer.Options
---@field public keyword_length number
---@field public keyword_pattern string
---@field public get_bufnrs fun(): number[]
---@field public indexing_batch_size number
---@field public indexing_interval number
---@field public max_indexed_line_length number
---@field public cases table
---@field public show_source boolean

---@type cmp_buffer.Options
local defaults = {
  keyword_length = 3,
  keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\%(\h\|[\u00C0-\u00D6]\|[\u00D8-\u00F6]\|[\u00F8-\u02AF]\)\%(\w\|[\u00C0-\u00D6]\|[\u00D8-\u00F6]\|[\u00F8-\u02AF]\)*\%(-\%(\w\|[\u00C0-\u00D6]\|[\u00D8-\u00F6]\|[\u00F8-\u02AF]\)*\)*\)]],
  get_bufnrs = function()
    return { vim.api.nvim_get_current_buf() }
  end,
  indexing_batch_size = 1000,
  indexing_interval = 100,
  max_indexed_line_length = 1024 * 40,
  debounce = 400,
  cases = {},
  show_source = false,
}

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.buffers = {}
  return self
end

-- Code taken from @MariaSolOs in a indent-blankline.nvim PR:
-- https://github.com/lukas-reineke/indent-blankline.nvim/pull/934/files#diff-09ebcaa8c75cd1e92d25640e377ab261cfecaf8351c9689173fd36c2d0c23d94R16
-- According to https://github.com/neovim/neovim/pull/28977 it's ~ 39 000% faster

--- Use the faster validate version if available.
--- NOTE: We disable some Lua diagnostics here since lua_ls isn't smart enough to
--- realize that we're using an overloaded function.
---@param spec table<string, {[1]:any, [2]:function|string, [3]:string|true|nil}>
local validate = function(spec)
  if vim.fn.has("nvim-0.11") == 1 then
    for key, key_spec in pairs(spec) do
      local message = type(key_spec[3]) == "string" and key_spec[3] or nil --[[@as string?]]
      local optional = type(key_spec[3]) == "boolean" and key_spec[3] or nil --[[@as boolean?]]
      ---@diagnostic disable-next-line:param-type-mismatch, redundant-parameter
      vim.validate(key, key_spec[1], key_spec[2], optional, message)
    end
  else
    ---@diagnostic disable-next-line:param-type-mismatch
    vim.validate(spec)
  end
end

---@return cmp_buffer.Options
source._validate_options = function(_, params)
  local opts = vim.tbl_deep_extend("keep", params.option, defaults)
  validate({
    keyword_length = { opts.keyword_length, "number" },
    keyword_pattern = { opts.keyword_pattern, "string" },
    get_bufnrs = { opts.get_bufnrs, "function" },
    indexing_batch_size = { opts.indexing_batch_size, "number" },
    indexing_interval = { opts.indexing_interval, "number" },
    cases = { opts.cases, "table" },
    show_source = { opts.show_source, "boolean" },
  })
  return opts
end

source.get_keyword_pattern = function(self, params)
  local opts = self:_validate_options(params)
  return opts.keyword_pattern
end

source.complete = function(self, params, callback)
  local opts = self:_validate_options(params)

  local processing = false
  local bufs = self:_get_buffers(opts)
  for _, buf in ipairs(bufs) do
    if buf.timer:is_active() then
      processing = true
      break
    end
  end

  vim.defer_fn(function()
    local input = string.sub(params.context.cursor_before_line, params.offset)
    local items = {}
    local words = {}
    for _, buf in ipairs(bufs) do
      for _, word_list in ipairs(buf:get_words()) do
        for word, _ in pairs(word_list) do
          if not words[word] and input ~= word then
            words[word] = true
            table.insert(items, {
              label = word,
              dup = 0,
              labelDetails = opts.show_source and {
                description = buf:description(true),
              },
              detail = opts.show_source and buf:description(),
            })
            if opts.cases ~= {} then
              local slices = get_word_slices(word)

              for _, case in ipairs(opts.cases) do
                local new_word

                if type(case) == "function" then
                  new_word = case(slices)
                else
                  local converter = case_lookup[case]
                  if converter ~= nil then
                    new_word = converter(slices)
                  end
                end

                if type(new_word) == "string" then
                  if not words[new_word] then
                    words[new_word] = true
                    table.insert(items, {
                      label = new_word,
                      dup = 0,
                    })
                  end
                end
              end
            end
          end
        end
      end
    end

    callback({
      items = items,
      isIncomplete = processing,
    })
  end, processing and 100 or 0)
end

---@param opts cmp_buffer.Options
---@return cmp_buffer.Buffer[]
source._get_buffers = function(self, opts)
  local buffers = {}
  for _, bufnr in ipairs(opts.get_bufnrs()) do
    if not self.buffers[bufnr] then
      local new_buf = buffer.new(bufnr, opts)
      new_buf.on_close_cb = function()
        self.buffers[bufnr] = nil
      end
      new_buf:start_indexing_timer()
      new_buf:watch()
      self.buffers[bufnr] = new_buf
    end
    table.insert(buffers, self.buffers[bufnr])
  end

  return buffers
end

source._get_distance_from_entry = function(self, entry)
  local buf = self.buffers[entry.context.bufnr]
  if buf then
    local distances = buf:get_words_distances(entry.context.cursor.line + 1)
    return distances[entry.completion_item.filterText] or distances[entry.completion_item.label]
  end
end

source.compare_locality = function(self, entry1, entry2)
  if entry1.context ~= entry2.context then
    return
  end
  local dist1 = self:_get_distance_from_entry(entry1) or math.huge
  local dist2 = self:_get_distance_from_entry(entry2) or math.huge
  if dist1 ~= dist2 then
    return dist1 < dist2
  end
end

return source
