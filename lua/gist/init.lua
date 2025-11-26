local M = {}

M.config = {
    clipboard = "+",
    split_direction = "vertical",
    platform = "github", -- Default backend to use
    prompts = {
        create = {
            private = false,      -- Prompt for private/public when creating an entry
            description = false,  -- Prompt for description when creating an entry
            confirmation = false, -- Prompt for confirmation when creating an entry
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
        sourcehut = {
            cmd = "hut",
            visibility = "unlisted", -- private, public, unlisted,
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

    -- Validate platform
    local valid_platforms =
    { github = true, gitlab = true, termbin = true, sourcehut = true }
    if not valid_platforms[M.config.platform] then
        vim.notify(
            "Gist: Invalid platform '"
            .. tostring(M.config.platform)
            .. "'. Falling back to 'github'.",
            vim.log.levels.WARN
        )
        M.config.platform = "github"
    end

    return M.config
end

return M
