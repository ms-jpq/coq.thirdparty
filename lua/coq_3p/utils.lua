-- !!WARN !!

--
-- THIS IS **NOT** STABLE DO NOT DEPEND ON IMPLEMENTATION DETAIL
--

-- !!WARN !!

local DEBUG = vim.env.COQ_DEBUG

return {
  debug_err = function(...)
    if DEBUG then
      vim.api.nvim_err_writeln(table.concat({...}, "\n"))
    end
  end,
  in_comment = function(line)
    vim.validate {
      line = {line, "string"}
    }

    local commentstring = vim.bo.commentstring or ""
    if #commentstring == 0 then
      return false
    else
      local lhs, rhs = unpack(vim.split(commentstring, "%s", true))
      local trimmed = vim.trim(line)
      local surrounded =
        vim.startswith(trimmed, lhs) and vim.endswith(trimmed, rhs)
      return surrounded
    end
  end
}
