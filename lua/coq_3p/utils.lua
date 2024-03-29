-- !!WARN !!

--
-- THIS IS **NOT** PUBLIC API
--

-- !!WARN !!

local DEBUG = vim.env.COQ_DEBUG

local M = {}

M.MAX_COL_DIFF = 6

M.is_win = vim.fn.has("win32") == 1

M.sep = M.is_win and [[\]] or "/"

M.noop = function(...)
  return ...
end

M.constantly = function(...)
  local x = {...}
  return function()
    return unpack(x)
  end
end

M.bind = function(fn, ...)
  vim.validate {fn = {fn, "function"}}
  local args = {...}
  return function(...)
    return fn(unpack(args), ...)
  end
end

M.debug_err = function(...)
  if DEBUG then
    vim.api.nvim_err_writeln(table.concat({...}, "\n"))
  end
end

M.freeze = function(name, original)
  vim.validate {
    name = {name, "string"},
    original = {original, "table"}
  }

  local proxy =
    setmetatable(
    {},
    {
      __index = function(_, key)
        if original[key] == nil then
          error("NotImplementedError :: " .. name .. "->" .. key)
        else
          return original[key]
        end
      end,
      __newindex = function(_, key, val)
        error(
          "TypeError :: " ..
            vim.inspect {key, val} .. "->frozen<" .. name .. ">"
        )
      end
    }
  )
  return proxy
end

M.new_uid = function(map)
  vim.validate {
    map = {map, "table"}
  }

  local key = nil
  while true do
    if not key or map[key] then
      key = math.floor(math.random() * 10000)
    else
      return key
    end
  end
end

M.linesep = function()
  local nl = vim.bo.fileformat
  if nl == "unix" then
    return "\n"
  elseif nl == "dos" then
    return "\r\n"
  elseif nl == "mac" then
    return "\r"
  else
    assert(false)
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
  if #commentstring <= 0 then
    return false
  else
    local lhs, rhs = unpack(vim.split(commentstring, "%s", true))
    local trimmed = vim.trim(line)
    local surrounded =
      vim.startswith(trimmed, lhs) and vim.endswith(trimmed, rhs)
    return surrounded
  end
end

M.comment = function(cstring)
  vim.validate {
    cstring = {cstring, "string", true}
  }

  local lhs, rhs = (function()
    local commentstring = cstring or vim.bo.commentstring or ""
    if #commentstring <= 0 then
      return "", ""
    else
      local lhs, rhs = unpack(vim.split(commentstring, "%s", true))
      return lhs or "", rhs or ""
    end
  end)()

  local off = function(line)
    vim.validate {
      line = {line, "string"}
    }
    if vim.startswith(line, lhs) and vim.endswith(line, rhs) then
      local l1 = string.sub(line, #lhs + 1)
      local l2 = string.sub(l1, 1, -(#rhs + 1))
      return l2
    else
      return line
    end
  end

  local on = function(line)
    vim.validate {
      line = {line, "string"}
    }

    local uncommented = off(line)
    return lhs .. uncommented .. rhs
  end

  return on, off
end

M.match_tail = function(tail, str)
  vim.validate {
    tail = {tail, "string"},
    str = {str, "string"}
  }
  local tail_len = #tail

  if tail_len <= 0 then
    return ""
  else
    local ending = string.sub(str, -tail_len)
    return ending == tail and string.sub(str, 1, -tail_len - 1) or ""
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

M.run_completefunc = function()
  local legal_modes = {
    ["i"] = true,
    ["ic"] = true,
    ["ix"] = true
  }
  local legal_cmodes = {
    [""] = true,
    ["eval"] = true,
    ["function"] = true,
    ["ctrl_x"] = true
  }
  local info = vim.fn.complete_info {"pum_visible"}
  local mode = vim.api.nvim_get_mode().mode
  local comp_mode = vim.fn.complete_info({"mode"}).mode
  if not info.pum_visible and legal_modes[mode] and legal_cmodes[comp_mode] then
    COQ.omnifunc(0, "")
  end
end

local new_timer = function(timeout, f)
  vim.validate {
    timeout = {timeout, "number"},
    f = {f, "function"}
  }
  local timer = vim.loop.new_timer()
  local cancel = function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
  end
  timer:start(
    timeout,
    0,
    function()
      cancel()
      f()
    end
  )
  return cancel
end

M.throttle = function(f, delay)
  vim.validate {
    f = {f, "function"},
    delay = {delay, "number"}
  }

  local wraped = vim.schedule_wrap(f)
  local cancel = function()
  end
  local touched = 0

  return function()
    local now = vim.loop.now()
    local elapsed = now - touched

    local exec = function()
      touched = now
      wraped()
    end

    if elapsed >= delay then
      exec()
    else
      cancel()
      cancel = new_timer(delay - elapsed, exec)
    end
  end
end

return M
