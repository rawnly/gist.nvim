local gist = require("gist")

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

vim.api.nvim_create_user_command("ListGists", gist.list_gists, {
	desc = "List user Gists.",
})
