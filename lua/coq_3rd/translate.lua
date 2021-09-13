return {
  completefunc = function(matches)
    local acc = {}
    for _, match in ipairs(matches) do
      local item = {
        label = match.abbr or match.word,
        insertText = match.word,
        detail = match.info
      }
      table.insert(acc, item)
    end
    return acc
  end
}
