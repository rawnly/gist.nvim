local gist = require("gist")
local utils = require("gist.core.utils")

vim.api.nvim_create_user_command("CreateGistFromFile", gist.create_from_file, {
	nargs = "?",
	desc = "Create a Gist from the current file.",
	range = false,
})

vim.api.nvim_create_user_command("CreateGist", gist.create, {
	nargs = "?",
	desc = "Create a Gist from the current selection.",
	range = true,
})
