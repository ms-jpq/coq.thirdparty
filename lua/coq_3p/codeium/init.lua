local utils = require("coq_3p.utils")

return function(spec)
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
    return {
      prefix = prefix,
      text = text,
      type = type
    }
  end

  local trans = function(current_row, item)
    vim.validate {item = {item, "table"}}
    local range = item.range
    local completion = item.completion
    local suffix = item.suffix
    local parts = item.completionParts or {}
    vim.validate {
      current_row = {current_row, "number"},
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
    for _, part in ipairs(parts) do
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

  local parse = function(buf, start_line, start_row, col, row_offset_lo, xform)
    vim.validate {
      buf = {buf, "number"},
      start_line = {start_line, "string"},
      start_row = {start_row, "number"},
      col = {col, "number"},
      row_offset_lo = {row_offset_lo, "number"},
      xform = {xform, "table"}
    }

    local start_col = xform.start_offset - row_offset_lo
    local same_row = xform.start_row == start_row
    local col_diff = col - start_col
    local almost_same_col = math.abs(col_diff) <= 6

    if not (same_row and almost_same_col) then
      return nil
    end

    local text = xform.text
    local label = vim.trim(text)

    local filterText = (function()
      local parts = xform.parts
      for _, part in ipairs(parts) do
        if part.type == "COMPLETION_PART_TYPE_INLINE" then
          local lhs = vim.fn.matchstr(part.prefix, [[\v\w+$]])
          local rhs = vim.fn.matchstr(part.text, [[\v^\w+]])
          local text = lhs .. rhs
          if #text >= 1 then
            return text
          end
        end
      end
      return label
    end)()

    local range =
      (function()
      local end_row = xform.end_row
      local row_offset_hi = vim.api.nvim_buf_get_offset(buf, end_row)
      local end_col = xform.end_offset - row_offset_hi
      local end_line =
        unpack(vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, true))

      local col_shift = function(ro, co)
        if ro ~= start_row then
          return co
        elseif co >= col then
          return co + col_diff
        else
          return co
        end
      end

      return {
        start = {
          line = start_row,
          character = col_shift(start_row, start_col)
        },
        ["end"] = {
          line = end_row,
          character = col_shift(end_row, end_col)
        }
      }
    end)()

    local edit = {
      preselect = true,
      label = label,
      filterText = filterText,
      documentation = label,
      textEdit = {
        newText = text,
        range = range
      }
    }

    return edit
  end

  local pull = function()
    local comp = vim.b._codeium_completions or {}
    local acc = comp.items or {}

    vim.validate {acc = {acc, "table", nil}}

    local uuids = {}
    for _, item in ipairs(acc or {}) do
      local uuid = item.completionId
      if uuid then
        vim.validate {uuid = {uuid, "string"}}
        table.insert(uuids, uuid)
      end
    end

    local id = table.concat(uuids, "")
    return acc, id
  end

  local items =
    (function()
    local uid = ""
    local suggestions = {}

    local function loopie()
      local maybe_suggestions, new_uid = pull()
      suggestions = maybe_suggestions or suggestions
      if uid ~= new_uid and #suggestions >= 1 then
        utils.run_completefunc()
      end
      uid = new_uid
      vim.defer_fn(loopie, 88)
    end
    loopie()

    return function(row, col, start_line)
      vim.validate {
        row = {row, "number"},
        col = {col, "number"},
        start_line = {start_line, "string"}
      }

      local buf = vim.api.nvim_get_current_buf()
      local row_offset_lo = vim.api.nvim_buf_get_offset(buf, row)

      local acc = {}
      for _, item in pairs(suggestions) do
        local xform = trans(row, item)

        local edit = parse(buf, start_line, row, col, row_offset_lo, xform)
        if edit then
          table.insert(acc, edit)
        end
      end
      return acc
    end
  end)()

  -- vim.g.codeium_manual = true

  -- local notify = utils.throttle(vim.fn["codeium#Complete"], 66)
  return function(args, callback)
    -- notify()
    local row, col = unpack(args.pos)

    callback(
      {
        isIncomplete = true,
        items = items(row, col, args.line)
      }
    )
  end
end
