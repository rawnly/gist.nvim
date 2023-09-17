local core = require("gist.core.gh")
local config = require("gist").config

local M = {}

local function create_split_terminal(command)
    vim.cmd.vsplit()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)
    vim.api.nvim_buf_set_name(buf, ("term://%s/%s"):format(buf, command[1]))
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

        local command = { "gh", "gist", "edit", gist.hash }
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
                    vim.api.nvim_chan_send(
                        term_chan_id,
                        table.concat(data, "\r\n")
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
                on_exit = function()
                    vim.api.nvim_buf_delete(buf, { force = true })
                end,
                pty = true,
            }, {})
        )
    end)
end

return M
