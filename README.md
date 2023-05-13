# gist.nvim

`gist.nvim` is a Neovim plugin that allows you to create a GitHub Gist from the current file.
The plugin uses the gh command-line tool to create the Gist and provides a simple interface for specifying the Gist's description and privacy settings.

## Installation

To use `gist.nvim`, you need to have Neovim installed on your system.
You also need to have the gh command-line tool installed and configured with your GitHub account.

Once you have Neovim and gh installed, you can install `gist.nvim` using your favorite plugin manager.
For example, if you are using packer, you can add the following line to your init.vim file:

```lua
  use "rawnly/gist.nvim"
```

## Usage

To create a Gist from the current file, use the `:CreateGist` command in Neovim.
The plugin will prompt you for a description and whether the Gist should be private or public.

```vim
  :CreateGist [description] [public=true]
```

- `:CreateGist` will create the gist from the current selection
- `:CreateGistFromFile` will create the gist from the current file

Both the commands accept the same options which are `[description=]` and `[public=true]`

If you don't pass the `description` it will prompt to insert one later.
If you pass `[public=true]` it won't prompt for privacy later.

After you enter the description and privacy settings, the plugin ask for confirmation and will create the Gist using the gh command-line tool and copy the Gist's URL to the given clipboard registry.

## Configuration

`gist.nvim` provides a few configuration options that you can set as global params:

- `g:gist_is_private`: All the gists will be private and you won't be prompted again. Defaults to `false`
- `g:gist_clipboard`: The registry to use for copying the Gist URL. Defaults to `"+"`

## License

`gist.nvim` is released under MIT License. See [LICENSE](/LICENSE.md) for details.

## Contributing

If you find a bug or would like to contribute to `gist.nvim`, please open an issue or a pull request.
All contributions are welcome and appreciated!
