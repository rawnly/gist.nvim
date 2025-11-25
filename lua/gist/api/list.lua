local core = require("gist.core.gh")

local M = {}

local function create_split_terminal(command)
    local config = require("gist").config
    if config.split_direction == "vertical" then
        vim.cmd.vsplit()
    else
        vim.cmd.split()
    end
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

local function format_item(g, platform)
    if platform == "github" then
        return string.format(
            "%s (%s) |%s 📃| [%s]",
            g.name, -- Gist name
            g.hash, -- Gist hash
            g.files, -- Gist files number
            g.privacy == "public" and "➕" or "➖" -- Gist privacy setting (public/private)
        )
    elseif platform == "gitlab" then
        return string.format(
            "%s (%s) |%s 📄| [%s]",
            g.title, -- Snippet title
            g.id, -- Snippet ID
            g.files, -- Snippet files number
            g.visibility == "public" and "➕" or "➖" -- Snippet visibility (public/private)
        )
    end
end

--- List user gists/snippets and edit them on the fly.
function M.gists(opts)
    local config = require("gist").config
    local args = opts and utils.parseArgs(opts.args) or {}
    local platform = args.platform or config.default_platform

    if
        pcall(require, "unception")
        and not vim.g.unception_block_while_host_edits
    then
        print(
            "You need to set this option `:h g:unception_block_while_host_edits`"
        )
        return
    end

    local list
    if platform == "github" then
        list = core.list_gists()
    elseif platform == "gitlab" then
        local gitlab_core = require("gist.core.gitlab")
        list = gitlab_core.list_snippets()
    else
        vim.notify("Unsupported platform: " .. platform, vim.log.levels.ERROR)
        return
    end

    if not list or #list == 0 then
        local item_name = platform == "github" and "gists" or "snippets"
        print(
            "No " .. item_name .. ". You can create one from current buffer with `GistCreate`"
        )
        return
    end

    vim.ui.select(list, {
        prompt = "Select a " .. (platform == "github" and "gist" or "snippet") .. " to edit",
        format_item = function(g) return format_item(g, platform) end,
    }, function(item)
        if not item then
            return
        end

        local job_id

        -- handle command construction a little differently based on command
        -- complexity.  there's probably a better way to do this, but this seems
        -- reasonably robust.
        local command
        if platform == "github" then
            if config.gh_cmd:find(" ") then
              -- for complex commands with spaces, use a shell to interpret it
              command = {"sh", "-c", string.format("%s gist edit %s", config.gh_cmd, item.hash)}
            else
              -- for simple commands without spaces, use the array approach
              command = {config.gh_cmd, "gist", "edit", item.hash}
            end
        elseif platform == "gitlab" then
            -- GitLab snippets don't have an interactive edit command like GitHub gists
            -- We'll open the snippet in the browser for editing
            local url = string.format("https://gitlab.com/-/snippets/%s", item.id)
            local open_cmd = vim.fn.has("mac") == 1 and "open" or (vim.fn.has("unix") == 1 and "xdg-open" or "start")
            vim.fn.jobstart({open_cmd, url})
            vim.notify("Opened snippet in browser for editing", vim.log.levels.INFO)
            return
        end

        local buf = create_split_terminal(command)

        local term_chan_id = vim.api.nvim_open_term(buf, {
            on_input = function(_, _, _, data)
                vim.api.nvim_chan_send(job_id, data)
            end,
        })

        job_id = vim.fn.jobstart(
            command,
            vim.tbl_extend("force", {
                on_stdout = function(_, data)
                    -- check if data is empty or contains only empty strings
                    if not data or #data == 0 then
                        return
                    end

                    -- filter out empty trailing entries which are common in jobstart output
                    local last_idx = #data
                    while last_idx > 0 and data[last_idx] == "" do
                        last_idx = last_idx - 1
                    end

                    if last_idx == 0 then
                        return
                    end -- All entries were empty

                    -- create a new filtered table with only non-empty entries
                    local filtered_data = {}
                    for i = 1, last_idx do
                        table.insert(filtered_data, data[i])
                    end

                    vim.api.nvim_chan_send(
                        term_chan_id,
                        table.concat(filtered_data, "\r\n") .. "\r\n"
                    )

                    local changed = vim.fn.bufnr() ~= buf
                    if changed then
                        vim.api.nvim_buf_set_option(
                            vim.fn.bufnr(),
                            "bufhidden",
                            "wipe"
                        )
                        vim.api.nvim_buf_set_option(
                            vim.fn.bufnr(),
                            "swapfile",
                            true
                        )

                        local item_type = platform == "github" and "GIST" or "SNIPPET"
                        local item_name = platform == "github" and item.name or item.title
                        local winbar = ("%s%s `%s`"):format("%=", item_type, item_name)
                        vim.api.nvim_win_set_option(
                            vim.fn.win_getid(),
                            "winbar",
                            winbar
                        )
                    end
                    if item.files > 1 and changed then
                        vim.api.nvim_create_autocmd({ "BufDelete" }, {
                            buffer = vim.fn.bufnr(),
                            group = vim.api.nvim_create_augroup(
                                "gist_save",
                                {}
                            ),
                            callback = function()
                                vim.cmd.startinsert()
                            end,
                        })
                    end
                end,
                on_stderr = function(_, data)
                    -- check if data is empty or contains only empty strings
                    if not data or #data == 0 then
                        return
                    end

                    -- filter out empty trailing entries which are common in jobstart output
                    local last_idx = #data
                    while last_idx > 0 and data[last_idx] == "" do
                        last_idx = last_idx - 1
                    end

                    if last_idx == 0 then
                        return
                    end -- All entries were empty

                    -- create a new filtered table with only non-empty entries
                    local filtered_data = {}
                    for i = 1, last_idx do
                        table.insert(filtered_data, data[i])
                    end

                    vim.api.nvim_chan_send(
                        term_chan_id,
                        table.concat(filtered_data, "\r\n") .. "\r\n"
                    )
                end,
                on_exit = function(_, exit_code)
                    if exit_code ~= 0 then
                        vim.api.nvim_chan_send(
                            term_chan_id,
                            "\r\nCommand exited with code "
                            .. exit_code
                            .. "\r\n"
                        )
                    end

                    -- Don't close window immediately on error to allow seeing the error
                    local delay = exit_code ~= 0 and 3000 or 1000
                    vim.defer_fn(function()
                        vim.api.nvim_buf_delete(buf, { force = true })
                    end, delay) -- give user a chance to see any error messages
                end,
                pty = true,
            }, {})
        )
    end)
end

return M
