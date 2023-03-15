vim.cmd([[
    command! -range CreateGist :lua require("gist").create(<line1>, <line2>)
]])
