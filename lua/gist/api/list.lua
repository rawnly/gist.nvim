local core = require("gist.core.gh")
local utils = require("gist.core.utils")

local M = {}

local function create_tab_terminal(command)
    local config = require("gist").config
    vim.cmd.tabnew()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)

    -- create a representative command name for the buffer
    local cmd_str
    if type(command) == "table" then
        cmd_str = table.concat(command, " ")
    else
        cmd_str = command
    end
    vim.api.nvim_buf_set_name(buf, ("term://%s/%s"):format(buf, cmd_str))
    vim.keymap.set(
        "t",
        config.list.mappings.next_file,
        "<Down>",
        { buffer = buf }
    )
    vim.keymap.set(
        "t",
        config.list.mappings.prev_file,
        "<Up>",
        { buffer = buf }
    )
    vim.api.nvim_win_set_option(win, "winbar", "%=Use CTRL-{n,p} to cycle")
    vim.cmd.startinsert()
    return buf
end

local function format_gist(g)
    return string.format(
        "%s (%s) |%s 📃| [%s]",
        g.name, -- Gist name
        g.hash, -- Gist hash
        g.files, -- Gist files number
        g.privacy == "public" and "➕" or "➖" -- Gist privacy setting (public/private)
    )
end

local function create_readonly_buffer(gist)
    vim.cmd.tabnew()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    
    -- Set buffer to be readonly
    vim.api.nvim_buf_set_option(buf, "readonly", true)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_name(buf, string.format("gist://%s/%s", gist.hash, gist.name))
    
    -- Set winbar
    local winbar = string.format("%%=GIST `%s` [READ-ONLY]", gist.name)
    vim.api.nvim_win_set_option(win, "winbar", winbar)
    
    return buf
end

local function fetch_gist_content(gist_hash)
    local config = require("gist").config
    local cmd_parts = vim.split(config.gh_cmd, " ")
    local cmd = table.concat(cmd_parts, " ") .. " gist view -r " .. gist_hash
    
    local output = utils.exec(cmd)
    return output
end

--- List user gists and edit them on the fly.
function M.gists()
    local config = require("gist").config
    if
        pcall(require, "unception")
        and not vim.g.unception_block_while_host_edits
    then
        print(
            "You need to set this option `:h g:unception_block_while_host_edits`"
        )
        return
    end

    local list = core.list_gists()
    if #list == 0 then
        print(
            "No gists. You can create one from current buffer with `GistCreate`"
        )
        return
    end

    vim.ui.select(list, {
        prompt = "Select a gist to edit",
        format_item = format_gist,
    }, function(gist)
        if not gist then
            return
        end

        -- Check if we should use multiplexer
        local multiplexer = utils.detect_multiplexer()
        if config.list.use_multiplexer and multiplexer then
            -- handle command construction a little differently based on command
            -- complexity.  there's probably a better way to do this, but this seems
            -- reasonably robust.
            local command
            if config.gh_cmd:find(" ") then
                -- for complex commands with spaces, use a shell to interpret it
                command = {
                    "sh",
                    "-c",
                    string.format("%s gist edit %s", config.gh_cmd, gist.hash),
                }
            else
                -- for simple commands without spaces, use the array approach
                command = { config.gh_cmd, "gist", "edit", gist.hash }
            end

            local mux_cmd = utils.create_multiplexer_command(multiplexer, command)
            if mux_cmd then
                vim.fn.system(mux_cmd)
                print(string.format("Opening gist in %s tab", multiplexer))
                return
            end
        end

        -- Fallback: use read-only buffer with gist view
        local content = fetch_gist_content(gist.hash)
        if content then
            local buf = create_readonly_buffer(gist)
            -- Temporarily make buffer modifiable to set content
            vim.api.nvim_buf_set_option(buf, "modifiable", true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
            vim.api.nvim_buf_set_option(buf, "modifiable", false)
            print("Opened gist in read-only buffer")
        else
            print("Failed to fetch gist content")
        end
    end)
end

return M