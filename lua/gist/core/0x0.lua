M = {}

local utils = require('gist.core.utils')
local gist = require("gist")

---@param content string
---@param private boolean
function M.create(_, content, _, private)
  ---@type Gist.Platforms.0x0
  local config = gist.config.platforms['0x0']

  local filename = utils.write_tmp(content)
  if not filename then
    return nil, "Failed to create temporary file"
  end

  local cmd = {
    "curl",
    "-sS",
    "-H", "User-Agent: gist.nvim",
    "-F", string.format("file=@%s", filename),
  }

  if config.private or private then
    table.insert(cmd, "-F")
    table.insert(cmd, "secret=")
  end

  table.insert(cmd, config.url or "https://0x0.st")

  local ok, output = pcall(utils.system, cmd, "failed to curl")
  if not ok then
    os.remove(filename)
    return nil, tostring(output)
  end

  if output == nil or #output == 0 or output[1] == "" then
    os.remove(filename)
    return nil, "No output from 0x0.st"
  end

  local url = output[1]:gsub("%s+$", "")

  os.remove(filename)

  return url, nil
end

function M.get_create_details()
  return {
    filename = vim.fn.expand("%:t"),
    description = "",
    is_private = gist.config.platforms["0x0"].private or false,
  }
end

return M
