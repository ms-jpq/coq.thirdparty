-- !!WARN !!

--
-- THIS IS **NOT** STABLE API
--

-- !!WARN !!

local M = {}

local DEBUG = vim.env.COQ_DEBUG

M.debug_err = function(...)
  if DEBUG then
    vim.api.nvim_err_writeln(table.concat({...}, "\n"))
  end
end

local split_line = function(line, col)
  vim.validate {
    line = {line, "string"},
    col = {col, "number"}
  }

  local c = math.min(math.max(0, col), #line)
  local lhs = string.sub(line, 1, c)
  local rhs = string.sub(line, c + 1)
  return lhs, rhs
end

M.cword = function(line, col)
  vim.validate {
    line = {line, "string"},
    col = {col, "number"}
  }

  local lhs, rhs = split_line(line, col)
  local search_b = vim.fn.matchstr(lhs, [[\v\w+$]])
  local search_f = vim.fn.matchstr(rhs, [[\v^\w+]])
  return search_b .. search_f
end

M.in_comment = function(line)
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

return M
