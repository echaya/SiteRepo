local Conceal = require('render-markdown.core.conceal')
local Env = require('render-markdown.lib.env')
local Node = require('render-markdown.lib.node')
local Range = require('render-markdown.core.range')
local Str = require('render-markdown.lib.str')
local log = require('render-markdown.core.log')

---@class render.md.context.Props
---@field buf integer
---@field win integer
---@field mode string
---@field top_level_mode boolean

---@class render.md.context.Offset
---@field col integer
---@field width integer

---@class render.md.Context
---@field private buf integer
---@field private win integer
---@field private ranges render.md.Range[]
---@field private callouts table<integer, render.md.CustomCallout>
---@field private checkboxes table<integer, render.md.CustomCheckbox>
---@field private offsets table<integer, render.md.context.Offset[]>
---@field private window_width? integer
---@field mode string
---@field top_level_mode boolean
---@field conceal render.md.Conceal
---@field last_heading? integer
local Context = {}
Context.__index = Context

---@param props render.md.context.Props
---@param offset integer
---@return render.md.Context
function Context.new(props, offset)
    local self = setmetatable({}, Context)
    self.buf = props.buf
    self.win = props.win

    local ranges = {}
    for _, window in ipairs(Env.buf.windows(self.buf)) do
        table.insert(ranges, Context.compute_range(self.buf, window, offset))
    end
    self.ranges = Range.coalesce(ranges)

    self.callouts = {}
    self.checkboxes = {}
    self.offsets = {}
    self.window_width = nil

    self.mode = props.mode
    self.top_level_mode = props.top_level_mode
    self.conceal = Conceal.new(self, self.buf, self.win)
    self.last_heading = nil

    return self
end

---@private
---@param buf integer
---@param win integer
---@param offset integer
---@return render.md.Range
function Context.compute_range(buf, win, offset)
    local top = math.max(Env.win.view(win).topline - 1 - offset, 0)

    local bottom = top
    local lines = vim.api.nvim_buf_line_count(buf)
    local size = vim.api.nvim_win_get_height(win) + (2 * offset)
    while bottom < lines and size > 0 do
        bottom = bottom + 1
        if Env.row.visible(win, bottom) then
            size = size - 1
        end
    end

    return Range.new(top, bottom)
end

---@param component render.md.BaseComponent
---@return boolean
function Context:skip(component)
    -- Skip disabled components regardless of mode
    if not component.enabled then
        return true
    end
    -- Enabled components in top level modes should not be skipped
    if self.top_level_mode then
        return false
    end
    -- Enabled components in component modes should not be skipped
    return not Env.mode.is(self.mode, component.render_modes)
end

---@return integer
function Context:get_buf()
    return self.buf
end

---@param row integer
---@return render.md.CustomCallout?
function Context:get_callout(row)
    return self.callouts[row]
end

---@param row integer
---@param callout render.md.CustomCallout
function Context:add_callout(row, callout)
    self.callouts[row] = callout
end

---@param row integer
---@return render.md.CustomCheckbox?
function Context:get_checkbox(row)
    return self.checkboxes[row]
end

---@param row integer
---@param checkbox render.md.CustomCheckbox
function Context:add_checkbox(row, checkbox)
    self.checkboxes[row] = checkbox
end

---@return integer
function Context:tab_size()
    return Env.buf.get(self.buf, 'tabstop')
end

---@param node? render.md.Node
---@return integer
function Context:width(node)
    if node == nil then
        return 0
    end
    return Str.width(node.text) + self:get_offset(node) - self.conceal:get(node)
end

---@param row integer
---@param offset render.md.context.Offset
function Context:add_offset(row, offset)
    if offset.width <= 0 then
        return
    end
    if self.offsets[row] == nil then
        self.offsets[row] = {}
    end
    table.insert(self.offsets[row], offset)
end

---@private
---@param node render.md.Node
---@return integer
function Context:get_offset(node)
    local result = 0
    local offsets = self.offsets[node.start_row] or {}
    for _, offset in ipairs(offsets) do
        if node.start_col <= offset.col and node.end_col > offset.col then
            result = result + offset.width
        end
    end
    return result
end

---@param offset number
---@param width integer
---@return integer
function Context:to_width(offset, width)
    if offset <= 0 then
        return 0
    elseif offset < 1 then
        return math.floor(((self:get_width() - width) * offset) + 0.5)
    else
        return offset
    end
end

---@private
---@return integer
function Context:get_width()
    if self.window_width == nil then
        self.window_width = Env.win.width(self.win)
    end
    return self.window_width
end

---@param win integer
---@return boolean
function Context:contains_window(win)
    local window_range = Context.compute_range(self.buf, win, 0)
    return self:for_each(function(range)
        return range:contains(window_range.top, window_range.bottom)
    end)
end

---@param node TSNode
---@return boolean
function Context:overlaps_node(node)
    local top, _, bottom, _ = node:range()
    return self:for_each(function(range)
        return range:overlaps(top, bottom)
    end)
end

---@param parser vim.treesitter.LanguageTree
function Context:parse(parser)
    self:for_each(function(range)
        parser:parse({ range.top, range.bottom })
    end)
end

---@param root TSNode
---@param query vim.treesitter.Query
---@param callback fun(capture: string, node: render.md.Node)
function Context:query(root, query, callback)
    self:for_each(function(range)
        for id, ts_node in query:iter_captures(root, self.buf, range.top, range.bottom) do
            local capture = query.captures[id]
            local node = Node.new(self.buf, ts_node)
            log.node(capture, node)
            callback(capture, node)
        end
    end)
end

---@param callback fun(range: render.md.Range): boolean?
---@return boolean
function Context:for_each(callback)
    for _, range in ipairs(self.ranges) do
        if callback(range) then
            return true
        end
    end
    return false
end

---@type table<integer, render.md.Context>
local cache = {}

---@class render.md.ContextManager
local M = {}

---@param props render.md.context.Props
function M.reset(props)
    cache[props.buf] = Context.new(props, 10)
end

---@param buf integer
---@param win integer
---@return boolean
function M.contains_range(buf, win)
    local context = cache[buf]
    return context ~= nil and context:contains_window(win)
end

---@param buf integer
---@return render.md.Context
function M.get(buf)
    return cache[buf]
end

return M
