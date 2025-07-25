--- @class (exact) blink.cmp.SnippetsConfig
--- @field preset 'default' | 'luasnip' | 'mini_snippets'
--- @field expand fun(snippet: string) Function to use when expanding LSP provided snippets
--- @field active fun(filter?: { direction?: number }): boolean Function to use when checking if a snippet is active
--- @field jump fun(direction: number) Function to use when jumping between tab stops in a snippet, where direction can be negative or positive
--- @field score_offset number Offset to the score of all snippet items

--- @param handlers table<'default' | 'luasnip' | 'mini_snippets', fun(...): any>
local function by_preset(handlers)
  return function(...)
    local preset = require('blink.cmp.config').snippets.preset
    return handlers[preset](...)
  end
end

--- Guess whether we can expand an hidden luasnip snippet
--- @return boolean
local function is_hidden_snippet()
  local ls = require('luasnip')
  return not require('blink.cmp').is_visible() and not ls.locally_jumpable(1) and ls.expandable()
end

local validate = require('blink.cmp.config.utils').validate
local snippets = {
  --- @type blink.cmp.SnippetsConfig
  default = {
    preset = 'default',
    -- NOTE: we wrap `vim.snippet` calls to reduce startup by 1-2ms
    expand = by_preset({
      default = function(snippet) vim.snippet.expand(snippet) end,
      luasnip = function(snippet) require('luasnip').lsp_expand(snippet) end,
      mini_snippets = function(snippet)
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
        insert({ body = snippet })
        -- HACK: mini.snippets may edit the buffer during TextChangedI, so we need to ensure
        -- we run after it completes it callback. We do this by resubscribing to TextChangedI
        require('blink.cmp').resubscribe()
      end,
    }),
    active = by_preset({
      default = function(filter) return vim.snippet.active(filter) end,
      luasnip = function(filter)
        local ls = require('luasnip')
        if is_hidden_snippet() then return true end
        if filter and filter.direction then return ls.jumpable(filter.direction) end
        return ls.locally_jumpable(1)
      end,
      mini_snippets = function()
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        return MiniSnippets.session.get(false) ~= nil
      end,
    }),
    jump = by_preset({
      default = function(direction) vim.snippet.jump(direction) end,
      luasnip = function(direction)
        local ls = require('luasnip')
        if is_hidden_snippet() then return ls.expand_or_jump() end
        return ls.jumpable(direction) and ls.jump(direction)
      end,
      mini_snippets = function(direction)
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        MiniSnippets.session.jump(direction == -1 and 'prev' or 'next')
      end,
    }),
    score_offset = -3,
  },
}

function snippets.validate(config)
  validate('snippets', {
    preset = {
      config.preset,
      function(preset) return vim.tbl_contains({ 'default', 'luasnip', 'mini_snippets' }, preset) end,
      'one of: "default", "luasnip", "mini_snippets"',
    },
    expand = { config.expand, 'function' },
    active = { config.active, 'function' },
    jump = { config.jump, 'function' },
    score_offset = { config.score_offset, 'number' },
  }, config)
end

return snippets
