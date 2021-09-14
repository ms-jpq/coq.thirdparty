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

M.split_line = function(line, col)
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

  local lhs, rhs = M.split_line(line, col)
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

M.rand_between = function(lo, hi)
  vim.validate {
    lo = {lo, "number"},
    hi = {hi, "number"}
  }
  assert(hi >= lo)

  local lo, hi = math.ceil(lo), math.floor(hi)
  return math.floor(math.random() * (hi - lo + 1) + lo)
end

M.pick = function(list)
  vim.validate {
    list = {list, "table"}
  }
  local length = #list
  assert(length > 0)
  local item = list[M.rand_between(1, length)]
  assert(item)
  return item
end

M.snippet_escape = function(text)
  vim.validate {
    text = {text, "string"}
  }

  local l1 = string.gsub(text, [[\]], [[\\]])
  local l2 = string.gsub(l1, "%$", [[\$]])
  return l2
end

return M
