return function(spec)
  local accept_key = spec.accept_key
  if not accept_key then
    vim.api.nvim_err_writeln(
      [[Please update :: { src = "copilot", short_name = "COP", accept_key = "|something like <c-f> would work|" }]]
    )
    accept_key = "<c-f>"
  end

  COQcopilot = function()
    local esc_pum =
      vim.fn.pumvisible() == 1 and
      vim.api.nvim_replace_termcodes("<c-e>", true, true, true) or
      ""
    return esc_pum .. vim.fn["copilot#Accept"]()
  end

  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.api.nvim_set_keymap(
    "i",
    accept_key,
    [[v:lua.COQcopilot()]],
    {nowait = true, silent = true, expr = true}
  )

  local maybe_item = function(row, col, suggestion)
    vim.validate {
      row = {row, "number"},
      col = {col, "number"},
      suggestion = {suggestion, "table"}
    }
    vim.validate {
      position = {suggestion.position, "table"},
      label = {suggestion.displayText, "string"},
      new_text = {suggestion.text, "string"},
      range = {suggestion.range, "table"}
    }
    local cop_row, cop_col =
      suggestion.position.line,
      suggestion.position.character
    vim.validate {cop_row = {cop_row, "number"}, cop_col = {cop_col, "number"}}

    local same_row = cop_row == row
    local col_diff = col - cop_col
    local almost_same_col = col_diff >= 0 and col_diff < 6

    if not (same_row and almost_same_col) then
      return nil
    else
      local filterText = vim.fn.matchstr(suggestion.text, [[\v^\S+]])

      local range =
        (function()
        local fin = suggestion.range["end"]

        vim.validate {
          start = {suggestion.range.start, "table"},
          ["end"] = {fin, "table"}
        }
        vim.validate {
          line = {fin.line, "number"},
          character = {fin.character, "number"}
        }

        local ending =
          (function()
          if fin.line ~= row then
            return fin
          else
            return {
              line = fin.line,
              character = fin.character + col_diff
            }
          end
        end)()

        return {
          start = suggestion.range.start,
          ["end"] = ending
        }
      end)()

      local item = {
        preselect = true,
        label = suggestion.displayText,
        insertText = suggestion.text,
        filterText = filterText,
        documentation = suggestion.displayText,
        textEdit = {
          newText = suggestion.text,
          range = range
        }
      }
      return item
    end
  end

  local items = (function()
    local ooda = nil
    local suggestions = {}
    ooda = function()
      local copilot = vim.b._copilot
      if copilot then
        vim.validate {copilot = {copilot, "table"}}
        local maybe_suggestions = copilot.suggestions
        if maybe_suggestions then
          vim.validate {maybe_suggestions = {maybe_suggestions, "table"}}
          suggestions = maybe_suggestions
        end
      end
      vim.defer_fn(ooda, 88)
    end
    ooda()

    return function(row, col)
      local items = {}
      for _, suggestion in pairs(suggestions) do
        local item = maybe_item(row, col, suggestion)
        if item then
          table.insert(items, item)
        end
      end
      return items
    end
  end)()

  return function(args, callback)
    local row, col = unpack(args.pos)
    local _, u16_col = vim.str_utfindex(args.line, col)
    local _ = nil

    (function()
      callback(
        {
          isIncomplete = true,
          items = items(row, u16_col)
        }
      )
    end)()
  end
end
