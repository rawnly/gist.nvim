local utils = require("gist.core.utils")
local M = {}

--- Creates a GitLab snippet with the specified filename and description
--
-- @param filename string The filename of the snippet
-- @param content string|nil The content of the snippet
-- @param description string The description of the snippet
-- @param private boolean Whether the snippet should be private
-- @return string|nil The URL of the created snippet
-- @return number|nil The error of the command
function M.create_snippet(filename, content, description, private)
    local visibility_flag = private and "--private" or "--public"
    description = vim.fn.shellescape(description)

    local config = require("gist").config
    local cmd

    -- split the glab_cmd into components to handle wrappers properly
    local cmd_parts = vim.split(config.glab_cmd, " ")
    local base_cmd = table.concat(cmd_parts, " ")

    if content ~= nil then
        filename = vim.fn.shellescape(filename)
        cmd = string.format(
            "echo %s | %s snippet create --title %s --description %s %s",
            vim.fn.shellescape(content),
            base_cmd,
            filename,
            description,
            visibility_flag
        )
    else
        -- expand filepath if no content is provided
        cmd = string.format(
            "%s snippet create %s --title %s --description %s %s",
            base_cmd,
            vim.fn.expand("%"),
            vim.fn.shellescape(filename),
            description,
            visibility_flag
        )
    end

    local ans =
        vim.fn.input("Do you want to create snippet " .. filename .. " (y/n)? ")
    if ans ~= "y" then
        vim.cmd.redraw()
        vim.notify("Snippet creation aborted", vim.log.levels.INFO)
        return
    end

    local output = utils.exec(cmd)

    if vim.v.shell_error ~= 0 then
        return output, vim.v.shell_error
    end

    local url = utils.extract_gitlab_url(output)

    return url, nil
end

--- List all GitLab snippets
--
-- @return [string]|nil The URLs of all the snippets
function M.list_snippets()
    local config = require("gist").config
    -- create a command that properly handles command wrappers
    local cmd_parts = vim.split(config.glab_cmd, " ")
    local cmd = table.concat(cmd_parts, " ") .. " snippet list"

    -- Add limit if configured (GitLab CLI uses --per-page)
    if config.list.limit and type(config.list.limit) == "number" and config.list.limit > 0 then
        cmd = cmd .. " --per-page " .. math.floor(config.list.limit)
    end

    local output = utils.exec(cmd)
    if type(output) == "string" then
        local list = {}

        local snippets = vim.split(output, "\n")
        table.remove(snippets, #snippets)

        for _, snippet in ipairs(snippets) do
            local s = vim.split(snippet, "\t")

            table.insert(list, {
                id = s[1],
                title = s[2],
                files = 1, -- GitLab snippets typically have one file
                visibility = s[3],
                date = s[4],
            })
        end
        return list
    end
end

return M