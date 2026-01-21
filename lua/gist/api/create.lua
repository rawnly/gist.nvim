local core = require("gist.core.services")
local utils = require("gist.core.utils")

local M = {}

---@param content string
---@param ctx CreateContext
local function create(content, ctx)
  local config = require("gist").config
  local details = core.get_create_details(ctx)

  local url, err = core.create(
    details.filename,
    content,
    details.description,
    details.is_private
  )

  if err ~= nil then
    vim.notify("Error creating Gist: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if not url then
    vim.notify("Error creating Gist: no URL returned", vim.log.levels.ERROR)
    return
  end

  vim.notify("URL (copied to clipboard): " .. url, vim.log.levels.INFO)
  vim.fn.setreg(config.clipboard, url)
end

--- Creates a Gist from the current selection
function M.from_buffer(opts)
  local content = nil
  local args = utils.parseArgs(opts.args)

  local start_line = opts.line1
  local end_line = opts.line2
  local description = opts.fargs[1]

  if start_line ~= end_line then
    content = utils.get_current_selection(start_line, end_line)
  end

  return create(content, {
    description = description,
    is_public = args.public,
  })
end

--- Creates a Gist from the current file.
function M.from_file(opts)
  local args = utils.parseArgs(opts.args)
  local description = opts.fargs[1]

  create(nil, {
    description = description,
    is_public = args.public,
  })
end

return M
