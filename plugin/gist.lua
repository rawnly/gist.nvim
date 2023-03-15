local gist = require("gist")

vim.api.nvim_create_user_command("Rawnly", function(args)
	vim.api.nvim_echo({
		{ "Args: " .. table.concat(args, " "), "Identifier" },
	}, true, {})
end, {
	nargs = "*",
})

vim.api.nvim_create_user_command("CreateFileGist", gist.create_from_file, {
	desc = "Create a new gist from current file",
	nargs = "*",
})

vim.api.nvim_create_user_command("CreateGist", gist.create_from_selection, {
	desc = "Create a new gist from current selection",
})
