-- !!WARN !!

--
-- THIS IS **NOT** STABLE API
--

-- !!WARN !!

local utils = require("coq_3p.utils")

local kind_map =
  (function()
  local lsp_kinds = vim.lsp.protocol.CompletionItemKind

  local acc = {
    v = lsp_kinds.Variable,
    f = lsp_kinds.Function,
    m = lsp_kinds.Property,
    t = lsp_kinds.TypeParameter
    --d = lsp_kinds.Macro
  }

  for key, val in pairs(lsp_kinds) do
    if type(key) == "string" and type(val) == "number" then
      acc[string.lower(key)] = val
    end
  end

  return acc
end)()

local completefunc_items = function(matches)
  vim.validate {
    matches = {matches, "table"},
    words = {matches.words, "table", true}
  }

  local words = matches.words and matches.words or matches

  local parse = function(match)
    vim.validate {
      match = {match, "table"},
      word = {match.word, "string"},
      abbr = {match.abbr, "string", true},
      menu = {match.menu, "string", true},
      kind = {match.kind, "string", true},
      info = {match.info, "string", true}
    }

    local kind_taken, menu_taken = false, false

    local kind = (function()
      local lkind = string.lower(match.kind or "")
      if kind_map[lkind] then
        kind_taken = true
        return kind_map[lkind]
      end
      local lmenu = string.lower(match.menu or "")
      if kind_map[lmenu] then
        menu_taken = true
        return kind_map[lmenu]
      end

      return nil
    end)()

    local label = (function()
      local label = match.abbr or match.word
      if match.menu and not menu_taken then
        menu_taken = true
        return label .. "\t" .. match.menu .. ""
      else
        return label
      end
    end)()

    local detail = (function()
      if match.info then
        return match.info
      elseif match.kind and not kind_taken then
        return match.kind
      else
        return nil
      end
    end)()

    local item = {
      label = label,
      insertText = match.word,
      kind = kind,
      detail = detail
    }

    return item
  end

  local acc = {}
  for _, match in ipairs(words) do
    local item = parse(match)
    table.insert(acc, item)
  end

  return acc
end

local omnifunc = function(opts)
  vim.validate {
    use_cache = {opts.use_cache, "boolean"},
    omnifunc = {opts.omnifunc, "string"},
    filetypes = {opts.filetypes, "table", true}
  }

  local filetypes = (function()
    local acc = {}
    for _, ft in ipairs(opts.filetypes or {}) do
      vim.validate {ft = {ft, "string"}}
      acc[ft] = true
    end
    return acc
  end)()

  local omnifunc = (function()
    local vlua = "v:lua."
    if vim.startswith(opts.omnifunc, vlua) then
      local name = string.sub(opts.omnifunc, #vlua + 1)
      return function(...)
        return _G[name](...)
      end
    else
      return function(...)
        return vim.call(opts.omnifunc, ...)
      end
    end
  end)()

  local fetch = function(line, row, col)
    local pos = omnifunc(1, "")
    vim.validate {pos = {pos, "number"}}

    if pos == -2 or pos == -3 then
      return nil
    else
      local cword = utils.cword(line, pos)
      local matches = omnifunc(0, cword) or {}
      local items = completefunc_items(matches)

      return {isIncomplete = not opts.use_cache, items = items}
    end
  end

  local wrapped = function(line, row, col)
    vim.validate {
      line = {line, "string"},
      row = {row, "number"},
      col = {col, "number"}
    }

    if not opts.filetypes or filetypes[vim.bo.filetype] then
      if utils.in_comment(line) then
        return nil
      else
        local go, items = pcall(fetch, line, row, col)
        if go then
          return items
        else
          utils.debug_err(items)
          return nil
        end
      end
    else
      return nil
    end
  end

  return wrapped
end

local wrap = function(opts)
  local omni = omnifunc(opts)
  return function(args, callback)
    local row, col = unpack(args.pos)
    local items = omni(args.line, row, col)
    callback(items)
  end
end

return wrap
