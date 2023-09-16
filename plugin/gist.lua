local gist = require("gist.api")

local complete = function()
	return { "description=", "public=" }
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

vim.api.nvim_create_user_command("GistsList", gist.list_gists, {
	desc = "List user Gists.",
})
