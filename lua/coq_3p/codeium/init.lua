local utils = require("coq_3p.utils")

return function(spec)
  local items =
    (function()
    local ooda = nil
    local uid = nil
    local items = {}
    ooda = function()
      local comp = vim.b._codeium_completions or {}
      items = comp.items or {}
      vim.validate {items = {items, "table"}}

      local uuids = {}
      for _, item in pairs(items) do
        local uuid = item.completionId
        if uuid then
          vim.validate {uuid = {uuid, "string"}}
          table.insert(uuids, uuid)
        end
      end

      local id = table.concat(uuids, "")
      if uid ~= id then
        utils.run_completefunc()
      end
      uid = id

      vim.defer_fn(ooda, 88)
    end
    ooda()

    local tr = function(part)
      vim.validate {part = {part, "table"}}
      local line = tonumber(part.line)
      local offset = tonumber(part.offset)
      local prefix = part.prefix
      local text = part.text
      local type = part.type
      vim.validate {
        prefix = {prefix, "string", true},
        text = {text, "string"},
        type = {type, "string"}
      }
    end

    local trans = function(current_row, item)
      vim.validate {item = {item, "table"}}
      local range = item.range
      local completion = item.completion
      local suffix = item.suffix
      local parts = item.completionParts
      vim.validate {
        completion = {completion, "table"},
        parts = {parts, "table"},
        range = {range, "table"},
        suffix = {suffix, "table", true}
      }

      local text = completion.text
      local end_position = range.endPosition
      local start_position = range.startPosition

      vim.validate {
        end_position = {end_position, "table"},
        start_position = {start_position, "table"},
        text = {text, "string"}
      }

      local end_row = tonumber(end_position.row) or current_row
      local end_offset = tonumber(range.endOffset)
      local start_row = tonumber(start_position.row) or end_row
      local start_offset = tonumber(range.startOffset) or end_offset

      vim.validate {
        end_offset = {end_offset, "number"},
        end_row = {end_row, "number"},
        start_offset = {start_offset, "number"},
        start_row = {start_row, "number"}
      }

      local acc = {}
      for _, part in pairs(parts) do
        local parsed = tr(part)
        table.insert(acc, parsed)
      end

      return {
        parts = acc,
        end_offset = end_offset,
        end_row = end_row,
        start_offset = start_offset,
        start_row = start_row,
        text = text
      }
    end

    return function(start_row, col, start_line)
      vim.validate {
        col = {col, "number"},
        start_row = {start_row, "number"},
        start_line = {start_line, "string"}
      }

      local buf = vim.api.nvim_get_current_buf()
      local row_offset_lo = vim.api.nvim_buf_get_offset(buf, start_row)
      local _, u16_col = vim.str_utfindex(start_line, col)

      local acc = {}
      for _, item in pairs(items) do
        local xform = trans(start_row, item)

        local start_col = xform.start_offset - row_offset_lo
        local same_row = xform.start_row == start_row
        local col_diff = col - start_col
        local almost_same_col = math.abs(col_diff) <= 6

        if same_row and almost_same_col then
          local text = xform.text
          local label = vim.trim(text)

          local range =
            (function()
            local end_row = xform.end_row
            local row_offset_hi = vim.api.nvim_buf_get_offset(buf, end_row)
            local end_col = xform.end_offset - row_offset_hi
            local end_line =
              unpack(
              vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, true)
            )

            local _, u16_col_start = vim.str_utfindex(start_line, start_col)
            local u16_col_end = (function()
              local _, u16_col_end = pcall(vim.str_utfindex, end_line, end_col)
              if go then
                return u16_col_end
              else
                return vim.str_utfindex(end_line)
              end
            end)()

            local col_shift = function(ro, co)
              if ro ~= start_row then
                return co
              elseif co >= u16_col then
                -- TODO: Calculate the diff in u16
                return co + col_diff
              else
                return co
              end
            end

            return {
              start = {
                line = start_row,
                character = col_shift(start_row, u16_col_start)
              },
              ["end"] = {
                line = end_row,
                character = col_shift(end_row, u16_col_end)
              }
            }
          end)()

          local edit = {
            preselect = true,
            label = label,
            filterText = label,
            documentation = label,
            textEdit = {
              newText = text,
              range = range
            }
          }

          table.insert(acc, edit)
        end
      end

      return acc
    end
  end)()

  return function(args, callback)
    local row, col = unpack(args.pos)

    local bufnr = vim.fn.bufnr("")
    vim.fn["codeium#Complete"](bufnr)

    callback(
      {
        isIncomplete = true,
        items = items(row, col, args.line)
      }
    )
  end
end
