local utils = require("gist.core.utils")
local gist = require("gist")

local M = {}

---@param filename string|nil UNSUPPOTED
---@param content string|nil
---@param description string UNSUPPOTED
---@param private boolean UNSUPPOTED
function M.create(filename, content, description, private)
  ---@type Gist.Platforms.Termbin
  local config = gist.config.platforms.termbin

  local cmd = string.format("nc %s %d", config.url, config.port)

  local output = utils.exec(cmd, content)

  if vim.v.shell_error ~= 0 then
    return output, vim.v.shell_error
  end

  if output == nil or output == "" then
    return nil, "No output from termbin"
  end

  local pattern = string.format("https?://%s/%%S+", config.url)
  local url = output:match(pattern)

  return url, nil
end

--- Get details for creating a paste (termbin doesn't support most options)
---@return CreateDetails
function M.get_create_details()
  return {
    filename = vim.fn.expand("%:t"),
    description = "",
    is_private = false,
  }
end

return M
