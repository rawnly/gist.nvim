local core = require("gist.core.gh")

local M = {}

function M.create_from_file(args)
	local config = core.read_config()

	local filename = vim.fn.expand("%:t")
	local description = ""

	if args[1] ~= nil then
		description = args[1]
	end

	if description == "" or description == nil then
		vim.api.nvim_echo({
			{ "No description provided" },
		}, true, {})

		description = vim.fn.input("Description: ")
	end

	local is_private = config.is_private or vim.fn.input("Create a private Gist? (y/n): ") == "y"

	local url, err = core.create_gist(filename, nil, description, is_private)

	if err ~= nil then
		vim.api.nvim_err_writeln("Error creating Gist: " .. err)
	else
		vim.api.nvim_echo({ { "URL (copied to clipboard): " .. url, "Identifier" } }, true, {})
		vim.fn.setreg(config.clipboard, url)
	end
end

function M.create_from_selection(opts)
	vim.api.nvim_echo({
		{ "Creating Gist from selection..." .. opts.args, "Identifier" },
	}, true, {})
end

return M
