local gh = require("gist.core.gh")
local termbin = require("gist.core.termbin")
local gitlab = require("gist.core.gitlab")
local sourcehut = require("gist.core.sourcehut")
local x0 = require("gist.core.0x0")
local pastecn = require("gist.core.pastecn")
local utils = require("gist.core.utils")
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
    elseif platform == "pastecn" then
        return pastecn.create(...)
    else
        return nil
    end
end

--- Fetch the content of a gist
--
-- @param hash string The hash/ID of the gist
-- @param filename string|nil The file to fetch
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

--- List the file names of a gist
--
-- @param hash string The hash/ID of the gist
-- @return string[]|nil The file names
function M.list_files(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.list_files(...)
    else
        return nil
    end
end

--- Replace the content of a file in an existing gist
--
-- @param hash string The hash/ID of the gist
-- @param filename string The file to replace
-- @param content string The new content
-- @return boolean Whether the update succeeded
-- @return string|nil Error message
function M.update(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.update(...)
    else
        return false, "Platform " .. platform .. " does not support editing"
    end
end

--- List gists from the configured platform
--
-- @param page number|nil The page to fetch, starting at 1
-- @return table|nil Array of gist information tables
-- @return number|nil The page size
function M.list(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.list(...)
    else
        return nil
    end
end

--- List a page of gists without blocking
--
-- @param page number The page to fetch, starting at 1
-- @param callback function Called with the gists, or nil on failure
function M.list_async(page, callback)
    local platform = get_platform()

    if platform == "github" then
        gh.list_async(page, callback)
    else
        callback(nil)
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
    elseif platform == "pastecn" then
        return pastecn.get_create_details(ctx)
    else
        --- @type Gist.Prompts.Create
        local prompts = gist.config.prompts.create
        local filename = utils.resolve_filename(ctx.filename)

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
