# Agent Guidelines for gist.nvim

## Build/Lint/Test Commands

- **Lint**: `luacheck lua/`
- **Format**: `stylua lua/`
- **Static Analysis**: `selene lua/`
- **No tests configured** - this is a Neovim plugin with no test suite

## Code Style Guidelines

### Formatting
- 4-space indentation
- 80 column width maximum
- Unix line endings
- Auto double quotes preference

### Structure
- Use module pattern: `local M = {}` and `return M`
- Local functions for private/internal functions
- Public functions attached to M table

### Naming
- snake_case for variables and functions
- PascalCase for module names (when used)
- Descriptive function names with clear purpose

### Imports
- `local module = require("path.to.module")`
- Group related requires at top of file

### Types & Error Handling
- Dynamic typing (no explicit type annotations)
- Use `vim.notify()` for user-facing messages
- Check for nil values and handle errors gracefully
- Use `vim.log.levels.ERROR/INFO` for notifications

### Neovim API Usage
- `vim.api.nvim_*` for core API calls
- `vim.fn.*` for Vimscript functions
- `vim.cmd.*` for Vim commands
- Table-based configuration with `vim.tbl_deep_extend`

### Comments
- LDoc style for public functions: `--- Description` and `-- @param/@return`
- Inline comments for complex logic
- No unnecessary comments

### Security
- Always shell-escape user input with `vim.fn.shellescape()`
- Validate inputs before processing
- Use secure command execution patterns