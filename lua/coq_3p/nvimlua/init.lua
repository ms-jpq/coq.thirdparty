return function(spec)
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

  local parse = function(line, row, col)
    local before_cursor = string.sub(line, 1, col + 1)
    local match =
      string.reverse(
      string.match(string.reverse(before_cursor), "^[^%s]+") or ""
    )
    local path = vim.split(match, ".", true)

    local cur, seen = _G, {"_G"}
    local fin = false
    for idx, key in ipairs(path) do
      if type(cur) == "table" and type(cur[key]) == "table" then
        cur = cur[key]
        table.insert(seen, key)
        if idx == #path then
          fin = true
        end
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
          insertText = fin and "." .. key or key,
          kind = kind_map[type(val)],
          detail = table.concat(vim.tbl_flatten {seen, {key}}, ".")
        }
        table.insert(acc, item)
      end
    end

    return {isIncomplete = false, items = acc}
  end

  local is_win = vim.fn.has("win32") == 1
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
      local row, col = unpack(args.pos)
      if utils.in_comment(args.line) then
        callback(nil)
      else
        local go, parsed = pcall(parse, args.line, row, col)
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
