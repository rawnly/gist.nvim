local M = {}

M.config = {
	private = false,
	clipboard = "+",
	list = {
		mappings = {
			next_file = "<C-n>",
			prev_file = "<C-p>"
		}
	}
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend('force', M.config, opts or {})
	return M.config
end

return M
