local core = require("gist.core.services")
local utils = require("gist.core.utils")

local M = {}

local function create_readonly_buffer(gist)
    vim.cmd.tabnew()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    -- Set buffer to be readonly
    vim.api.nvim_set_option_value("readonly", true, { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_buf_set_name(
        buf,
        string.format("gist://%s/%s", gist.hash, gist.name)
    )

    -- Set winbar
    local winbar = string.format("%%=GIST `%s` [READ-ONLY]", gist.name)
    vim.api.nvim_set_option_value("winbar", winbar, { win = win })

    local extension = gist.name:match("^.+%.(.+)$")
    if extension then
        vim.api.nvim_set_option_value("filetype", extension, { buf = buf })
    end

    return buf
end

--- List user gists and edit them on the fly.
function M.gists()
    local config = require("gist").config
    local multiplexer = utils.detect_multiplexer()
    local has_mux = config.list.use_multiplexer and multiplexer

    if
        pcall(require, "unception")
        and not vim.g.unception_block_while_host_edits
    then
        print(
            "You need to set this option `:h g:unception_block_while_host_edits`"
        )
        return
    end

    local list = core.list()

    if list == nil then
        print(string.format("Platform %s not supported", config.platform))
        return
    end

    if #list == 0 then
        print(
            "No gists. You can create one from current buffer with `GistCreate`"
        )
        return
    end

    local platform_prefix = string.format("[%s]", string.upper(config.platform))

    local listPrompt =
        string.format("%s Select a file to edit", platform_prefix)

    if not has_mux or config.list.read_only then
        listPrompt = string.format(
            "%s Select a file to view (read-only)",
            platform_prefix
        )
    end

    vim.ui.select(list, {
        prompt = listPrompt,
        format_item = core.format,
    }, function(gist)
        if not gist then
            return
        end

        -- Check if we should use multiplexer
        if has_mux and not config.list.read_only then
            local command = core.get_edit_cmd(gist.hash)

            local mux_cmd =
                utils.create_multiplexer_command(multiplexer, command)
            if mux_cmd then
                vim.fn.system(mux_cmd)
                print(string.format("Opening in %s tab", multiplexer))
                return
            end
        end

        -- Fallback: use read-only buffer with gist view
        local content = core.fetch_content(gist.hash)
        if content then
            local buf = create_readonly_buffer(gist)
            -- Temporarily make buffer modifiable to set content
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            vim.api.nvim_buf_set_lines(
                buf,
                0,
                -1,
                false,
                vim.split(content, "\n")
            )
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            print("Opened in read-only buffer")
        else
            print("Failed to fetch content")
        end
    end)
end

return M
