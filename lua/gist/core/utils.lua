local M = {}

function M.get_selection()
	local start_line, start_col = unpack(vim.fn.getpos("'<")[2])
	local end_line, end_col = unpack(vim.fn.getpos("'>")[2])

	-- selection is empty
	if start_line == end_line and start_col == end_col then
		return nil
	end

	-- selection is not empty
	local bufnr = vim.api.nvim_get_current_buf()

	start_line = start_line - 1 -- convert to 0-based line number
	end_line = end_line - 1 -- convert to 0-based line number

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

	return table.concat(lines, "\n")
end

return M
