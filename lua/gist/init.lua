local utils = require("gist.core.utils")
local core = require("gist.core.gh")

local M = {}

function M.create(start_line, end_line)
	local config = core.read_config()
	local content = nil

	if start_line ~= end_line then
		content = utils.get_current_selection(start_line, end_line)
	end

	local filename = vim.fn.expand("%:t")
	local description = vim.fn.input("Gist description: ")
	local is_private = config.is_private or vim.fn.input("Create a private Gist? (y/n): ") == "y"

	local url, err = core.create_gist(filename, content, description, is_private)

	if err ~= nil then
		vim.api.nvim_err_writeln("Error creating Gist: " .. err)
	else
		vim.api.nvim_echo({ { "URL (copied to clipboard): " .. url, "Identifier" } }, true, {})
		vim.fn.setreg(config.clipboard, url)
	end
end

return M
