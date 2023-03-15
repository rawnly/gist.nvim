local M = {}

--- Creates a Github gist with the specified filename and description
--
-- @param filename string The filename of the Gist
-- @param description string The description of the Gist
-- @param private boolean Wether the Gist should be private
-- @return string|nil The URL of the created Gist
-- @return number|nil The error of the command
function M.create_gist(filename, description, private)
	local public_flag = private and "" or "--public"
	local escaped_description = vim.fn.shellescape(description)

	local cmd = string.format(
		"gh gist create %s %s --filename %s -d %s",
		vim.fn.expand("%"),
		public_flag,
		filename,
		escaped_description
	)

	local handle = io.popen(cmd)

	-- null check on handle
	if handle == nil then
		return nil
	end

	local output = handle:read("*a")
	handle:close()

	if vim.v.shell_error ~= 0 then
		return output, vim.v.shell_error
	end

	local url = string.gsub(output, "\n", "")

	return url, nil
end

--- Reads the configuration from the user's vimrc
-- @return table A table with the configuration properties
function M.read_config()
	local ok, values = pcall(vim.api.nvim_get_var, { "gist_is_private", "gist_clipboard" })

	local is_private = ok and values[1] or false
	local clipboard = ok and values[2] or "+"

	local config = {
		is_private = is_private,
		clipboard = clipboard,
	}

	return config
end

return M
