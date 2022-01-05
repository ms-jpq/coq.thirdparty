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

  return function(args, callback)
    local row, col = unpack(args.pos)
    local _ = nil

    (function()
      local suggestion = vim.b._copilot_suggestion
      if not (type(suggestion) == "table" and type(suggestion.text) == "string") then
        callback(nil)
      else
        vim.validate {
          position = {suggestion.position, "table"},
          label = {suggestion.displayText, "string"},
          new_text = {suggestion.text, "string"},
          range = {suggestion.range, "table"}
        }

        local _, u16_col = vim.str_utfindex(args.line, col)
        local cop_row, cop_col =
          suggestion.position.line,
          suggestion.position.character
        vim.validate {row = {row, "number"}, col = {col, "number"}}

        local same_row = cop_row == row
        local col_diff = u16_col - cop_col
        local almost_same_col = col_diff >= 0 and col_diff < 6

        if not (same_row and almost_same_col) then
          callback(nil)
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
          callback(
            {
              isIncomplete = true,
              items = {item}
            }
          )
        end
      end
    end)()
  end
end
