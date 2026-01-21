local gh = require("gist.core.gh")
local termbin = require("gist.core.termbin")
local gitlab = require("gist.core.gitlab")
local sourcehut = require("gist.core.sourcehut")
local x0 = require("gist.core.0x0")
local gist = require("gist")

local M = {}

--- Get the currently configured platform
--
-- @return string The platform name (e.g., "github", "gitlab")
local function get_platform()
  local platform = require("gist").config.platform

  return platform
end

--- Create a gist on the configured platform
--
-- @param filename string The filename for the gist
-- @param content string|nil The content of the gist (optional)
-- @param description string The description of the gist
-- @param private boolean Whether the gist should be private
-- @return string|nil The URL of the created gist
-- @return number|nil Error code if creation failed
function M.create(...)
  local platform = get_platform()

  if platform == "github" then
    return gh.create(...)
  elseif platform == "gitlab" then
    return gitlab.create(...)
  elseif platform == "termbin" then
    return termbin.create(...)
  elseif platform == "sourcehut" then
    return sourcehut.create(...)
  elseif platform == "0x0" then
    return x0.create(...)
  else
    return nil
  end
end

--- Fetch the content of a gist
--
-- @param hash string The hash/ID of the gist
-- @return string|nil The content of the gist
function M.fetch_content(...)
  local platform = get_platform()

  if platform == "github" then
    return gh.fetch_content(...)
  else
    return nil
  end
end

--- Format gist information for display
--
-- @param g table Gist information table
-- @return string|nil Formatted gist string
function M.format(...)
  local platform = get_platform()

  if platform == "github" then
    return gh.format(...)
  else
    return nil
  end
end

--- Get the command to edit a gist
--
-- @param hash string The hash/ID of the gist to edit
-- @return table|nil Command array for editing the gist
function M.get_edit_cmd(...)
  local platform = get_platform()

  if platform == "github" then
    return gh.get_edit_cmd(...)
  else
    return nil
  end
end

--- List gists from the configured platform
--
-- @return table|nil Array of gist information tables
function M.list()
  local platform = get_platform()

  if platform == "github" then
    return gh.list()
  else
    return nil
  end
end

--- Get details for creating a gist
--
---@param ctx CreateContext Context containing description and public/private settings
---@return table Details with filename, description, and is_private fields
function M.get_create_details(ctx)
  local platform = get_platform()

  if platform == "github" then
    return gh.get_create_details(ctx)
  elseif platform == "termbin" then
    return termbin.get_create_details()
  elseif platform == "gitlab" then
    return gitlab.get_create_details(ctx)
  elseif platform == "sourcehut" then
    return sourcehut.get_create_details(ctx)
  elseif platform == "0x0" then
    return x0.get_create_details()
  else
    --- @type Gist.Prompts.Create
    local prompts = gist.config.prompts.create
    local filename = vim.fn.expand("%:t")

    local description = ""
    if prompts.description then
      description = ctx.description
          or vim.fn.input("Provide a description: ")
    end

    return {
      description = description,
      filename = filename,
      is_private = true,
    }
  end
end

return M
