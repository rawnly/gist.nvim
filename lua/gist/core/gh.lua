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

	local cmd

	if content ~= nil then
		filename = vim.fn.shellescape(filename)
		cmd = string.format("gh gist create -f %s -d %s %s", filename, description, public_flag)
	else
		-- expand filepath if no content is provided
		cmd = string.format(
			"gh gist create %s %s --filename %s -d %s",
			vim.fn.expand("%"),
			public_flag,
			filename,
			description
		)
	end

	local ans = vim.fn.input("Do you want to create gist " .. filename .. " (y/n)? ")
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

--- Reads the configuration from the user's vimrc
--
-- @return table A table with the configuration properties
function M.read_config()
	local ok_private, private = pcall(vim.api.nvim_get_var, "gist_is_private")
	local is_private = ok_private and private or false
	local ok_clipboard, clipboard = pcall(vim.api.nvim_get_var, "gist_clipboard")
	local clipboard_reg = ok_clipboard and clipboard or "+"

	local config = {
		is_private = is_private,
		clipboard = clipboard_reg,
	}

	return config
end

return M
