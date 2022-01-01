local utils = require("coq_3p.utils")

return function(spec)
  local conf_only = true

  if spec.conf_only ~= nil then
    conf_only = spec.conf_only
  end

  vim.validate {
    conf_only = {conf_only, "boolean"}
  }

  local lsp_kinds = vim.lsp.protocol.CompletionItemKind

  local kind_map = {
    ["nil"] = lsp_kinds.Constant,
    ["function"] = lsp_kinds.Function,
    thread = lsp_kinds.Class,
    table = lsp_kinds.Struct,
    userdata = lsp_kinds.Struct,
    string = lsp_kinds.Property,
    number = lsp_kinds.Property,
    boolean = lsp_kinds.Property
  }

  local parse = function(match)
    local path = vim.split(match, ".", true)

    local cur, seen = _G, {"_G"}
    for idx, key in ipairs(path) do
      if type(cur) == "table" and type(cur[key]) == "table" then
        cur = cur[key]
        table.insert(seen, key)
      else
        break
      end
    end
    assert(type(cur), "table")

    local acc = {}
    for key, val in pairs(cur) do
      -- [A-z][A-z | 0-9]*
      if vim.fn.matchstr(key, [[\v^\w(\w|\d)*$]]) == key then
        local item = {
          label = key,
          insertText = key,
          kind = kind_map[type(val)],
          detail = table.concat(vim.tbl_flatten {seen, {key}}, ".")
        }
        table.insert(acc, item)
      end
    end

    return {
      isIncomplete = false,
      items = acc
    }
  end

  local p_norm = function(path)
    return utils.is_win and string.lower(path) or path
  end

  local conf_dir = p_norm(vim.fn.stdpath("config"))

  local should = function(line, match)
    if vim.bo.filetype ~= "lua" then
      return false
    end

    if #match <= 0 then
      return false
    end

    if utils.in_comment(line) then
      return false
    end

    if conf_only then
      local bufname = p_norm(vim.api.nvim_buf_get_name(0))
      return vim.startswith(bufname, conf_dir)
    end

    return true
  end

  return function(args, callback)
    local _, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local match = vim.fn.matchstr(before_cursor, [[\v(\w|\.)+$]])

    if not should(args.line, match) then
      callback(nil)
    else
      local go, parsed = pcall(parse, match)
      if go then
        callback(parsed)
      else
        callback(nil)
        utils.debug_err(parsed)
      end
    end
  end
end
