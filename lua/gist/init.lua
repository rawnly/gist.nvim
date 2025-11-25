local M = {}

M.config = {
    private = false,
    clipboard = "+",
    split_direction = "vertical",
    gh_cmd = "gh",
    list = {
        -- Limit the number of gists to fetch. When nil, uses gh's default (currently 10).
        limit = nil,
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
