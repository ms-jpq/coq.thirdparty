return function(spec)
  local name = spec.short_name or "NOTM"
  local query_template = spec.query_template or "from:*${keyword}*"
  
  return function(args, callback)
    local line = args.line
    local notmuch_path = vim.fn.exepath("notmuch")

    local keyword = nil
    
    keyword = string.match(line, "[Tt][Oo]:%s*(.*)")
    if not keyword then keyword = string.match(line, "[Ff][Rr][Oo][mm]:%s*(.*)") end
    if not keyword then keyword = string.match(line, "[Cc][Cc]:%s*(.*)") end
    if not keyword then keyword = string.match(line, "[Bb][Cc][Cc]:%s*(.*)") end
    
    if not keyword then
      return callback(nil)
    end

    keyword = string.gsub(keyword, "^%s*(.-)%s*$", "%1")
    
    if #keyword < 2 then
      return callback(nil)
    end

    local query = string.gsub(query_template, "%${keyword}", keyword)
    local stdout_lines = {}
    local results = {}

    local chan = vim.fn.jobstart(
      { notmuch_path, "address", "--format=text", query },
      {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, lines)
          if lines then
            for _, l in ipairs(lines) do
              if l ~= "" then table.insert(stdout_lines, l) end
            end
          end
        end,
        on_stderr = function(_, msg)
        end,
        on_exit = function(_, code)
          if code == 0 then
            for _, email in ipairs(stdout_lines) do
              table.insert(results, {
                label = email,
                insertText = email,
                detail = "Notmuch Address",
                kind = 1
              })
            end
            callback(results)
          else
            callback(nil)
          end
        end,
      }
    )

    if chan <= 0 then
      callback(nil)
    else
      return function()
        vim.fn.jobstop(chan)
      end
    end
  end
end
