local scripto = require("scripto")

vim.api.nvim_create_user_command("ScriptoOpen", scripto.start, {
	bang = true,
	desc = "spawn a new playground",
})

vim.api.nvim_create_user_command("ScriptoRun", scripto.run, {
	bang = true,
	desc = "spawn a new playground",
})
