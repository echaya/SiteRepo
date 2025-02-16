---@class snacks.image.doc
local M = {}

---@class snacks.image.Hover
---@field img snacks.image.Placement
---@field win snacks.win
---@field buf number

---@alias snacks.image.transform fun(buf:number, src:string, anchor: TSNode, image: TSNode): string

---@type table<string, snacks.image.transform>
M.transforms = {
  ---@param anchor TSNode
  ---@param img TSNode
  norg = function(buf, _, anchor, img)
    local row, col = img:start()
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    return line:sub(col + 1)
  end,
}

local hover ---@type snacks.image.Hover?
local uv = vim.uv or vim.loop

---@param str string
function M.url_decode(str)
  return str:gsub("+", " "):gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
end

---@param buf number
---@param src string
function M.resolve(buf, src)
  src = M.url_decode(src)
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  local s = Snacks.image.config.resolve and Snacks.image.config.resolve(file, src) or nil
  if s then
    return s
  end
  if not src:find("^%w%w+://") then
    if src:find("^%.") or src:find("^%w") then
      for _, dir in ipairs({ vim.fs.dirname(file), uv.cwd() }) do
        local path = dir .. "/" .. src
        if vim.fn.filereadable(path) == 1 then
          src = path
          break
        end
      end
    end
    src = vim.fs.normalize(src)
  end
  return src
end

---@param buf number
---@param from? number
---@param to? number
function M.find(buf, from, to)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then
    return {}
  end
  parser:parse(from and to and { from, to } or true)
  local ret = {} ---@type {id:string, pos:snacks.image.Pos, src:string}[]
  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local query = vim.treesitter.query.get(tree:lang(), "images")
    if not query then
      return
    end
    for _, match, meta in query:iter_matches(tstree:root(), buf, from and from - 1 or nil, to and to - 1 or nil) do
      local src, pos, nid ---@type string, snacks.image.Pos, string
      local anchor, image ---@type TSNode, TSNode
      for id, nodes in pairs(match) do
        nodes = type(nodes) == "userdata" and { nodes } or nodes
        local name = query.captures[id]
        for _, node in ipairs(nodes) do
          if name == "image" then
            image = node
            src = vim.treesitter.get_node_text(node, buf, { metadata = meta[id] })
          elseif name == "anchor" then
            anchor = node
            local range = { node:range() }
            pos = { range[1] + 1, range[2] }
            nid = node:id()
          end
        end
      end
      if src and pos and nid then
        local transform = M.transforms[tree:lang()]
        if transform then
          src = transform(buf, src, anchor, image)
        end
        src = M.resolve(buf, src)
        ret[#ret + 1] = { id = nid, pos = pos, src = src }
      end
    end
  end)
  return ret
end

function M.hover_close()
  if hover then
    hover.win:close()
    hover.img:close()
    hover = nil
  end
end

--- Get the image at the cursor (if any)
---@return string? image_src, snacks.image.Pos? image_pos
function M.at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local img = M.find(vim.api.nvim_get_current_buf(), cursor[1], cursor[1] + 1)[1]
  if img then
    return img.src, img.pos
  end
end

function M.hover()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()

  if hover and hover.win.win == current_win and hover.win:valid() then
    return
  end

  if hover and (not hover.win:valid() or hover.buf ~= current_buf or vim.fn.mode() ~= "n") then
    M.hover_close()
  end

  local src = M.at_cursor()
  if not src then
    return M.hover_close()
  end

  if hover and hover.img.img.src ~= src then
    M.hover_close()
  elseif hover then
    hover.img:update()
    return
  end

  local win = Snacks.win(Snacks.win.resolve(Snacks.image.config.doc, "snacks_image", {
    show = false,
    enter = false,
  }))
  win:open_buf()
  local updated = false
  local o = Snacks.config.merge({}, Snacks.image.config.doc, {
    on_update_pre = function()
      if hover and not updated then
        updated = true
        local loc = hover.img:state().loc
        win.opts.width = loc.width
        win.opts.height = loc.height
        win:show()
      end
    end,
    inline = false,
  })
  hover = {
    win = win,
    buf = current_buf,
    img = Snacks.image.placement.new(win.buf, src, o),
  }
  vim.api.nvim_create_autocmd({ "BufWritePost", "CursorMoved", "ModeChanged", "BufLeave" }, {
    buffer = current_buf,
    once = true,
    callback = M.hover,
  })
end

---@param buf number
function M.inline(buf)
  local imgs = {} ---@type table<string, snacks.image.Placement>
  return function()
    local found = {} ---@type table<string, boolean>
    for _, i in ipairs(M.find(buf)) do
      local img = imgs[i.id] ---@type snacks.image.Placement?
      if img and img.img.src ~= i.src then
        img:close()
        img = nil
      end

      if not img then
        img = Snacks.image.placement.new(
          buf,
          i.src,
          Snacks.config.merge({}, Snacks.image.config.doc, {
            pos = i.pos,
            inline = true,
          })
        )
        imgs[i.id] = img
      else
        img:update()
      end
      found[i.id] = true
    end
    for nid, img in pairs(imgs) do
      if not found[nid] then
        img:close()
        imgs[nid] = nil
      end
    end
  end
end

---@param buf number
function M.attach(buf)
  if vim.b[buf].snacks_image_attached then
    return
  end
  vim.b[buf].snacks_image_attached = true
  local inline = Snacks.image.config.doc.inline and Snacks.image.terminal.env().placeholders
  local float = Snacks.image.config.doc.float and not inline

  if not inline and not float then
    return
  end

  local group = vim.api.nvim_create_augroup("snacks.image.doc." .. buf, { clear = true })

  local update = inline and M.inline(buf) or M.hover

  if inline then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      buffer = buf,
      callback = vim.schedule_wrap(update),
    })
  else
    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = group,
      buffer = buf,
      callback = vim.schedule_wrap(update),
    })
  end
  vim.schedule(update)
end

return M
