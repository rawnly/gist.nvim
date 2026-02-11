local M = {}

local utils = require("gist.core.utils")
local gist = require("gist")

--- Creates a pastecn snippet with the specified filename and content
--
--- @param filename string The filename of the snippet
--- @param content string|nil The content of the snippet
--- @param description string IGNORED - pastecn does not support descriptions
--- @param private boolean Whether to password-protect the snippet
--- @return string|nil The URL of the created snippet
--- @return string|number|nil Error code or message if creation failed
function M.create(filename, content, description, private)
    ---@type Gist.Platforms.Pastecn
    local config = gist.config.platforms.pastecn
    local base_url = config.url or "https://pastecn.com"

    -- When content is nil (from_file), read the current buffer
    if content == nil then
        local lines = utils.read_buffer(vim.api.nvim_get_current_buf())
        content = table.concat(lines, "\n")
    end

    local payload = {
        name = filename or "untitled",
        type = config.type or "file",
        files = {
            {
                path = filename or "untitled",
                content = content,
            },
        },
    }

    if config.private or private then
        payload.password = config.password or ""
    end

    local json = vim.fn.json_encode(payload)
    local tmp = utils.write_tmp(json)
    if not tmp then
        return nil, "Failed to create temp file"
    end

    local cmd = {
        "curl",
        "-sS",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        "User-Agent: gist.nvim",
        "-d",
        string.format("@%s", tmp),
        base_url .. "/api/v1/snippets",
    }

    local output = utils.system(cmd, "failed to create pastecn snippet")

    os.remove(tmp)

    if output == nil or output[1] == "" then
        return nil, "No output from pastecn"
    end

    local response = vim.fn.json_decode(table.concat(output, "\n"))

    if response.code then
        return nil, response.message or response.code
    end

    local url = response.url or (base_url .. "/" .. response.id)

    return url, nil
end

---@param ctx CreateContext
---@return CreateDetails
function M.get_create_details(ctx)
    ---@type Gist.Prompts.Create
    local prompts = gist.config.prompts.create

    local filename = vim.fn.expand("%:t")

    local description = ""
    if prompts.description then
        description = ctx.description or vim.fn.input("Provide a description: ")
    end

    local is_private = false
    if prompts.private then
        local input = vim.fn.input("Make private? (y/n): ")
        is_private = input == "y" or input == "Y"
    end

    return {
        filename = filename,
        description = description,
        is_private = is_private,
    }
end

return M
