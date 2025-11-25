local utils = require("gist.core.utils")
local M = {}

--- Creates a Github gist with the specified filename and description
--
-- @param filename string The filename of the Gist
-- @param content string|nil The content of the Gist
-- @param description string The description of the Gist
-- @param private boolean Wether the Gist should be private
-- @return string|nil The URL of the created Gist
-- @return number|nil The error of the command
function M.create_gist(filename, content, description, private)
    local public_flag = private and "" or "--public"
    description = vim.fn.shellescape(description)

    local config = require("gist").config
    local cmd

    -- split the gh_cmd into components to handle wrappers properly
    local cmd_parts = vim.split(config.gh_cmd, " ")
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

    local ans =
        vim.fn.input("Do you want to create gist " .. filename .. " (y/n)? ")
    if ans ~= "y" then
        vim.cmd.redraw()
        vim.notify("Gist creation aborted", vim.log.levels.INFO)
        return
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
function M.list_gists()
    local config = require("gist").config
    -- create a command that properly handles command wrappers
    local cmd_parts = vim.split(config.gh_cmd, " ")
    local cmd = table.concat(cmd_parts, " ") .. " gist list"

    -- Add limit if configured
    if config.list.limit and type(config.list.limit) == "number" and config.list.limit > 0 then
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

return M
