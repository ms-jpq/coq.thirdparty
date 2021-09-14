return function(spec)
  local is_win = vim.fn.has("win32") == 1
  local utils = require("coq_3p.utils")

  vim.validate {
    conf_only = {spec.conf_only, "boolean"}
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

  local parse = function(line, col)
    local before_cursor = utils.split_line(line, col)
    local match = vim.fn.matchstr(before_cursor, [[\v(\w|\.)+$]])
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

    return {isIncomplete = false, items = acc}
  end

  local p_norm = function(path)
    return is_win and string.lower(path) or path
  end

  local conf_dir = p_norm(vim.fn.stdpath("config"))
  local should = function()
    if vim.bo.filetype ~= "lua" then
      return false
    elseif spec.conf_only then
      local bufname = p_norm(vim.api.nvim_buf_get_name(0))
      return vim.startswith(bufname, conf_dir)
    else
      return false
    end
  end

  return function(args, callback)
    if not should() then
      callback(nil)
    else
      local _, col = unpack(args.pos)
      if utils.in_comment(args.line) then
        callback(nil)
      else
        local go, parsed = pcall(parse, args.line, col)
        if go then
          callback(parsed)
        else
          callback(nil)
          utils.debug_err(parsed)
        end
      end
    end
  end
end
