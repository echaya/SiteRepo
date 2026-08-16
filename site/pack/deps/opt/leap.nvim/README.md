<img align="left" width="150" height="85" src="../media/kangaroo.png?raw=true">

# leap.nvim

Leap is a motion and selection plugin for Neovim, building and improving
primarily on [vim-sneak](https://github.com/justinmk/vim-sneak). Using some
clever ideas, it allows you to jump to any position in the visible editor area
very quickly, with near-zero mental overhead.

### How to use it (TL;DR)

* Initiate the command in a given scope, and start typing a 2-character search
  pattern (`{char1}{char2}`). After typing `{char1}`, you can see **label
  characters** appearing next to some pairs. **They are not active yet, but
  this preview allows you to process them in the background**.

* Typing `{char2}` filters the matches, and the labels are now active. When the
  closest pair is not labeled, you automatically jump there. If that was your
  target, you can safely ignore the labels remaining on the screen - those will
  not conflict with any sensible command, and will disappear on the next
  keypress.

* Else: type the given label character to jump. If there are more matches than
  available labels, use `<space>` and `<backspace>` to move between groups.

To target the last character on a line, type `{char}<space>`; to target empty
lines, type `<space><space>`. Use `{char}<enter>` as a shortcut to the closest
`{char}` match.

> [!Note]
> To keep visual noise tolerable, preview is only enabled at word boundaries by
> default. Check `:h leap.opts.preview`.

### Why this method?

Not counting the trigger key, leaping to literally anywhere on the screen
rarely takes more than 3 keystrokes in total. Often 2 is enough.

At the same time, it reduces mental effort by all possible means:

* _You don't have to weigh alternatives_: a single universal motion type can be
  used in all non-trivial situations.

* _You don't have to compose motions_: one command achieves one logical
  movement.

* _You don't have to be aware of the context_: the eyes can keep focusing on
  the target the whole time.

* _You don't have to pause in the middle_: if typing at a moderate speed, your
  mind can prepare for the next steps ahead of time.

### Showcase

This efficient mode of navigation allows building interesting features on top
of it. "Text editing at the speed of thought" has become a bit of an inflated
phrase in the Vim world, but cloning an arbitrary syntax tree node from an
arbitrary window with eight keystrokes speaks for itself:

<figure>
    <img src="../media/showcase.gif?raw=true" width="80%" alt="Leap in action" title="Leap in action" />
    <figcaption>Copying a function from another window with help of Treesitter</figcaption>
</figure>

## Getting started

Help files are not exactly page-turners, but [`:help leap`](doc/leap.txt) is
written with considerable care (by humans, for humans), and I suggest at least
skimming it, even if you don't have a specific question yet, as it contains
lots of additional information and details.

### Requirements

* Neovim >= 0.10.0 stable, or latest nightly

* [repeat.vim](https://github.com/tpope/vim-repeat), for dot-repeating (`.`)
  delete/change/etc. operations (optional)

### Installation

```lua
vim.pack.add { 'https://codeberg.org/andyg/leap.nvim' }
```

> [!Note]
> Lazy loading is all the rage now, but doing it via your plugin manager is
> unnecessary, as Leap already lazy-loads itself, [as it
> should](https://github.com/neovim/neovim/issues/35562#issuecomment-3239702727).
> Using the `keys` feature of lazy.nvim might even cause
> [problems](https://codeberg.org/andyg/leap.nvim-github/issues/191).

### Mappings & configuration

Recommended starter configuration:

```lua
-- Jump
vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
vim.keymap.set('n',               'S', '<Plug>(leap-from-window)')

-- Visit (jump - operate - jump back)
vim.keymap.set({ 'n', 'o' }, 'gs', '<Plug>(leap-visit)')
vim.keymap.set({ 'n', 'o' }, 'gS', '<Plug>(leap-visit-linewise)')
vim.keymap.set({ 'x', 'o' }, 'ar', '<Plug>(leap-visit-text-object)')
vim.keymap.set({ 'x', 'o' }, 'ir', '<Plug>(leap-visit-inner-text-object)')
vim.keymap.set({ 'o' },      'rr', '<Plug>(leap-visit-line)')

vim.api.nvim_create_autocmd('User', {
  pattern = 'VisitDone',
  group = vim.api.nvim_create_augroup('VisitorMode', {}),
  callback = function(event)
    if vim.v.operator == 'y' and event.data.register == '"' then
      vim.cmd('normal! p')
    end
  end,
})

-- Treeselect
-- Tip: If you have set up remote text objects (`ar`/`ir`), `arn` will
-- work as expected (visit node).
vim.keymap.set({ 'x', 'o' }, 'an', function()
  require('leap.treesitter').select {
    opts = require('leap.user').with_traversal_keys('n', 'N')
  }
end)
```

See `:h leap-mappings` for more.

### Extra modules

<details>
<summary>Visit ("spooky actions at a distance")</summary>

Prior art: [leap-spooky.nvim](https://github.com/ggandor/leap-spooky.nvim), and
[flash.nvim](https://github.com/folke/flash.nvim)'s "remote operation" feature.

The `visit()` function allows you to perform an action in a remote location: it
forgets the current mode or pending operator, lets you leap to anywhere on the
tab page, then continues where it left off. Once returning to Normal mode, it
jumps back to the original position, as if you had operated from the distance.

```lua
-- For example, `gs{leap}yap` or `ygs{leap}ap` will yank the paragraph
-- at the position specified by `{leap}`.
vim.keymap.set({ 'n', 'x', 'o' }, 'gs', function()
  require('leap').visit()
end)
```

The recommended way though is automatically starting Visual mode after jumping,
so that from Normal mode you can e.g. `gs{leap}apy` (_leap-select-op_). This is
the same amount of keystrokes as the _leap-op-select_ (`gs{leap}yap`) or the
_op-leap-select_ (`ygs{leap}ap`) version, but here you have visual feedback,
can move around freely with arbitrary motion combinations, and correct
mistakes. The `input` parameter lets you feed keystrokes automatically:

```lua
vim.keymap.set({ 'n', 'o' }, 'gs', function()
  require('leap').visit { input = vim.fn.mode(true):match('o') and '' or 'v' }
end)
```

The keys `<Plug>(leap-visit)` and `<Plug>(leap-visit-linewise)` do this by
default (the above is the actual body or `<Plug>(leap-visit)` by the way).

By giving text objects as `input`, you can create _remote text objects_, for an
even more intuitive workflow (`yarp{leap}` - "yank a remote paragraph at...").
For this, you can use the readily available `<Plug>(leap-visit-text-object)`
and `<Plug>(leap-visit-inner-text-object)` keys. They are simple wrappers that
consume an additional input character before calling `visit()`, and feed that
character prefixed with `a` and `i`, respectively. (In `arp`, for example, `ar`
is the hardcoded LHS of the mapping, and `p` is the additional input.)

> [!Tip]
> This feature makes exchanging two regions of text moderately simple, without
> needing a custom plugin: delete region A + visit region B + `pP`. Example
> (swapping two words): `diw gs{leap}iw pP`.

**Icing on the cake: automatic paste after yanking**

By setting an autocommand on `VisitDone`, you can clone regions in the blink of
an eye, even from another window (just `ygs{leap}ap`, or, with predefiend
remote text object, `yarp{leap}`, and voilà, the remote paragraph appears
there):

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'VisitDone',
  group = vim.api.nvim_create_augroup('VisitorMode', {}),
  callback = function(event)
    -- Do not paste if some special register was in use.
    if vim.v.operator == 'y' and event.data.register == '"' then
      vim.cmd('normal! p')
    end
  end,
})
```

</details>

<details>
<summary>Treesitter integration</summary>

You can either choose a node directly (`van{label}`), or, in Normal/Visual
mode, use the traversal keys for incremental selection. The labels are forced
to be safe, so you can operate on the selection right away then (`vannny`).
Traversal can "wrap around" backwards (`vanN` selects the root node).

```lua
vim.keymap.set({ 'x', 'o' }, 'an', function()
  require('leap.treesitter').select {
    -- To increase/decrease the selection in a clever-f-like manner,
    -- with the trigger key itself (vannnNN...). The default keys
    -- (<enter>/<backspace>) also work, so feel free to skip this.
    opts = require('leap.user').with_traversal_keys('n', 'N')
  }
end)
```

> [!Tip]
> Use linewise mode (`Vannn...`, `yVan`) whenever possible, as it filters out
> redundant nodes in the same line range, making the selection much more
> efficient.

</details>

## Design considerations in detail

### The ideal

Premise: [Vim golf](https://www.vimgolf.com/) is incredibly fun, but efficient
movement between point A and B on the screen, in particular, should rather be a
non-issue. An ideal keyboard-driven interface would impose almost no more
cognitive burden than using a mouse, without the constant context-switching
required by the latter.

That is, **you do not want to think about**

* **the command**: we need one fundamental targeting method that can bring you
  anywhere: a jetpack on the back, instead of airline routes (↔
  [EasyMotion](https://github.com/easymotion/vim-easymotion) and its
  derivatives)

* **the context**: it should be enough to look at the target, and nothing else
  (↔ vanilla Vim motion combinations using relative line numbers and/or
  repeats)

* **the steps**: the motion should be atomic (↔ Vim motion combos), and ideally
  you should be able to type the whole input sequence in one go, on more or
  less autopilot (↔ any kind of just-in-time labeling method, including the
  "search command on steroids" approach by
  [Pounce](https://github.com/rlane/pounce.nvim) and
  [Flash](https://github.com/folke/flash.nvim))

All the while using as few keystrokes as possible, and getting distracted by as
little incidental visual noise as possible.

### How do we measure up?

It is obviously impossible to achieve all of the above at the same time, without
some trade-offs at least; but in our opinion Leap comes pretty close, occupying
a sweet spot in the design space. (The worst remaining offender might be visual
noise, but clever filtering in the preview phase can help - see `:h
leap.opts.preview`.)

The **one-step shift between perception and action** is the big idea that cuts
the Gordian knot: a fixed pattern length combined with previewing labels can
eliminate the surprise factor, and make the search-based method (our "jetpack")
work smoothly. Fortunately, even a 2-character pattern - the shortest one with
which we can play this trick - is usually long enough to sufficiently narrow
down the matches.

Fixed pattern length also makes **(safe) automatic jump to the first target**
possible. Even with preview, labels are a necessary evil, and we should
optimize for the common case as much as possible (something that Sneak got
absolutely right from the beginning). You cannot improve on jumping directly,
just like how `f` and `t` works, not having to use even `<enter>` to accept the
match. However, we can do this in a smart way: if there are many targets (more
than 15-20), we stay put, so we can use a bigger, "unsafe" label set - getting
the best of both worlds. The non-determinism we're introducing is less of an
issue here, since the outcome is known in advance.

In sum, compared to other methods based on labeling targets, Leap's approach is
unique in that it

* offers a smoother experience, by (somewhat) eliminating the pause before
  typing the label

* feels natural to use for both distant _and close_ targets

## FAQ

### Search and motions

<details>
<summary>Enhanced f/t motions (1-character search)</summary>

```lua
do
  local function ft(kwargs)
    require('leap').leap(
      vim.tbl_deep_extend('keep', kwargs, {
        inputlen = 1,
        inclusive = true,
        opts = {
          -- Force autojump.
          labels = '',
          -- Match the modes where you don't need labels (`:h mode()`).
          safe_labels = vim.fn.mode(1):match('no?') and '' or nil,
        },
      })
    )
  end

  -- A helper function making it easier to set "clever-f" behavior
  -- (using f/F or t/T instead of ;/, - see the plugin clever-f.vim).
  local clever = require('leap.user').with_traversal_keys
  local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')

  vim.keymap.set({ 'n', 'x', 'o' }, 'f', function()
    ft { opts = clever_f }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'F', function()
    ft { backward = true, opts = clever_f }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 't', function()
    ft { offset = -1, opts = clever_t }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'T', function()
    ft { backward = true, offset = 1, opts = clever_t }
  end)
end
```

</details>

<details>
<summary>Wildcard characters (one-way aliases)</summary>

The preview phase, unfortunately, makes them impossible, by design: for a
potential match, we might need to show two different labels - corresponding to
two different futures - at the same time (see `:h leap-wildcard-problem` for a
longer explanation). `smartcase` is experimentally supported, but it can only
be applied on the first input character (`:h leap-smartcase`).

</details>

<details>
<summary>Working with non-English text</summary>

If a [`language-mapping`](https://neovim.io/doc/user/map.html#language-mapping)
([`'keymap'`](https://neovim.io/doc/user/options.html#'keymap')) is active,
Leap waits for keymapped sequences as needed and searches for the keymapped
result.

Also check out `opts.equivalence_classes`, that lets you group certain
characters together as mutual aliases, e.g.:

```lua
{
  ' \t\r\n', 'aäàáâãā', 'dḍ', 'eëéèêē', 'gǧğ', 'hḥḫ',
  'iïīíìîı', 'nñ', 'oō', 'sṣšß', 'tṭ', 'uúûüűū', 'zẓ'
}
```

</details>

<details>
<summary>Disable autojumping to the first match</summary>

```lua
require('leap').opts.safe_labels = ''
```

</details>

<details>
<summary>Force autojumping to the first match</summary>

```lua
require('leap').opts.labels = ''
```

</details>

<details>
<summary>"Clever s" (à la Sneak)</summary>

```lua
do
  local clever_s = require('leap.user').with_traversal_keys('s', 'S')
  vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
    require('leap').leap { opts = clever_s }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'S', function()
    require('leap').leap { backward = true, opts = clever_s }
  end)
end
```

</details>

<details>
<summary>Arbitrary remote actions instead of jumping</summary>

Basic template:

```lua
local function remote_action ()
  require('leap').leap {
    windows = require('leap.user').get_focusable_windows(),
    action = function(target)
      local winid = target.wininfo.winid
      local lnum, col = unpack(target.pos)  -- 1/1-based indexing!
      -- ... do something at the given position ...
    end,
  }
end
```

See [Extending Leap](#extending-leap) for more.

</details>

### Labels and highlighting

<details>
<summary>Disable previewing labels</summary>

```lua
require('leap').opts.preview = false
```

</details>


<details>
<summary>Show all labels as uppercase</summary>

This might be helpful in case of having poorer eyesight or using relatively
small font sizes. Obviously, only lowercase and non-alphabetic labels are
expected in your label lists.

Warning: `on_beacons` is an experimental escape hatch, and this workaround
depends on implementation details.

```lua
require('leap').opts.on_beacons = function(targets)
  for _, t in ipairs(targets) do
    if t.label and t.beacon then
      local vt = t.beacon[2].virt_text
      if vt then vt[1][1] =  vim.fn.toupper(vt[1][1]) end
    end
  end
end
```

</details>


<details>
<summary>Grey out the search area ("backdrop" highlight)</summary>

There is a helper function for that in the `user` module:

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('LeapBackdrop', {}),
  callback = function()
    if vim.g.colors_name == 'this_color_scheme_needs_backdrop' then
      require('leap.user').set_backdrop_highlight('Comment')
    end
  end
})
```

NOTE: This is intended as an opt-in feature for end users. Color scheme plugins
should make sure that the labels are clearly visible as they are, and should
not rely on "greywashing" by default.

</details>

<details>
<summary>Restore the default highlighting</summary>

If a certain color scheme sets the highlight groups for Leap in a way that you
don't particularly like, the simplest solution (besides a PR) is:

```lua
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('LeapColorTweaks', {}),
  callback = function()
    if vim.g.colors_name == 'bad_color_scheme' then
      -- Forces using the defaults: sets `IncSearch` for labels,
      -- `Search` for matches, and updates the look of concealed labels.
      require('leap').init_hl(true)
    end
  end
})
```

</details>

### Miscellaneous

<details>
<summary>Mappings for surround plugins</summary>

If `s` and `S` are used by Leap, I suggest either `gz` or `gm` as the prefix
for surround commands (e.g.: `gz{motion}`, `gzz`, `gzd`, `gzr`, etc.). Even if
unused in itself, `gs` is not an ideal choice, because `gss` cannot be mapped
to linewise surround then.

</details>

<details>
<summary>Was the name inspired by Jef Raskin's Leap?</summary>

To paraphrase Steve Jobs about their logo and Turing's poison apple, I wish it
were, but it is a coincidence. "Leap" is just another synonym for "jump", that
happens to rhyme with Sneak. That said, you can think of the name as a
little tribute to the great pioneer of interface design, even though embracing
the modal paradigm is a fundamental difference in Vim's approach.

</details>

## Extending Leap

There are lots of ways you can extend the plugin and bend it to your will - see
`:h leap.leap()` and `:h leap-events`. Besides tweaking the basic parameters of
the function (search scope, jump offset, etc.), you can:

* feed it with a prepared search pattern
* feed it with prepared targets, and only use it as labeler/selector
* give it a custom action to perform, instead of jumping
* customize the behavior of specific calls via autocommands

Examples:

<details>
<summary>Search integration</summary>

When finishing a `/` or `?` search command, automatically label visible
matches, so that you can jump to them directly.

```lua
vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('LeapOnSearch', {}),
  callback = function()
    local ev = vim.v.event
    local is_search_cmd = (ev.cmdtype == '/') or (ev.cmdtype == '?')
    -- Allow CmdLineLeave-related chores to be completed before
    -- invoking Leap.
    vim.schedule(function()
      local cnt = vim.fn.searchcount().total
      if is_search_cmd and (not ev.abort) and (cnt > 1) then
        -- We want "safe" labels, but no autojump (as the search
        -- command already does that), so just use `safe_labels`
        -- as `labels`, with n/N removed.
        local labels = require('leap').opts.safe_labels:gsub('[nN]', '')
        -- For `pattern` search, we never need to adjust conceallevel
        -- (no user input). We cannot merge `nil` from a table, but
        -- using the option's current value has the same effect.
        local vim_opts = { ['wo.conceallevel'] = vim.wo.conceallevel }
        require('leap').leap {
          pattern = vim.fn.getreg('/'),  -- last search pattern
          windows = { vim.fn.win_getid() },
          opts = { safe_labels = '', labels = labels, vim_opts = vim_opts, }
        }
      end
    end)
  end,
})
```

The above might be enough for your needs, but here is another snippet, which
sets keys to leap to visible matches of the previous search pattern anytime. It
also:

* allows traversing with the trigger key, so that you can `<c-s><c-s>...`.
* allows using the keys in Command-line mode too, so that you can exit and jump
  (or traverse) right away, without needing to press `enter` first
  (`/pattern<c-s>{label}`, `/pattern<c-s><c-s>...`).

Rationale for the suggested keys: `<c-s>` is the default Leap trigger combined
with a modifier, to make it usable in Command-line mode; and with `<c-q>`, the
pair resembles `c_CTRL-G` and `c_CTRL-T` (`s` is - sort of - below `q`).

```lua
do
  local function leap_search (key, is_reverse)
    local cmdline_mode = vim.fn.mode(true):match('^c')
    if cmdline_mode then
      -- Finish the search command.
      vim.api.nvim_feedkeys(vim.keycode('<enter>'), 't', false)
    end
    if vim.fn.searchcount().total < 1 then
      return
    end
    -- Activate again if `:nohlsearch` has been used (Normal/Visual mode).
    vim.go.hlsearch = vim.go.hlsearch
    -- Allow the search command to complete its chores before
    -- invoking Leap (Command-line mode).
    vim.schedule(function()
      require('leap').leap {
        pattern = vim.fn.getreg('/'),
        -- If you always want to go forward/backward with the given key,
        -- regardless of the previous search direction, just set this to
        -- `is_reverse`.
        backward = (is_reverse and vim.v.searchforward == 1)
                   or (not is_reverse and vim.v.searchforward == 0),
        opts = require('leap.user').with_traversal_keys(key, nil, {
          -- Autojumping to the second match would be confusing without
          -- 'incsearch'.
          safe_labels = (cmdline_mode and not vim.o.incsearch) and ''
                        -- Keep n/N usable in any case.
                        or require('leap').opts.safe_labels:gsub('[nN]', '')
        })
      }
      -- You might want to switch off the highlights after leaping.
      -- vim.cmd('nohlsearch')
    end)
  end

  vim.keymap.set({ 'n', 'x', 'o', 'c' }, '<c-s>', function()
    leap_search('<c-s>', false)
  end, { desc = 'Leap to search matches' })

  vim.keymap.set({ 'n', 'x', 'o', 'c' }, '<c-q>', function()
    leap_search('<c-q>', true)
  end, { desc = 'Leap to search matches (reverse)' })
end
```

</details>

<details>
<summary>Jump to lines</summary>

```lua
vim.keymap.set({ 'n', 'x', 'o' }, '|', function()
  local line = vim.fn.line('.')
  -- Skip 3-3 lines around the cursor.
  local top, bot = unpack { math.max(1, line - 3), line + 3 }
  require('leap').leap {
    pattern = '\\v(%<'..top..'l|%>'..bot..'l)$',
    windows = { vim.fn.win_getid() },
    opts = { safe_labels = '' }
  }
end)
```

</details>

<details>
<summary>Shortcuts to Telescope results</summary>

```lua
local function get_targets (picker)
  local scroller = require('telescope.pickers.scroller')
  local wininfo = vim.fn.getwininfo(picker.results_win)[1]
  local bottom = wininfo.botline - 2  -- skip the current row
  local top = math.max(
    scroller.top(picker.sorting_strategy,
                 picker.max_results,
                 picker.manager:num_results()),
    wininfo.topline - 1
  )
  local targets = {}
  for lnum = bottom, top, -1 do
    table.insert(targets, { wininfo = wininfo, pos = { lnum + 1, 1 } })
  end
  return targets
end

local function pick_with_leap (buf)
  local picker = require('telescope.actions.state').get_current_picker(buf)
  require('leap').leap {
    targets = get_targets(picker),
    action = function(target)
      picker:set_selection(target.pos[1] - 1)
      require('telescope.actions').select_default(buf)
    end,
  }
end

require('telescope').setup {
  defaults = {
    mappings = {
      i = { ['<a-p>'] = pick_with_leap },
    }
  }
}
```

</details>
