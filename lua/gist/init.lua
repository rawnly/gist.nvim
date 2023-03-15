local core = require("gist.core.gh")

local M = {}

function M.create()
	local config = core.read_config()

	local filename = vim.fn.expand("%:t")
	local description = vim.fn.input("Description: ")
	local is_private = config.is_private or vim.fn.input("Create a private Gist? (y/n): ") == "y"

	local url, err = core.create_gist(filename, nil, description, is_private)

	if err ~= nil then
		vim.api.nvim_err_writeln("Error creating Gist: " .. err)
	else
		vim.api.nvim_echo({ { "URL (copied to clipboard): " .. url, "Identifier" } }, true, {})
		vim.fn.setreg(config.clipboard, url)
	end
end

return M
