local M = {}

M.config = {
    private = false,
    clipboard = "+",
    split_direction = "vertical",
    platform = "github", -- Default backend to use
    -- list is not supported by all the platforms
    platforms = {
        github = {
            cmd = "gh",
            list = {
                limit = nil,       -- Limit the number of gists fetched (default: nil, uses gh default of 10)
                read_only = false, -- Opens the given gists in read-only buffers. This option is ignored if use_multiplexer is `false`
            },
        },
        termbin = {
            url = "termbin.com",
            port = 9999,
        },
    },
    list = {
        use_multiplexer = true, -- Use terminal multiplexer (tmux/zellij) if detected
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
