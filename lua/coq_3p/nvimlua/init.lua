return function(spec)
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

  local parse = function(row, col)
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
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
      local item = {
        label = key,
        insertText = fin and "." .. key or key,
        kind = kind_map[type(val)],
        detail = table.concat(vim.tbl_flatten {seen, {key}}, ".")
      }
      table.insert(acc, item)
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
      local go, parsed = pcall(parse, row, col)
      if go then
        callback(parsed)
      else
        vim.api.nvim_err_writeln(parsed)
      end
    end
  end
end
