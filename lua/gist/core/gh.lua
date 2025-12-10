local utils = require("gist.core.utils")
local gist = require("gist")

local M = {}

-- Creates a Github gist with the specified filename and description
---@param filename string The filename of the Gist
---@param content string? The content of the Gist
---@param description string The description of the Gist
---@param private boolean Wether the Gist should be private
---@return string? The URL of the created Gist
---@return number? The error of the command
function M.create(filename, content, description, private)
  local public_flag = private and "" or "--public"
  description = vim.fn.shellescape(description)

  ---@type Gist.Platforms.Github
  local config = gist.config.platforms.github
  ---@type Gist.Prompts.Create
  local prompts = config.prompts.create

  local cmd

  -- split the cmd into components to handle wrappers properly
  local cmd_parts = vim.split(config.cmd, " ")
  local base_cmd = table.concat(cmd_parts, " ")

  if content ~= nil then
    filename = vim.fn.shellescape(filename)
    cmd = string.format(
      "%s gist create -f %s -d %s %s",
      base_cmd,
      filename,
      description,
      public_flag
    )
  else
    -- expand filepath if no content is provided
    cmd = string.format(
      "%s gist create %s %s --filename %s -d %s",
      base_cmd,
      vim.fn.expand("%"),
      public_flag,
      filename,
      description
    )
  end

  if prompts.confirmation then
    local ans = vim.fn.input(M.prompts.confirmation .. " (y/n): ")

    if ans:lower() ~= "y" then
      vim.cmd.redraw()
      vim.notify("Gist creation aborted", vim.log.levels.INFO)
      return
    end
  end

  local output = utils.exec(cmd, content)

  if vim.v.shell_error ~= 0 then
    return output, vim.v.shell_error
  end

  local url = utils.extract_gist_url(output)

  return url, nil
end

--- List all Github gists
--
-- @return [string]|nil The URLs of all the Gists
function M.list()
  ---@type Gist.Platforms.Github
  local config = gist.config.platforms.github

  -- create a command that properly handles command wrappers
  local cmd_parts = vim.split(config.cmd, " ")
  local cmd = table.concat(cmd_parts, " ") .. " gist list"

  -- Add limit if configured
  if
      config.list.limit
      and type(config.list.limit) == "number"
      and config.list.limit > 0
  then
    cmd = cmd .. " --limit " .. math.floor(config.list.limit)
  end

  local output = utils.exec(cmd)
  if type(output) == "string" then
    local list = {}

    local gists = vim.split(output, "\n")
    table.remove(gists, #gists)

    for _, gist in ipairs(gists) do
      local g = vim.split(gist, "\t")

      if #g >= 5 then
        local files_str = g[3]:match("%d+")
        table.insert(list, {
          hash = g[1],
          name = g[2],
          files = files_str and tonumber(files_str) or 0,
          privacy = g[4],
          date = g[5],
        })
      end
    end
    return list
  end
end

-- @param hash string The hash of the gist to edit
function M.get_edit_cmd(hash)
  ---@type Gist.Platforms.Github
  local config = gist.config.platforms.github

  local command
  if config.cmd:find(" ") then
    -- for complex commands with spaces, use a shell to interpret it
    command = {
      "sh",
      "-c",
      string.format("%s gist edit %s", config.cmd, hash),
    }
  else
    -- for simple commands without spaces, use the array approach
    command = { config.cmd, "gist", "edit", hash }
  end

  return command
end

-- @param hash string The hash of the gist to edit
function M.fetch_content(hash)
  ---@type Gist.Platforms.Github
  local config = gist.config.platforms.github

  local cmd_parts = vim.split(config.cmd, " ")
  local cmd = table.concat(cmd_parts, " ") .. " gist view -r " .. hash

  local output = utils.exec(cmd)
  return output
end

function M.format(g)
  return string.format(
    "%s (%s) |%s 📃| [%s]",
    g.name, -- Gist name
    g.hash, -- Gist hash
    g.files, -- Gist files number
    g.privacy == "public" and "➕" or "➖" -- Gist privacy setting (public/private)
  )
end

function M.get_create_details(ctx)
  ---@type Gist.Platforms.Github
  local config = gist.config.platforms.github

  ---@type Gist.Prompts.Create
  local prompts = config.prompts.create

  local filename = vim.fn.expand("%:t")
  local description = ""
  if prompts.description then
    description = ctx.description
        or vim.fn.input(M.prompts.description .. ": ")
  end

  local is_private

  if ctx.public ~= nil then
    is_private = not ctx.public
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
  private = "Create a private Gist?",
  confirmation = "Are you sure you want to create this Gist?",
}

return M
