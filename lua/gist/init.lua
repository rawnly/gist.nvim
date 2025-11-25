local M = {}

M.config = {
    private = false,
    clipboard = "+",
    split_direction = "vertical",
    gh_cmd = "gh",
    glab_cmd = "glab",
    default_platform = "github", -- "github" or "gitlab"
    list = {
        limit = nil, -- Limit the number of gists fetched (default: nil, uses gh default of 10)
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
