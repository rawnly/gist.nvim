<h1 align="center">📜 gist.nvim</h1>
<p align="center">
    <em>A plugin that allows you to create a Gist (and more) from the current file</em>
</p>
<br />
<p align="center">
    <img src="gist.nvim.gif"/>
</p>


`gist.nvim` is a Neovim plugin that allows you to create gists on GitHub, GitLab, or Termbin from the current file.
The plugin uses the respective command-line tools (`gh` for GitHub, `glab` for GitLab, or direct HTTP for Termbin and 0x0) to create the gist and provides a simple interface for specifying the gist's description and privacy settings.

## Installation

To use `gist.nvim`, you need to have Neovim installed on your system.

Depending on the platform you want to use:

- **GitHub**: Install the [`gh` command-line tool](https://cli.github.com/) and configure it with your GitHub account.
- **GitLab**: Install the [`glab` command-line tool](https://gitlab.com/gitlab-org/cli) and configure it with your GitLab account.
- [**Termbin**](https://termbin.com): No additional tools required, as it uses direct HTTP requests.
- **SourceHut**: Install the [`hut` command-line tool](https://sr.ht/~emersion/hut/) and configure it with your SourceHut account.
- [**0x0.st**](https://0x0.st): No additional tools required, as it uses direct HTTP requests (curl).
- [PasteCN](https://pastecn.com): No additional tools required, as it uses direct HTTP requests (curl).

If you intend to use the `GistsList` command to list and edit all your gists (GitHub only), I suggest the `nvim-unception` plugin.


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

To create a gist from the current file, use the `:GistCreateFromFile` command in Neovim.
The plugin will prompt you for a description and whether the gist should be private or public (depending on the platform).

```vim
  :GistCreate [description] [public=true]
```

- `:GistCreate` will create the gist from the current selection or the entire buffer if no selection is made
- `:GistCreateFromFile` will create the gist from the current file

Both commands accept the same options: `[description=]` and `[public=true]`

If you don't pass the `description` it will prompt to insert one later.
If you pass `[public=true]` it won't prompt for privacy later.

After you enter the description and privacy settings, the plugin will ask for confirmation and create the gist using the configured platform's tool, then copy the gist's URL to the given clipboard registry.

You can also list your gists and edit their files on the fly (GitHub only).
```vim
    :GistsList
```
- `:GistsList` will list all your gists and after you select one it will:
  - If `use_multiplexer` is enabled and a multiplexer (tmux/zellij) is detected: opens the gist in a new multiplexer tab using `gh gist edit`
  - Otherwise: opens the gist in a new tab with read-only content using `gh gist view -r`
  - The default editor for modifying gists is configured as part of the gh cli usually in `~/.config/gh/config.yaml' or the system default

## Configuration

`gist.nvim` provides configuration options via the `setup` function:

```lua
    require("gist").setup({
        platform = "github", -- Default platform: "github", "gitlab", "termbin", or "sourcehut"
        clipboard = "+", -- The registry to use for copying the gist URL
        prompts = {
            create = {
                private = false,      -- Prompt for private/public when creating a gist
                description = false,  -- Prompt for description when creating a gist
                confirmation = false, -- Prompt for confirmation when creating a gist
            },
        },
        platforms = {
            github = {
                private = false, -- All GitHub gists will be public by default
                cmd = "gh",     -- Command for GitHub CLI
                list = {
                    limit = nil,       -- Limit the number of gists fetched (default: nil, uses gh default of 10)
                    read_only = false, -- Opens gists in read-only buffers. Ignored if use_multiplexer is false
                },
            },
            gitlab = {
                cmd = "glab",  -- Command for GitLab CLI
                private = true, -- Create personal snippets by default
            },
            termbin = {
                url = "termbin.com", -- URL for Termbin service
                port = 9999,         -- Port for Termbin service
            },
            ["0x0"] = {
                private = false,
            },
            pastecn = {
                private = false,
                url = "https://pastecn.com",
                type = "file",
            },
            sourcehut = {
                cmd = "hut", -- Command for SourceHut CLI
            },
        },
        list = {
            use_multiplexer = true, -- Use terminal multiplexer (tmux/zellij) if detected for editing gists
            -- If there are multiple files in a gist you can scroll them,
            -- with vim-like bindings n/p next previous
            mappings = {
                next_file = "<C-n>",
                prev_file = "<C-p>"
            }
        }
    })
```

For GitHub, the `cmd` defaults to `gh`. You may want to override this with a custom wrapper, e.g., for 1Password users: `op plugin run -- gh`.

For GitLab, `cmd` defaults to `glab`.

For PasteCN, Termbin and 0x0, no command is needed as it uses direct HTTP.

For SourceHut, `cmd` defaults to `hut`.

### Multiplexer Support

When `list.use_multiplexer` is set to `true`, the plugin will automatically detect if you're running inside a terminal multiplexer:
- **tmux**: Opens gists in a new tmux window using `tmux new-window`
- **zellij**: Opens gists in a new zellij tab using `zellij run -i -c`

If no multiplexer is detected, gists will be opened in read-only Neovim buffers for viewing.

## License

`gist.nvim` is released under MIT License. See [LICENSE](/LICENSE.md) for details.

## Contributing

If you find a bug or would like to contribute to `gist.nvim`, please open an issue or a pull request.
All contributions are welcome and appreciated!
