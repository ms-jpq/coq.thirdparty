local completefunc_items = function(matches)
  local acc = {}
  for _, match in ipairs(matches) do
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

local omnifunc = function(omnifunc)
  local omni = vim.fn[omnifunc]

  return function(row, col)
    local pos = omni(1, "")

    if pos == -2 or pos == -3 then
      return nil
    else
      local cword = (function()
        if pos < 0 or pos >= col then
          return vim.fn.expand("<cword>")
        else
          local line =
            vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
          local search = string.sub(line, pos + 1)
          return search
        end
      end)()

      local matches = omni(0, cword)
      local words = matches.words and matches.words or matches
      local items = completefunc_items(words)

      return {isIncomplete = true, items = items}
    end
  end
end

return {
  completefunc = completefunc,
  omnifunc = omnifunc
}
