---@class render.md.Env
local M = {}

M.uv = vim.uv or vim.loop

M.has_10 = vim.fn.has('nvim-0.10') == 1
M.has_11 = vim.fn.has('nvim-0.11') == 1

---@param key 'ft'|'cmd'
---@return string[]
function M.lazy(key)
    -- https://github.com/folke/lazydev.nvim/blob/main/lua/lazydev/pkg.lua -> get_plugin_path
    if type(package.loaded.lazy) ~= 'table' then
        return {}
    end
    local ok, lazy_config = pcall(require, 'lazy.core.config')
    if not ok then
        return {}
    end
    local name = 'render-markdown.nvim'
    local plugin = lazy_config.spec.plugins[name]
    if plugin == nil then
        return {}
    end
    local values = plugin[key]
    if type(values) == 'table' then
        return values
    elseif type(values) == 'string' then
        return { values }
    else
        return {}
    end
end

---@param file string|integer
---@return number
function M.file_size_mb(file)
    if type(file) ~= 'string' then
        file = vim.api.nvim_buf_get_name(file)
    end
    local ok, stats = pcall(function()
        return M.uv.fs_stat(file)
    end)
    if not (ok and stats) then
        return 0
    end
    return stats.size / (1024 * 1024)
end

---@param callback fun()
---@return fun()
function M.runtime(callback)
    return function()
        local start_time = M.uv.hrtime()
        callback()
        local end_time = M.uv.hrtime()
        vim.print(string.format('Runtime (ms): %.1f', (end_time - start_time) / 1e+6))
    end
end

---@param buf integer
---@param win integer
---@return boolean
function M.valid(buf, win)
    if not M.buf.valid(buf) or not M.win.valid(win) then
        return false
    end
    return buf == M.win.buf(win)
end

---@class render.md.env.Row
M.row = {}

---@param buf integer
---@param win integer
---@return integer?
function M.row.get(buf, win)
    if buf ~= M.buf.current() then
        return nil
    end
    return vim.api.nvim_win_get_cursor(win)[1] - 1
end

---@param win integer
---@param row integer
---@return boolean
function M.row.visible(win, row)
    return vim.api.nvim_win_call(win, function()
        return vim.fn.foldclosed(row) == -1
    end)
end

---@class render.md.env.Mode
M.mode = {}

---@return string
function M.mode.get()
    return vim.fn.mode(true)
end

---@param mode string
---@param modes render.md.Modes
---@return boolean
function M.mode.is(mode, modes)
    if type(modes) == 'boolean' then
        return modes
    else
        return vim.tbl_contains(modes, mode)
    end
end

---@class render.md.env.Buf
M.buf = {}

---@return integer
function M.buf.current()
    return vim.api.nvim_get_current_buf()
end

---@param buf integer
---@return boolean
function M.buf.valid(buf)
    return vim.api.nvim_buf_is_valid(buf)
end

---@param buf integer
---@param name string
---@return render.md.option.Value
---@overload fun(buf: integer, name: 'buflisted'): boolean
---@overload fun(buf: integer, name: 'buftype'): integer
---@overload fun(buf: integer, name: 'filetype'): integer
---@overload fun(buf: integer, name: 'tabstop'): integer
function M.buf.get(buf, name)
    return vim.api.nvim_get_option_value(name, { buf = buf })
end

---@param buf integer
---@param name string
---@param value render.md.option.Value
function M.buf.set(buf, name, value)
    if value ~= M.buf.get(buf, name) then
        vim.api.nvim_set_option_value(name, value, { buf = buf })
    end
end

---@param buf integer
---@return integer
function M.buf.win(buf)
    return vim.fn.bufwinid(buf)
end

---@param buf integer
---@return integer[]
function M.buf.windows(buf)
    return vim.fn.win_findbuf(buf)
end

---@class render.md.env.Win
M.win = {}

---@return integer
function M.win.current()
    return vim.api.nvim_get_current_win()
end

---@param win integer
---@return boolean
function M.win.valid(win)
    return vim.api.nvim_win_is_valid(win)
end

---@param win integer
---@param name string
---@return render.md.option.Value
---@overload fun(win: integer, name: 'conceallevel'): integer
---@overload fun(win: integer, name: 'diff'): boolean
function M.win.get(win, name)
    return vim.api.nvim_get_option_value(name, { scope = 'local', win = win })
end

---@param win integer
---@param name string
---@param value render.md.option.Value
function M.win.set(win, name, value)
    if value ~= M.win.get(win, name) then
        vim.api.nvim_set_option_value(name, value, { scope = 'local', win = win })
    end
end

---@param win integer
---@return integer
function M.win.buf(win)
    return vim.fn.winbufnr(win)
end

---@param win integer
---@return integer
function M.win.width(win)
    local infos = vim.fn.getwininfo(win)
    local textoff = #infos == 1 and infos[1].textoff or 0
    return vim.api.nvim_win_get_width(win) - textoff
end

---@param win integer
---@return vim.fn.winsaveview.ret
function M.win.view(win)
    return vim.api.nvim_win_call(win, vim.fn.winsaveview)
end

return M
