local utils = require("gist.core.utils")

local M = {}

-- @param filename string UNSUPPOTED
-- @param content string|nil UNSUPPOTED
-- @param description string UNSUPPOTED
-- @param private boolean UNSUPPOTED
function M.create(_, content, _, _)
    local config = require("gist").config.platforms.termbin
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

return M
