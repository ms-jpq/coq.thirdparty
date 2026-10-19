local utils = require "coq_3p.utils"

local uv = vim.uv or vim.loop

local description_of = function(text)
  local lines = vim.split(text, "\n", { plain = true })
  local first = unpack(lines)
  if vim.trim(first or "") ~= "---" then
    return nil
  end
  local description, block = {}, false
  for index = 2, #lines do
    local line = string.gsub(lines[index], "\r$", "")
    if line == "---" or line == "..." then
      break
    end
    if block then
      if string.match(line, "^%S") then
        break
      end
      table.insert(description, vim.trim(line))
    else
      local value = string.match(line, "^description:%s*(.*)$")
      if value then
        value = vim.trim(value)
        if value == "" or string.match(value, "^[>|][+-]?%s*$") then
          block = true
        else
          if string.match(value, [[^".*"$]]) then
            local ok, decoded = pcall(vim.json.decode, value)
            value = ok and decoded or string.sub(value, 2, -2)
          elseif string.match(value, [[^'.*'$]]) then
            value = string.gsub(string.sub(value, 2, -2), "''", "'")
          end
          return value
        end
      end
    end
  end
  local value = vim.trim(table.concat(description, " "))
  return value ~= "" and value or nil
end

local read_skill = function(filename)
  local stat = uv.fs_stat(filename)
  if not stat or stat.type ~= "file" then
    return nil
  end

  local file = io.open(filename, "r")
  if not file then
    return nil
  end
  local text = file:read "*a"
  file:close()
  return text
end

return function(spec)
  local paths = (spec or {}).paths or {}
  utils.validate { paths = { paths, "table" } }
  for _, directory in ipairs(paths) do
    utils.validate { path = { directory, "string" } }
  end

  return function(args, callback)
    if vim.bo.filetype ~= "markdown" then
      callback(nil)
      return
    end

    local skills, visited = {}, {}
    local range
    local prefix = ""
    local fragment
    do
      local row, col = unpack(args.pos)
      local before = string.sub(args.line, 1, col)
      local slash, _, matched = string.find(before, "/([%w_-]+)$")
      if not slash then
        callback(nil)
        return
      end
      fragment = string.lower(matched)
      local keyword = vim.fn.matchstr(before, [[\k*$]])
      prefix = string.sub(before, slash, col - #keyword)
      range = {
        start = { line = row, character = slash - 1 },
        ["end"] = {
          line = row,
          character = col + #(string.match(string.sub(args.line, col + 1), "^[%w_-]*") or ""),
        },
      }
    end

    local scan = function(directory)
      directory = vim.fs.normalize(directory)
      if visited[directory] then
        return
      end
      visited[directory] = true
      local handle = uv.fs_scandir(directory)
      if not handle then
        return
      end

      while true do
        local name, kind = uv.fs_scandir_next(handle)
        if not name then
          break
        end
        if
          not skills[name]
          and vim.startswith(string.lower(name), fragment)
          and (kind == "directory" or kind == "link")
        then
          local filename = vim.fs.joinpath(directory, name, "SKILL.md")
          local text = read_skill(filename)
          if text then
            local label = "/" .. name
            local description = description_of(text)
            skills[name] = {
              label = label,
              insertText = vim.startswith(label, prefix) and string.sub(label, #prefix + 1) or label,
              filterText = name,
              kind = vim.lsp.protocol.CompletionItemKind.Reference,
              labelDetails = description and { description = description } or nil,
              textEdit = {
                newText = label,
                range = range,
              },
              documentation = description and { kind = "markdown", value = description } or nil,
            }
          end
        end
      end
    end

    do
      local bufname = vim.api.nvim_buf_get_name(0)
      local directory = vim.bo.buftype == "" and bufname ~= "" and vim.fs.dirname(bufname) or uv.cwd()
      while directory do
        for _, scope in ipairs { ".", ".agents", ".codex", ".claude" } do
          scan(vim.fs.joinpath(directory, scope, "skills"))
        end
        local parent = vim.fs.dirname(directory)
        if parent == directory then
          break
        end
        directory = parent
      end

      local home = uv.os_homedir()
      if home then
        scan(vim.fs.joinpath(home, "skills"))
      end
    end
    for _, directory in ipairs(paths) do
      scan(directory)
    end

    local items = vim.tbl_values(skills)
    table.sort(items, function(lhs, rhs)
      return lhs.label < rhs.label
    end)
    callback { isIncomplete = true, items = items }
  end, { offset_encoding = "utf-8" }
end
