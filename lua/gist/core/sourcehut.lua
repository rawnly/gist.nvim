local utils = require("gist.core.utils")
local gist  = require("gist")

local M     = {}

--- Creates a SourceHut paste with the specified filename and description
--
--- @param filename string The filename of the paste
--- @param content string|nil The content of the paste
--- @param description string The description of the paste
--- @param private boolean IGNORED - pastes are public
--- @return string|nil The URL of the created paste
--- @return number|nil The error of the command
function M.create(filename, content, description, private)
  ---@type Gist.Platforms.Sourcehut
  local config = gist.config.platforms.sourcehut
  local cmd_parts = vim.split(config.cmd, " ")

  if content == nil then
    content = utils.read_current_buffer_content()
  end

  cmd_parts[#cmd_parts + 1] = "paste"
  cmd_parts[#cmd_parts + 1] = "create"

  if filename then
    cmd_parts[#cmd_parts + 1] = "--name"
    cmd_parts[#cmd_parts + 1] = vim.fn.shellescape(filename)
  end

  if config.visibility and config.visibility ~= "" then
    cmd_parts[#cmd_parts + 1] = "-v"
    cmd_parts[#cmd_parts + 1] = config.visibility
  end

  local cmd = table.concat(cmd_parts, " ")

  local output, exit_code = utils.exec(cmd, content)

  if exit_code ~= 0 then
    return output, exit_code
  end

  if output == nil or output == "" then
    return nil, "No output from hut"
  end

  local url = output:match("https://paste%.sr%.ht/%S+")

  return url, nil
end

---@param ctx CreateContext
---@return CreateDetails
function M.get_create_details(ctx)
  ---@type Gist.Prompts.Create
  local prompts = gist.config.prompts and gist.config.prompts.create or {}

  local filename = vim.fn.expand("%:t")

  local description = ""
  if prompts.description then
    description = ctx.description or vim.fn.input("Provide a description: ")
  end

  -- SourceHut pastes are always public
  return {
    filename = filename,
    description = description,
    is_private = false,
  }
end

return M
