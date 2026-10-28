local utils = require("gist.core.utils")
local gist = require("gist")

local M = {}

--- The configured `gh` command (may be a wrapper, e.g. `op plugin run -- gh`)
---@return string
function M.cmd()
    return gist.config.platforms.github.cmd
end

-- Creates a Github gist with the specified filename and description
---@param filename string The filename of the Gist
---@param content string? The content of the Gist
---@param description string The description of the Gist
---@param private boolean Wether the Gist should be private
---@return string? The URL of the created Gist
---@return number? The error of the command
function M.create(filename, content, description, private)
    local public_flag = private and "" or "--public"
    description = vim.fn.shellescape(description)

    ---@type Gist.Platforms.Github
    local config = gist.config.platforms.github
    ---@type Gist.Prompts.Create
    local prompts = config.prompts and config.prompts.create or {}

    local cmd

    -- split the cmd into components to handle wrappers properly
    local cmd_parts = vim.split(config.cmd, " ")
    local base_cmd = table.concat(cmd_parts, " ")

    if content ~= nil then
        filename = vim.fn.shellescape(filename)
        cmd = string.format(
            "%s gist create -f %s -d %s %s",
            base_cmd,
            filename,
            description,
            public_flag
        )
    else
        -- expand filepath if no content is provided
        cmd = string.format(
            "%s gist create %s %s --filename %s -d %s",
            base_cmd,
            vim.fn.shellescape(vim.fn.expand("%")),
            public_flag,
            vim.fn.shellescape(filename),
            description
        )
    end

    if prompts.confirmation then
        local ans = vim.fn.input(M.prompts.confirmation .. " (y/n): ")

        if ans:lower() ~= "y" then
            vim.cmd.redraw()
            vim.notify("Gist creation aborted", vim.log.levels.INFO)
            return
        end
    end

    local output, exit_code = utils.exec(cmd, content)

    if exit_code ~= 0 then
        return output, exit_code
    end

    if not output then
        return nil, "No output from gh"
    end

    local url = utils.extract_gist_url(output)

    return url, nil
end

---@param page number?
---@return string cmd Command fetching one page of gists
---@return number per_page
local function list_cmd(page)
    ---@type Gist.Platforms.Github
    local config = gist.config.platforms.github
    local list_config = config.list or {}

    local per_page = 30
    if type(list_config.limit) == "number" and list_config.limit > 0 then
        per_page = math.min(math.floor(list_config.limit), 100)
    end

    local cmd = string.format(
        "%s api %s",
        M.cmd(),
        vim.fn.shellescape(
            string.format("gists?per_page=%d&page=%d", per_page, page or 1)
        )
    )

    return cmd, per_page
end

---@param output string? JSON returned by the gists API
---@return table[]? gists nil if the output is not a gist list
local function parse_list(output)
    local ok, gists = pcall(vim.json.decode, output or "")
    if not ok or type(gists) ~= "table" then
        return nil
    end

    local list = {}
    for _, g in ipairs(gists) do
        local filenames = vim.tbl_keys(g.files or {})
        table.sort(filenames)

        table.insert(list, {
            hash = g.id,
            -- same as `gh gist list`: the description, else the first file
            name = (g.description and g.description ~= "") and g.description
                or filenames[1]
                or g.id,
            files = #filenames,
            privacy = g.public and "public" or "secret",
            date = g.updated_at,
        })
    end

    return list
end

--- List one page of Github gists, most recently updated first
---@param page number? The page to fetch, starting at 1
---@return table[]? gists The gists of the page, nil on failure
---@return number? per_page The page size, so callers can tell whether more pages exist
function M.list(page)
    local cmd, per_page = list_cmd(page)
    local output, exit_code = utils.exec(cmd)
    if exit_code ~= 0 then
        return nil
    end

    local list = parse_list(output)
    if not list then
        return nil
    end

    return list, per_page
end

--- Like `list`, but without blocking the editor
---@param page number The page to fetch, starting at 1
---@param callback fun(gists: table[]?) Called on the main loop, with nil on failure
function M.list_async(page, callback)
    local cmd = list_cmd(page)

    vim.system(
        { "sh", "-c", cmd },
        { text = true },
        vim.schedule_wrap(function(result)
            callback(result.code == 0 and parse_list(result.stdout) or nil)
        end)
    )
end

--- List the file names of a gist
---@param hash string The hash of the gist
---@return string[]? files The file names, nil on failure
function M.list_files(hash)
    local cmd = string.format("%s gist view %s --files", M.cmd(), hash)
    local output, exit_code = utils.exec(cmd)

    if exit_code ~= 0 or not output then
        return nil
    end

    return vim.split(vim.trim(output), "\n", { trimempty = true })
end

--- Fetch the raw content of a gist
---@param hash string The hash of the gist
---@param filename string? The file to fetch, defaults to the gist's only/first file
---@return string? content
function M.fetch_content(hash, filename)
    local cmd = string.format("%s gist view -r %s", M.cmd(), hash)
    if filename then
        cmd = cmd .. " -f " .. vim.fn.shellescape(filename)
    end

    local output, exit_code = utils.exec(cmd)
    if exit_code ~= 0 then
        return nil
    end

    return output
end

--- Replace the content of a file in an existing gist
---@param hash string The hash of the gist
---@param filename string The file to replace
---@param content string The new content
---@return boolean ok
---@return string? err
function M.update(hash, filename, content)
    local tmp = utils.write_tmp(content)
    if not tmp then
        return false, "Failed to write temporary file"
    end

    local cmd = string.format(
        "%s gist edit %s -f %s %s",
        M.cmd(),
        hash,
        vim.fn.shellescape(filename),
        vim.fn.shellescape(tmp)
    )
    local output, exit_code = utils.exec(cmd)
    os.remove(tmp)

    if exit_code ~= 0 then
        return false, vim.trim(output or "")
    end

    return true
end

function M.format(g)
    return string.format(
        "%s (%s) |%s 📃| [%s]",
        g.name, -- Gist name
        g.hash, -- Gist hash
        g.files, -- Gist files number
        g.privacy == "public" and "➕" or "➖" -- Gist privacy setting (public/private)
    )
end

function M.get_create_details(ctx)
    ---@type Gist.Platforms.Github
    local config = gist.config.platforms.github

    ---@type Gist.Prompts.Create
    local prompts = config.prompts and config.prompts.create or {}

    local filename = utils.resolve_filename(ctx.filename)
    local description = ""
    if prompts.description then
        description = ctx.description
            or vim.fn.input(M.prompts.description .. ": ")
    end

    local is_private

    if ctx.is_public ~= nil then
        is_private = not ctx.is_public
    else
        is_private = config.private
        if prompts.private and not is_private then
            local user_input = vim.fn.input(M.prompts.private .. " (y/n): ")

            is_private = user_input:lower() == "y"
        end
    end

    return {
        filename = filename,
        description = description,
        is_private = is_private,
    }
end

M.prompts = {
    description = "Provide a description",
    private = "Create a private Gist?",
    confirmation = "Are you sure you want to create this Gist?",
}

return M
