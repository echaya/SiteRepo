local cmp = require 'cmp'
local IS_WIN = vim.uv.os_uname().sysname == 'Windows_NT'
local NAME_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\|]\\)'
local PATH_REGEX
local PATH_SEPARATOR

if IS_WIN then
  PATH_REGEX = assert(vim.regex(([[\%(\%([/\\]PAT*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*[/\\]\zePAT*$]]):gsub('PAT',
    NAME_REGEX)))
  PATH_SEPARATOR = '[/\\]'
else
  PATH_REGEX = assert(vim.regex(([[\%(\%(/PAT*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*/\zePAT*$]]):gsub('PAT',
    NAME_REGEX)))
  PATH_SEPARATOR = '/'
end

local source = {}

local constants = {max_lines = 20}

---@class cmp_path.Option
---@field public trailing_slash boolean
---@field public label_trailing_slash boolean
---@field public get_cwd fun(table): string
---@field public show_hidden_files_by_default boolean

---@type cmp_path.Option
local defaults = {
  trailing_slash = false,
  label_trailing_slash = true,
  get_cwd = function(params)
    return vim.fn.expand(('#%d:p:h'):format(params.context.bufnr))
  end,
  show_hidden_files_by_default = false,
}

source.new = function() return setmetatable({}, {__index = source}) end

source.get_trigger_characters = function()
  if IS_WIN then
    return {'/', '.', '\\'}
  else
    return {'/', '.'}
  end
end

source.get_keyword_pattern = function(_, _) return NAME_REGEX .. '*' end

---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
  local option = self:_validate_option(params)

  local dirname = self:_dirname(params, option)
  if not dirname then
    return callback()
  end

  local include_hidden = option.show_hidden_files_by_default or
    string.sub(params.context.cursor_before_line, params.offset, params.offset) == '.'
  self:_candidates(dirname, include_hidden, option,
    ---@param err nil|string
    ---@param candidates lsp.CompletionResponse|nil
    function(err, candidates)
      if err then
        return callback()
      end
      callback(candidates)
    end)
end

--- get documentation in separate thread
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
  local data = completion_item.data
  ---@diagnostic disable-next-line: undefined-field
  if not data.stat or data.stat.type ~= 'file' then
    -- return right away with no changes / no added docs
    callback(completion_item)
    return
  end

  local work
  work = assert(vim.uv.new_work(
  --- Read file in thread
  ---@param filepath string
  ---@param count number max line count (-1 if no max)
  ---@return string|nil, string (error, serialized_table) either some error or the serialized table
    function(filepath, count)
      local ok, binary = pcall(io.open, filepath, 'rb')
      if not ok or binary == nil then
        ---@diagnostic disable-next-line: redundant-return-value
        return nil, vim.json.encode({
          kind = "binary",
          contents = "« cannot read this file »"
        })
      end
      local first_kb = binary:read(1024)
      if first_kb == nil or first_kb == "" then
        ---@diagnostic disable-next-line: redundant-return-value
        return nil, vim.json.encode({kind = 'binary', contents = '« empty file »'})
      end

      if first_kb:find('\0') then
        ---@diagnostic disable-next-line: redundant-return-value
        return nil, vim.json.encode({kind = "binary", contents = 'binary file'})
      end

      local contents = {}
      for content in first_kb:gmatch("[^\r\n]+") do
        table.insert(contents, content)
        if count > -1 and #contents >= count then
          break
        end
      end
      ---@diagnostic disable-next-line: redundant-return-value
      return nil, vim.json.encode({contents = contents})
    end,
    --- deserialize doc and call callback(…)
    ---@param serialized_fileinfo string
    function(worker_error, serialized_fileinfo)
      if worker_error then
        error(string.format("Worker error while fetching file doc: %s", worker_error))
      end

      local read_ok, file_info = pcall(vim.json.decode, serialized_fileinfo, {luanil = {object = true, array = true}})
      if not read_ok then
        error(string.format("Unexpected problem de-serializing item info: «%s»",
          serialized_fileinfo))
      end
      if file_info.kind == "binary" then
        completion_item.documentation = {
          kind = cmp.lsp.MarkupKind.PlainText,
          value = file_info.contents,
        }
      else
        local contents = file_info.contents
        local filetype = vim.filetype.match({contents = contents})
        if not filetype then
          completion_item.documentation = {
            kind = cmp.lsp.MarkupKind.PlainText,
            value = table.concat(contents, '\n'),
          }
        else
          table.insert(contents, 1, '```' .. filetype)
          table.insert(contents, '```')
          completion_item.documentation = {
            kind = cmp.lsp.MarkupKind.Markdown,
            value = table.concat(contents, '\n'),
          }
        end
      end

      callback(completion_item)
    end
  ))
  work:queue(data.path, constants.max_lines or -1, cmp.lsp.MarkupKind.Markdown)
end

--- Try to match a path before cursor and return its dirname
--- Try to work around non-literal paths, like resolving env vars
---@param params cmp.SourceCompletionApiParams
---@param option cmp_path.Option
function source:_dirname(params, option)
  local s = PATH_REGEX:match_str(params.context.cursor_before_line)
  if not s then
    return nil
  end

  local dirname = string.gsub(string.sub(params.context.cursor_before_line,
    s + 2), '%a*$', '')                                                  -- exclude '/'
  local prefix = string.sub(params.context.cursor_before_line, 1, s + 1) -- include '/'

  local buf_dirname = option.get_cwd(params)
  if vim.api.nvim_get_mode().mode == 'c' then
    buf_dirname = vim.fn.getcwd()
  end
  if prefix:match('%.%.' .. PATH_SEPARATOR .. '$') then
    return vim.fn.resolve(buf_dirname .. '/../' .. dirname)
  end
  if (prefix:match('%.' .. PATH_SEPARATOR .. '$') or prefix:match('"$') or prefix:match('\'$')) then
    return vim.fn.resolve(buf_dirname .. '/' .. dirname)
  end
  if prefix:match('~' .. PATH_SEPARATOR .. '$') then
    return vim.fn.resolve(vim.fn.expand('~') .. '/' .. dirname)
  end
  local env_var_name = prefix:match('%$([%a_]+)' .. PATH_SEPARATOR .. '$')
  if env_var_name then
    local env_var_value = vim.fn.getenv(env_var_name)
    if env_var_value ~= vim.NIL then
      return vim.fn.resolve(env_var_value .. '/' .. dirname)
    end
  end
  if IS_WIN then
    local driver = prefix:match('(%a:)[/\\]$')
    if driver then
      return vim.fn.resolve(driver .. '/' .. dirname)
    end
  end
  if prefix:match('/$') then
    local accept = true
    -- Ignore URL components
    accept = accept and not prefix:match('%a/$')
    -- Ignore URL scheme
    accept = accept and not prefix:match('%a+:/$') and
      not prefix:match('%a+://$')
    -- Ignore HTML closing tags
    accept = accept and not prefix:match('</$')
    -- Ignore math calculation
    accept = accept and not prefix:match('[%d%)]%s*/$')
    -- Ignore / comment
    accept = accept and
      (not prefix:match('^[%s/]*$') or not self:_is_slash_comment_p())
    if accept then
      return vim.fn.resolve('/' .. dirname)
    end
  end
  return nil
end

--- call cmp's callback(entries) after retrieving entries in a separate thread
---@param dirname string
---@param include_hidden boolean
---@param option cmp_path.Option
---@param callback function(err:nil|string, candidates:lsp.CompletionResponse|nil)
function source:_candidates(dirname, include_hidden, option, callback)
  local entries, err = vim.uv.fs_scandir(dirname)
  if err then
    return callback(err, nil)
  end

  local work
  work = assert(vim.uv.new_work(
  --- Collect path entries, serialize them and return them
  --- This function is called in a separate thread, so errors are caught and serialized
  ---@param _entries uv_fs_t
  ---@param _dirname string see vim.fn.resolve()
  ---@param _include_hidden boolean
  ---@param label_trailing_slash boolean
  ---@param trailing_slash boolean
  ---@param file_kind table<string,number> see cmp.lsp.CompletionItemKind.Filee
  ---@param folder_kind table<string,number> see cmp.lsp.CompletionItemKind.Folder
  ---@return string|nil, string (error, serialized_results) "error text", nil or nil, "serialized items"
    function(_entries, _dirname, _include_hidden,
             label_trailing_slash, trailing_slash,
             file_kind, folder_kind)
      local items = {}

      local function create_item(name, fs_type)
        if not (_include_hidden or string.sub(name, 1, 1) ~= '.') then
          return
        end

        local path = _dirname .. '/' .. name
        local stat = assert(vim.uv.fs_stat)(path)
        local lstat = nil
        if stat then
          fs_type = stat.type
        elseif fs_type == 'link' then
          -- Broken symlink
          lstat = assert(vim.uv.fs_lstat)(_dirname)
          if not lstat then
            return
          end
        else
          return
        end

        local item = {
          label = name,
          filterText = name,
          insertText = name,
          kind = file_kind,
          data = {path = path, type = fs_type, stat = stat, lstat = lstat},
        }
        if fs_type == 'directory' then
          item.kind = folder_kind
          if label_trailing_slash then
            item.label = name .. '/'
          else
            item.label = name
          end
          item.insertText = name .. '/'
          if not trailing_slash then
            item.word = name
          end
        end

        table.insert(items, item)
      end

      while true do
        local name, fs_type, e = assert(vim.uv.fs_scandir_next)(_entries)
        if e then
          ---@diagnostic disable-next-line: redundant-return-value
          return fs_type, ""
        end
        if not name then
          break
        end
        create_item(name, fs_type)
      end

      ---@diagnostic disable-next-line: redundant-return-value
      return nil, vim.json.encode(items)
    end,
    --- Receive serialiazed entries, deserialize them, call callback(entries)
    --- This function is called in the main thread
    ---@param worker_error string|nil non-nil if some error happened in worker thread
    ---@param serialized_items string array-of-items serialized as string
    function(worker_error, serialized_items)
      if worker_error then
        callback(err, nil)
        return
      end
      local read_ok, items = pcall(vim.json.decode, serialized_items, {luanil = {object = true, array = true}})
      if not read_ok then
        callback("Problem de-serializing file entries", nil)
      end
      callback(nil, items)
    end))

  work:queue(entries, dirname, include_hidden, option.label_trailing_slash,
    option.trailing_slash, cmp.lsp.CompletionItemKind.File,
    cmp.lsp.CompletionItemKind.Folder)
end

--- using «/» as comment in current buffer?
function source:_is_slash_comment_p()
  local commentstring = vim.bo.commentstring or ''
  local no_filetype = vim.bo.filetype == ''
  local is_slash_comment = false
  is_slash_comment = is_slash_comment or commentstring:match('/%*')
  is_slash_comment = is_slash_comment or commentstring:match('//')
  return is_slash_comment and not no_filetype
end

---@param params cmp.SourceCompletionApiParams
---@return cmp_path.Option
function source:_validate_option(params)
  local option = assert(vim.tbl_deep_extend('keep', params.option, defaults))
  vim.validate({
    trailing_slash = {option.trailing_slash, 'boolean'},
    label_trailing_slash = {option.label_trailing_slash, 'boolean'},
    get_cwd = {option.get_cwd, 'function'},
    show_hidden_files_by_default = {option.show_hidden_files_by_default, 'boolean'},
  })
  return option
end

return source
