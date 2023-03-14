local gist = require("gist")

vim.api.nvim_create_user_command("CreateGist", gist.create, {
	bang = true,
	desc = "Create a new gist from curretn file",
})
