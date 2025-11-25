local M = {}

M.config = {
    private = false,
    clipboard = "+",
    split_direction = "vertical",
    gh_cmd = "gh",
    list = {
        limit = nil, -- Limit the number of gists fetched (default: nil, uses gh default of 10)
        use_multiplexer = false, -- Use terminal multiplexer (tmux/zellij) if detected
        mappings = {
            next_file = "<C-n>",
            prev_file = "<C-p>",
        },
    },
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    return M.config
end

return M
