local utils = require("gist.core.utils")
local core = require("gist.core.gh")

local M = {}

local function get_details(default_description)
	local config = core.read_config()

	local filename = vim.fn.expand("%:t")
	local description = default_description or vim.fn.input("Gist description: ")
	local is_private = config.is_private or vim.fn.input("Create a private Gist? (y/n): ") == "y"

	return {
		filename = filename,
		description = description,
		is_private = is_private,
	}
end

local function create(content, desc)
	local config = core.read_config()
	local details = get_details(desc)

	local url, err = core.create_gist(details.filename, content, details.description, details.is_private)

	if err ~= nil then
		vim.api.nvim_err_writeln("Error creating Gist: " .. err)
	else
		vim.api.nvim_echo({ { "URL (copied to clipboard): " .. url, "Identifier" } }, true, {})
		vim.fn.setreg(config.clipboard, url)
	end
end

--- Creates a Gist from the current selection
function M.create(opts)
	local content = nil

	local start_line = opts.line1
	local end_line = opts.line2
	local description = opts.fargs[1]

	if start_line ~= end_line then
		content = utils.get_current_selection(start_line, end_line)
	end

	return create(content, description)
end

--- Creates a Gist from the current file.
function M.create_from_file(opts)
	local description = opts.fargs[1]

	create(nil, description)
end

return M
