local core = require("gist.core.gh")
local utils = require("gist.core.utils")

local M = {}

local function get_details(ctx)
    local config = require("gist").config

    local filename = vim.fn.expand("%:t")
    local description = ctx.description or vim.fn.input("Gist description: ")

    local is_private

    if ctx.public ~= nil then
        is_private = not ctx.public
    else
        is_private = config.private
            or vim.fn.input("Create a private Gist? (y/n): ") == "y"
    end

    return {
        filename = filename,
        description = description,
        is_private = is_private,
    }
end

local function create(content, ctx)
    local config = require("gist").config
    local details = get_details(ctx)

    local url, err = core.create_gist(
        details.filename,
        content,
        details.description,
        details.is_private
    )
    if not url then
        return
    end

    if err ~= nil then
        vim.notify("Error creating Gist: " .. err, vim.log.levels.ERROR)
    else
        vim.notify("URL (copied to clipboard): " .. url, vim.log.levels.INFO)
        vim.fn.setreg(config.clipboard, url)
    end
end

--- Creates a Gist from the current selection
function M.from_buffer(opts)
    local content = nil
    local args = utils.parseArgs(opts.args)

    local start_line = opts.line1
    local end_line = opts.line2
    local description = opts.fargs[1]

    if start_line ~= end_line then
        content = utils.get_current_selection(start_line, end_line)
    end

    return create(content, {
        description = description,
        public = args.public,
    })
end

--- Creates a Gist from the current file.
function M.from_file(opts)
    local args = utils.parseArgs(opts.args)
    local description = opts.fargs[1]

    create(nil, {
        description = description,
        public = args.public,
    })
end

return M
