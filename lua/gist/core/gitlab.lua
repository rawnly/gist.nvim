local utils = require("gist.core.utils")
local gist  = require("gist")

local M     = {}
--- Creates a Gitlab snippet with the specified filename and description
--
--- @param filename string
--- @param content string?
--- @param description string?
--- @param personal boolean?
function M.create(filename, content, description, personal)
  ---@type Gist.Platforms.Gitlab
  local config = gist.config.platforms.gitlab
  local is_personal = config.private or personal

  local cmd_parts = vim.split(config.cmd, " ")

  cmd_parts[#cmd_parts + 1] = "snippet"
  cmd_parts[#cmd_parts + 1] = "create"

  filename = vim.fn.shellescape(filename)
  cmd_parts[#cmd_parts + 1] = "--title " .. filename

  if content ~= nil then
    cmd_parts[#cmd_parts + 1] = "--filename " .. filename
  else
    cmd_parts[#cmd_parts + 1] = vim.fn.expand("%s")
  end

  if description ~= "" then
    description = vim.fn.shellescape(description)
    cmd_parts[#cmd_parts + 1] = "--description " .. description
  end

  if is_personal then
    cmd_parts[#cmd_parts + 1] = "--personal"
  end

  local cmd = table.concat(cmd_parts, " ")

  local output = utils.exec(cmd, content)

  if vim.v.shell_error ~= 0 then
    return output, vim.v.shell_error
  end

  if output == nil or output == "" then
    return nil, "No output from gitlab"
  end

  local url = output:match("https://gitlab%.com/%-%/snippets/%d+")

  return url, nil
end

---@param ctx CreateContext
---@return CreateDetails
function M.get_create_details(ctx)
  ---@type Gist.Platforms.Gitlab
  local config = gist.config.platforms.gitlab
  ---@type Gist.Prompts.Create
  local prompts = gist.config.prompts.create

  local filename = vim.fn.expand("%:t")

  local description = ""
  if prompts.description then
    description = ctx.description
        or vim.fn.input(M.prompts.description .. ": ")
  end

  local is_private

  if ctx.is_public ~= nil then
    is_private = not ctx.is_public
  else
    is_private = config.private
    if prompts.private and not is_private then
      local user_input = vim.fn.input(M.prompts.private .. " (y/n): ")

      is_private = user_input:lower() == "y"
    end
  end

  return {
    filename = filename,
    description = description,
    is_private = is_private,
  }
end

M.prompts = {
  description = "Provide a description",
  private = "Create a personal Snippet?",
}

return M
