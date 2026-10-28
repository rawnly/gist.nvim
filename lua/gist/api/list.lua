local core = require("gist.core.services")

local M = {}

---@param hash string
---@param filename string
---@param read_only boolean
---@return number? bufnr
local function create_gist_buffer(hash, filename, read_only)
    local content = core.fetch_content(hash, filename)
    if not content then
        return nil
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(
        buf,
        string.format("gist://%s/%s", hash, filename)
    )

    local lines = vim.split((content:gsub("\n$", "")), "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local filetype = vim.filetype.match({ filename = filename, buf = buf })
    if filetype then
        vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
    end

    if read_only then
        vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
        vim.api.nvim_set_option_value("readonly", true, { buf = buf })
        return buf
    end

    -- `acwrite` makes `:w` trigger BufWriteCmd instead of writing to disk
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    vim.api.nvim_set_option_value("modified", false, { buf = buf })
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            local text = table.concat(
                vim.api.nvim_buf_get_lines(buf, 0, -1, false),
                "\n"
            )
            local ok, err = core.update(hash, filename, text .. "\n")

            if not ok then
                vim.notify(
                    string.format(
                        "gist.nvim: failed to update `%s`: %s",
                        filename,
                        err or ""
                    ),
                    vim.log.levels.ERROR
                )
                return
            end

            vim.api.nvim_set_option_value("modified", false, { buf = buf })
            vim.notify(
                string.format("gist.nvim: updated `%s`", filename),
                vim.log.levels.INFO
            )
        end,
    })

    return buf
end

--- Open every file of a gist in a new tab, one buffer per file.
---@param gist table
---@param read_only boolean
local function open_gist(gist, read_only)
    local mappings = require("gist").config.list.mappings or {}
    local files = core.list_files(gist.hash)
    if not files or #files == 0 then
        files = { gist.name }
    end

    local bufs = {}
    for _, filename in ipairs(files) do
        local buf = create_gist_buffer(gist.hash, filename, read_only)
        if not buf then
            vim.notify(
                string.format("gist.nvim: failed to fetch `%s`", filename),
                vim.log.levels.ERROR
            )
            return
        end
        bufs[#bufs + 1] = buf
    end

    vim.cmd.tabnew()
    local win = vim.api.nvim_get_current_win()
    local tabbuf = vim.api.nvim_get_current_buf()
    local current = 1

    local function show(index)
        current = (index - 1) % #bufs + 1
        vim.api.nvim_win_set_buf(win, bufs[current])

        local winbar = string.format("%%=GIST `%s`", files[current])
        if #bufs > 1 then
            winbar = winbar .. string.format(" (%d/%d)", current, #bufs)
        end
        if read_only then
            winbar = winbar .. " [READ-ONLY]"
        end
        vim.api.nvim_set_option_value("winbar", winbar, { win = win })
    end

    show(1)

    -- tabnew left an empty scratch buffer behind
    if vim.api.nvim_buf_is_valid(tabbuf) then
        vim.api.nvim_buf_delete(tabbuf, { force = true })
    end

    if #bufs > 1 then
        for _, buf in ipairs(bufs) do
            if mappings.next_file then
                vim.keymap.set("n", mappings.next_file, function()
                    show(current + 1)
                end, { buffer = buf, desc = "Next gist file" })
            end
            if mappings.prev_file then
                vim.keymap.set("n", mappings.prev_file, function()
                    show(current - 1)
                end, {
                    buffer = buf,
                    desc = "Previous gist file",
                })
            end
        end
    end
end

--- List user gists and edit them on the fly.
function M.gists()
    local gist = require("gist")

    if not gist.is_initialized() then
        vim.notify(
            "gist.nvim: setup() must be called before using this plugin",
            vim.log.levels.ERROR
        )
        return
    end

    local config = gist.config
    local platform_config = config.platforms[config.platform] or {}
    local read_only = (platform_config.list or {}).read_only == true

    local list, per_page = core.list(1)

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
    local action = read_only and "view (read-only)" or "edit"
    local page = 1
    local more = { more = true }
    -- a full page means there may be another one
    local has_more = per_page ~= nil and #list >= per_page

    -- Next page, fetched in the background while the picker is open, so that
    -- "load more" doesn't leave the editor without a picker while waiting.
    -- `nil` = not requested/ready yet, `false` = failed
    local prefetched
    local fetching = false
    local on_prefetch

    local function prefetch()
        fetching = true
        core.list_async(page + 1, function(items)
            fetching = false
            prefetched = items or false

            if on_prefetch then
                local continue = on_prefetch
                on_prefetch = nil
                continue()
            end
        end)
    end

    local select

    local function load_more()
        local next_page = prefetched
        prefetched = nil

        if not next_page then
            vim.notify(
                "gist.nvim: failed to load more gists",
                vim.log.levels.ERROR
            )
            return select()
        end

        page = page + 1
        vim.list_extend(list, next_page)
        has_more = #next_page >= per_page
        select()
    end

    select = function()
        if has_more and not fetching and prefetched == nil then
            prefetch()
        end

        local items = vim.list_extend({}, list)
        if has_more then
            items[#items + 1] = more
        end

        vim.ui.select(items, {
            prompt = string.format(
                "%s Select a file to %s",
                platform_prefix,
                action
            ),
            format_item = function(item)
                if item == more then
                    return "… load more"
                end
                return core.format(item)
            end,
        }, function(selected)
            if selected == more then
                if prefetched ~= nil then
                    load_more()
                else
                    vim.notify("gist.nvim: loading more gists…")
                    on_prefetch = load_more
                end
            elseif selected then
                on_prefetch = nil
                open_gist(selected, read_only)
            end
        end)
    end

    select()
end

return M
