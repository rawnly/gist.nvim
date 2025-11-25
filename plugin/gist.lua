local gist = require("gist.api")

local complete = function()
    return { "description=", "public=", "platform=github", "platform=gitlab" }
end

vim.api.nvim_create_user_command("GistCreate", function(args)
    gist.create_from_buffer(args)
end, {
    nargs = "?",
    desc = "Create a Gist from the current buffer selection.",
    range = true,
    complete = complete,
})

vim.api.nvim_create_user_command("GistCreateFromFile", function(args)
    gist.create_from_file(args)
end, {
    nargs = "?",
    desc = "Create a Gist from the current buffer.",
    range = false,
    complete = complete,
})

vim.api.nvim_create_user_command("GistsList", function(args)
    gist.list_gists(args)
end, {
    nargs = "?",
    desc = "List user Gists/Snippets.",
    complete = complete,
})
