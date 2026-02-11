local utils = require("gist.utils")

local M = {}

M._initialized = false

--- Check if setup() has been called
---@return boolean
function M.is_initialized()
    return M._initialized
end

---@alias Gist.Platform "github" | "gitlab" | "0x0" | "termbin" | "sourcehut" | "pastecn"

---@class Gist.Prompts.Create
---@field private boolean
---@field description boolean?
---@field confirmation boolean?

---@class Gist.Platforms.Github
---@field private boolean
---@field cmd string?
---@field list { limit: number|nil, read_only: boolean? } | nil
---@field prompts { create: Gist.Prompts.Create? } | nil

---@class Gist.Platforms.Gitlab
---@field private boolean
---@field cmd string?

---@class Gist.Platforms.Termbin
---@field url string |  nil
---@field port integer?

---@class Gist.Platforms.Sourcehut
---@field cmd string?
---@field visibility "private" | "public" | "unlisted" | nil

---@class Gist.Platforms.0x0
---@field private boolean
---@field url string?

---@class Gist.Platforms.Pastecn
---@field private boolean
---@field url string?
---@field type string?
---@field password string?

---@class Gist.Config
---@field clipboard string?
---@field split_direction "horizontal" | "vertical" | nil
---@field platform Gist.Platform | nil
---@field prompts { create: Gist.Prompts.Create? }?
---@field platforms { github: Gist.Platforms.Github?, gitlab: Gist.Platforms.Gitlab?, termbin: Gist.Platforms.Termbin?, ['0x0']: Gist.Platforms.0x0?, sourcehut: Gist.Platforms.Sourcehut?, pastecn: Gist.Platforms.Pastecn? }?
---@field list { use_multiplexer: boolean?, mappings: { next_file: string?, prev_file: string? } }?

---@type Gist.Config
local defaults = {
    clipboard = "+",
    split_direction = "vertical",
    platform = "github", -- Default backend to use
    prompts = {
        create = {
            private = false, -- Prompt for private/public when creating an entry
            description = false, -- Prompt for description when creating an entry
            confirmation = false, -- Prompt for confirmation when creating an entry
        },
    },
    -- list is not supported by all the platforms
    platforms = {
        github = {
            private = false,
            cmd = "gh",
            list = {
                limit = nil, -- Limit the number of gists fetched (default: nil, uses gh default of 10)
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
        ["0x0"] = {
            private = false,
        },
        pastecn = {
            private = false,
            url = "https://pastecn.com",
            type = "file",
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

---@param platform string
local function is_valid_platform(platform)
    local valid_platforms = {
        github = true,
        gitlab = true,
        termbin = true,
        sourcehut = true,
        ["0x0"] = true,
        pastecn = true,
    }

    if not valid_platforms[platform] then
        return false
    end

    return true
end

---@alias Gist.PlatformConfig Gist.Platforms.Gitlab | Gist.Platforms.Github | Gist.Platforms.Sourcehut | Gist.Platforms.Sourcehut | Gist.Platforms.Termbin | Gist.Platforms.0x0 | Gist.Platforms.Pastecn

---@param platform Gist.Platform
---@return Gist.PlatformConfig
function M.get_config(platform)
    if not is_valid_platform(platform) then
        error(string.format("invalid platform: '%s'", platform))
    end

    return M.config.platforms[platform]
end

---@param opts Gist.Config
function M.setup(opts)
    M.config = utils.merge_defaults(defaults, opts)

    -- Validate platform
    local valid_platforms = {
        github = true,
        gitlab = true,
        termbin = true,
        sourcehut = true,
        ["0x0"] = true,
        pastecn = true,
    }

    if not valid_platforms[M.config.platform] then
        vim.notify(
            "Gist: Invalid platform '"
                .. tostring(M.config.platform)
                .. "'. Falling back to 'github'.",
            vim.log.levels.WARN
        )
        M.config.platform = "github"
    end

    M._initialized = true

    return M.config
end

return M
