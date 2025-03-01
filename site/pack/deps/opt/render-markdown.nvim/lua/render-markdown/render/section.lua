local Base = require('render-markdown.render.base')
local Str = require('render-markdown.lib.str')

---@class render.md.render.Section: render.md.Renderer
---@field private indent render.md.Indent
---@field private level_change integer
local Render = setmetatable({}, Base)
Render.__index = Render

---@return boolean
function Render:setup()
    self.indent = self.config.indent
    if self.context:skip(self.indent) then
        return false
    end

    local current_level = self.node:level(false)
    local parent_level = math.max(self.node:level(true), self.indent.skip_level)
    self.level_change = current_level - parent_level

    -- Nothing to do if there is not a change in level
    if self.level_change <= 0 then
        return false
    end

    return true
end

function Render:render()
    local start_row = self:get_start_row()
    local end_row = self:get_end_row()
    -- Each level stacks inline marks so we only need to process change in level
    local virt_text = self:indent_line(false, self.level_change)
    for row = start_row, end_row do
        self.marks:add(false, row, 0, {
            priority = 0,
            virt_text = virt_text,
            virt_text_pos = 'inline',
        })
    end
end

---@private
---@return integer
function Render:get_start_row()
    if self.indent.skip_heading then
        -- Exclude any lines potentially used by section heading
        local second = self.node:line('first', 1)
        local start_offset = Str.width(second) == 0 and 1 or 0
        return self.node.start_row + 1 + start_offset
    else
        -- Include last empty line in previous section
        -- Exclude if it is the only empty line in that section
        local above, two_above = self.node:line('above', 1), self.node:line('above', 2)
        local above_is_empty = Str.width(above) == 0
        local two_above_is_section = two_above ~= nil and vim.startswith(two_above, '#')
        local start_offset = (above_is_empty and not two_above_is_section) and 1 or 0
        return math.max(self.node.start_row - start_offset, 0)
    end
end

---@private
---@return integer
function Render:get_end_row()
    -- Exclude last empty line in current section
    -- Include if it is the only empty line of the last subsection
    local last, second_last = self.node:line('last', 0), self.node:line('last', 1)
    local last_is_empty = Str.width(last) == 0
    local second_last_is_section = second_last ~= nil and vim.startswith(second_last, '#')
    local end_offset = (last_is_empty and not second_last_is_section) and 1 or 0
    return self.node.end_row - 1 - end_offset
end

return Render
