# gist.nvim
![Showcase](gist.nvim.gif)

`gist.nvim` is a Neovim plugin that allows you to create GitHub Gists or GitLab Snippets from the current file.
The plugin uses the [`gh` command-line tool](https://cli.github.com/) for GitHub and [`glab` command-line tool](https://gitlab.com/gitlab-org/cli) for GitLab to create gists/snippets and provides a simple interface for specifying the description and privacy settings.

## Installation

To use `gist.nvim`, you need to have Neovim installed on your system.
You also need to have the `gh` command-line tool installed and configured with your GitHub account for GitHub gists, and/or the `glab` command-line tool installed and configured with your GitLab account for GitLab snippets.

If you intend to use the `GistsList` command to list and edit all your gists, I suggest the `nvim-unception` plugin.


Once you have Neovim and gh installed, you can install `gist.nvim` using your favorite plugin manager.

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
return {
  {
    "Rawnly/gist.nvim",
    cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
    config = true
  },
  -- `GistsList` opens the selected gist in a terminal buffer,
  -- nvim-unception uses neovim remote rpc functionality to open the gist in an actual buffer
  -- and prevents neovim buffer inception
  {
    "samjwill/nvim-unception",
    lazy = false,
    init = function() vim.g.unception_block_while_host_edits = true end
  }
}
```
#### Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
  "rawnly/gist.nvim",
  config = function() require("gist").setup() end,
  -- `GistsList` opens the selected gif in a terminal buffer,
  -- this plugin uses neovim remote rpc functionality to open the gist in an actual buffer and not have buffer inception
  requires = { "samjwill/nvim-unception", setup = function() vim.g.unception_block_while_host_edits = true end }
}
```

## Usage

To create a Gist from the current file, use the `:GistCreate` command in Neovim.
The plugin will prompt you for a description and whether the Gist should be private or public.

```vim
  :GistCreate [description] [public=true] [platform=github]
```

- `:GistCreate` will create the gist/snippet from the current selection
- `:GistCreateFromFile` will create the gist/snippet from the current file

All commands accept the same options: `[description=]`, `[public=true]`, and `[platform=github]` or `[platform=gitlab]`

If you don't pass the `description` it will prompt to insert one later.
If you pass `[public=true]` it won't prompt for privacy later.
If you don't specify `platform`, it defaults to the configured `default_platform` (GitHub by default).

After you enter the description and privacy settings, the plugin will ask for confirmation and create the gist/snippet using the appropriate CLI tool, then copy the URL to the configured clipboard register.

You can also list your gists/snippets and edit them on the fly.
```vim
    :GistsList [platform=github]
```
- `:GistsList` will list all your gists/snippets and after you select one it will open a buffer to edit it
  - For GitHub gists: The default editor for modifying gists is configured as part of the gh cli usually in `~/.config/gh/config.yaml' or the system default
  - For GitLab snippets: Selecting a snippet will open it in your default web browser for editing

## Configuration

`gist.nvim` provides a few configuration options that you can with the `setup` function:

```lua
    require("gist").setup({
        private = false, -- All gists/snippets will be private, you won't be prompted again
        clipboard = "+", -- The registry to use for copying the URL
        split_direction = "vertical", -- default: "vertical" - set window split orientation when opening a gist ("vertical" or "horizontal")
        gh_cmd = "gh", -- GitHub CLI command
        glab_cmd = "glab", -- GitLab CLI command
        default_platform = "github", -- Default platform: "github" or "gitlab"
        list = {
            limit = nil, -- Limit the number of gists/snippets fetched (default: nil, uses CLI defaults)
            -- If there are multiple files in a gist you can scroll them,
            -- with vim-like bindings n/p next previous
            mappings = {
                next_file = "<C-n>",
                prev_file = "<C-p>"
            }
        }
    })
```

By default `gh_cmd` and `glab_cmd` are set to the default commands. However, there may be
cases where you want to override these with your custom wrapper. Users of the
1Password op plugin will likely want to point to the wrapper command.
(example: `op plugin run -- gh` or `op plugin run -- glab`)

## License

`gist.nvim` is released under MIT License. See [LICENSE](/LICENSE.md) for details.

## Contributing

If you find a bug or would like to contribute to `gist.nvim`, please open an issue or a pull request.
All contributions are welcome and appreciated!
