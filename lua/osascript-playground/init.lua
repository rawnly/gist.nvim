local bufn = -1
local output_bufn = -1

local function open_buffer()
	if bufn == -1 then
		vim.api.nvim_command("botright vnew")
		bufn = vim.api.nvim_get_current_buf()
	end
end

local function show_output(output)
	if output_bufn == -1 then
		vim.api.nvim_command("botright new")
		output_bufn = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(output_bufn, 0, -1, false, { output })
	end
end

local function start_playground()
	open_buffer()
end

local function get_content()
	local content = vim.api.nvim_buf_get_lines(bufn, 0, vim.api.nvim_buf_line_count(0), false)
	return table.concat(content, "\n")
end

local function evaluate()
	local content = get_content()
	local output = vim.api.nvim_exec("osascript -e " + content, true)
	show_output(output)
end

vim.api.nvim_create_user_command("OPlaygroundOpen", start_playground, {
	bang = true,
	desc = "spawn a new playground",
})

vim.api.nvim_create_user_command("OPlaygroundRun", evaluate, {
	bang = true,
	desc = "spawn a new playground",
})

return {}
