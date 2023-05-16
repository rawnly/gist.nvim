local gist = require("gist.api")

vim.api.nvim_create_user_command("GistCreate", gist.create_from_buffer, {
	nargs = "?",
	desc = "Create a Gist from the current file.",
	range = false,
})


vim.api.nvim_create_user_command("GistCreateFromFile", gist.create_from_file, {
	nargs = "?",
	desc = "Create a Gist from the current selection.",
	range = true,
})

vim.api.nvim_create_user_command("GistsList", gist.list_gists, {
	desc = "List user Gists.",
})
