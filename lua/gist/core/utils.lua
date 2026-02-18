local M = {}

function M.get_current_selection(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()

  start_line = start_line - 1 -- Convert to 0-based line number
  end_line = end_line - 1     -- Convert to 0-based line number

  local lines =
      vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

  return table.concat(lines, "\n")
end

function M.get_last_selection()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Save the current cursor position
  local saved_cursor = vim.api.nvim_win_get_cursor(0)

  -- Get the start and end positions of the visual selection
  vim.cmd("normal! gv")
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Restore the cursor position
  vim.api.nvim_win_set_cursor(0, saved_cursor)

  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]
  local content_lines =
      vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local content = table.concat(content_lines, "\n")

  return content
end

local function read_file(path)
  local file = io.open(path, "rb") -- r read mode and b binary mode
  if not file then
    return nil
  end
  local content = file:read("*a") -- *a or *all reads the whole file
  file:close()
  return content
end

---@param content string
function M.write_tmp(content)
  local filename = os.tmpname()

  local file = io.open(filename, "w+")

  if file == nil then
    return nil
  end

  file:write(content)
  file:close()

  return filename
end

--- Execute a shell command with optional stdin
---@param cmd string|string[] Command to execute
---@param stdin string? Optional input to pass to the command
---@return string? output Command output
---@return number exit_code Exit code (0 = success)
function M.exec(cmd, stdin)
  local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd

  local output
  if stdin then
    output = vim.fn.system(cmd_str, stdin)
  else
    output = vim.fn.system(cmd_str)
  end

  local exit_code = vim.v.shell_error

  return output, exit_code
end

function M.extract_gist_url(output)
  local pattern = "https://gist.github.com/%S+"

  return output:match(pattern)
end

-- @param args string
function M.parseArgs(args)
  -- parse args as key=value
  local parsed = {}

  for _, arg in ipairs(vim.split(args, " ", {})) do
    local key, value = unpack(vim.split(arg, "=", { plain = true }))

    if value == "true" then
      value = true
    elseif value == "false" then
      value = false
    end

    parsed[key] = value
  end

  return parsed
end

function M.detect_multiplexer()
  local tmux = vim.env.TMUX
  local zellij = vim.env.ZELLIJ

  if tmux and tmux ~= "" then
    return "tmux"
  elseif zellij and zellij ~= "" then
    return "zellij"
  end

  return nil
end

function M.create_multiplexer_command(multiplexer, command)
  local cmd_str = type(command) == "table" and table.concat(command, " ")
      or command

  if multiplexer == "tmux" then
    return string.format("tmux new-window '%s'", cmd_str)
  elseif multiplexer == "zellij" then
    return string.format("zellij run -c -i -n gist -- %s", cmd_str)
  end

  return nil
end

function M.read_buffer(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

function M.read_current_buffer_content()
  local lines = M.read_buffer(vim.api.nvim_get_current_buf())
  return table.concat(lines, "\n")
end

--- executes the given command
---@param cmd string[]
---@param err string
function M.system(cmd, err)
  local proc = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    error(err)
  end
  return vim.split(vim.trim(proc), "\n")
end

return M
