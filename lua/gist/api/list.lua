local core = require("gist.core.gh")

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

        local job_id

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

        local buf = create_tab_terminal(command)

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
                    if not data or #data == 0 or not vim.api.nvim_buf_is_valid(buf) then
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

                        local winbar = ("%sGIST `%s`"):format("%=", gist.name)
                        vim.api.nvim_win_set_option(
                            vim.fn.win_getid(),
                            "winbar",
                            winbar
                        )
                    end
                    if gist.files > 1 and changed then
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
                    if not data or #data == 0 or not vim.api.nvim_buf_is_valid(buf) then
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
