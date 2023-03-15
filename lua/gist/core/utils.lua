local M = {}

local function is_visual()
	if vim.fn.mode() ~= "v" and vim.fn.mode() ~= "V" and vim.fn.mode() ~= "<C-V>" then
		return false
	end

	return true
end

function M.get_current_selection(start_line, end_line)
	local bufnr = vim.api.nvim_get_current_buf()

	start_line = start_line - 1 -- Convert to 0-based line number
	end_line = end_line - 1 -- Convert to 0-based line number

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

	return table.concat(lines, "\n")
end

function M.get_last_selection()
	local bufnr = vim.api.nvim_get_current_buf()

	-- Save the current cursor position
	local saved_cursor = vim.api.nvim_win_get_cursor(0)

	-- Get the start and end positions of the visual selection
	vim.cmd("normal! gv")
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Restore the cursor position
	vim.api.nvim_win_set_cursor(0, saved_cursor)

	local start_line = start_pos[2] - 1
	local end_line = end_pos[2]
	local content_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
	local content = table.concat(content_lines, "\n")

	return content
end

local function read_file(path)
	local file = io.open(path, "rb") -- r read mode and b binary mode
	if not file then
		return nil
	end
	local content = file:read("*a") -- *a or *all reads the whole file
	file:close()
	return content
end

function M.exec(cmd, stdin)
	print(string.format("Executing: %s", cmd))
	local tmp = os.tmpname()

	local pipe = io.popen(cmd .. "> " .. tmp, "w")

	if not pipe then
		return nil
	end

	if stdin then
		pipe:write(stdin)
	end

	pipe:close()

	local output = read_file(tmp)
	os.remove(tmp)

	return output
end

function M.extract_gist_url(output)
	local pattern = "https://gist.github.com/%S+"

	return output:match(pattern)
end

return M
