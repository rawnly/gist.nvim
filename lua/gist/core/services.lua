local platform = require("gist").config.platform

local gh = require("gist.core.gh")
local tb = require("gist.core.termbin")

local M = {}

function M.create(...)
    if platform == "github" then
        return gh.create(...)
    elseif platform == "termbin" then
        return tb.create(...)
    else
        error("Unsupported platform: " .. tostring(platform))
    end
end

function M.fetch_content(...)
    if platform == "github" then
        return gh.fetch_content(...)
    else
        error("Unsupported platform: " .. tostring(platform))
    end
end

function M.format(...)
    if platform == "github" then
        return gh.format(...)
    else
        error("Unsupported platform: " .. tostring(platform))
    end
end

function M.get_edit_cmd(...)
    if platform == "github" then
        return gh.get_edit_cmd(...)
    else
        error("Unsupported platform: " .. tostring(platform))
    end
end

function M.list()
    if platform == "github" then
        return gh.list()
    else
        error("Unsupported platform: " .. tostring(platform))
    end
end

return M
