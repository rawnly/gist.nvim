local M = {}

M.config = {
    clipboard = "+",
    split_direction = "vertical",
    platform = "github", -- Default backend to use
    prompts = {
        create = {
            private = true,      -- Prompt for private/public when creating an entry
            description = true,  -- Prompt for description when creating an entry
            confirmation = true, -- Prompt for confirmation when creating an entry
        },
    },
    -- list is not supported by all the platforms
    platforms = {
        github = {
            private = false,
            cmd = "gh",
            list = {
                limit = nil,       -- Limit the number of gists fetched (default: nil, uses gh default of 10)
                read_only = false, -- Opens the given gists in read-only buffers. This option is ignored if use_multiplexer is `false`
            },
        },
        gitlab = {
            cmd = "glab",
            private = true, -- Create personal snippets by default
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
