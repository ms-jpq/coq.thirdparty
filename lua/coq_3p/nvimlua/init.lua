return function(spec)
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

  local parse = function()
    local line = vim.api.nvim_get_current_line()
    local match =
      string.reverse(string.match(string.reverse(line), "^[^%s]+") or "")
    local path = vim.split(match, ".", true)

    local cur, seen = _G, {"_G"}
    local fin = false
    for idx, key in ipairs(path) do
      if type(cur) == "table" and type(cur[key]) == "table" then
        cur = cur[key]
        table.insert(seen, key)
        if idx == #pass then
          fin = true
        end
      else
        break
      end
    end
    assert(type(cur), "table")

    local acc = {}
    for key, val in pairs(cur) do
      local item = {
        label = key,
        insertText = fin and "." .. key or key,
        kind = kind_map[type(val)],
        detail = table.concat(vim.tbl_flatten {seen, {key}}, ".")
      }
      table.insert(acc, item)
    end

    return acc
  end

  return function(args, callback)
    if vim.bo.filetype ~= "lua" then
      callback(nil)
    else
      local go, parsed = pcall(parse)
      if go then
        callback(parsed)
      else
        vim.api.nvim_err_writeln(parsed)
      end
    end
  end
end
