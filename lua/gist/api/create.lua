local core = require("gist.core.services")
local utils = require("gist.core.utils")

local M = {}

---@param content string
---@param ctx CreateContext
local function create(content, ctx)
    local gist = require("gist")

    if not gist.is_initialized() then
        vim.notify(
            "gist.nvim: setup() must be called before using this plugin",
            vim.log.levels.ERROR
        )
        return
    end

    local config = gist.config
    local details = core.get_create_details(ctx)

    local url, err = core.create(
        details.filename,
        content,
        details.description,
        details.is_private
    )

    if err ~= nil then
        vim.notify(
            "Error creating Gist: " .. tostring(err),
            vim.log.levels.ERROR
        )
        return
    end

    if not url then
        vim.notify("Error creating Gist: no URL returned", vim.log.levels.ERROR)
        return
    end

    vim.notify("URL (copied to clipboard): " .. url, vim.log.levels.INFO)
    vim.fn.setreg(config.clipboard, url)
end

--- Creates a Gist from the current buffer or selection.
function M.from_buffer(opts)
    local args = utils.parseArgs(opts.args)
    local content

    if opts.range and opts.range > 0 then
        content = utils.get_current_selection(opts.line1, opts.line2)
    else
        content = utils.read_current_buffer_content()
    end

    return create(content, {
        description = args.description,
        is_public = args.public,
        filename = args.filename,
    })
end

--- Creates a Gist from the current file.
function M.from_file(opts)
    local args = utils.parseArgs(opts.args)

    create(nil, {
        description = args.description,
        is_public = args.public,
        filename = args.filename,
    })
end

return M
