local completefunc_items = function(matches)
  vim.validate {
    matches = {matches, "table"}
  }

  local words = matches.words and matches.words or matches

  local acc = {}
  for _, match in ipairs(words) do
    local item = {
      label = match.abbr or match.word,
      insertText = match.word,
      kind = vim.lsp.protocol.CompletionItemKind[match.kind],
      detail = match.info
    }
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
      return _G[string.sub(opts.omnifunc, #vlua + 1)]
    else
      return vim.fn[opts.omnifunc]
    end
  end)()

  local fetch = function(row, col)
    local pos = omnifunc(1, "")
    vim.validate {pos = {pos, "number"}}

    if pos == -2 or pos == -3 then
      return nil
    else
      local cword = (function()
        if pos < 0 or pos >= col then
          return vim.fn.expand("<cword>")
        else
          local line =
            vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
          local search = string.sub(line, math.min(col, pos) + 1)
          local cword = string.match(search, "[^%s]+")
          return cword
        end
      end)()

      local matches = omnifunc(0, cword)
      local items = completefunc_items(matches)

      return {isIncomplete = not opts.use_cache, items = items}
    end
  end

  local wrapped = function(row, col)
    if not opts.filetypes or filetypes[vim.bo.filetype] then
      return fetch(row, col)
    else
      return nil
    end
  end

  return wrapped
end

return {
  completefunc_items = completefunc_items,
  omnifunc = omnifunc
}
