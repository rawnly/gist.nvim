local gh = require("gist.core.gh")
local termbin = require("gist.core.termbin")
local gitlab = require("gist.core.gitlab")
local sourcehut = require("gist.core.sourcehut")

local M = {}

local function get_platform()
    local platform = require("gist").config.platform

    return platform
end

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
    else
        return nil
    end
end

function M.fetch_content(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.fetch_content(...)
    else
        return nil
    end
end

function M.format(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.format(...)
    else
        return nil
    end
end

function M.get_edit_cmd(...)
    local platform = get_platform()

    if platform == "github" then
        return gh.get_edit_cmd(...)
    else
        return nil
    end
end

function M.list()
    local platform = get_platform()

    if platform == "github" then
        return gh.list()
    else
        return nil
    end
end

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
    else
        local prompts = require("gist").config.prompts.create
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
