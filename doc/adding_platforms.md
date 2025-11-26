# Adding a New Platform to gist.nvim

This document outlines the steps to add support for a new gist/paste platform to gist.nvim, along with the limitations and considerations.

## Steps to Add a New Platform

### 1. Create Platform Configuration

Add your platform to the `platforms` table in `lua/gist/init.lua`:

```lua
platforms = {
    -- existing platforms...
    your_platform = {
        cmd = "your_cli_tool",  -- CLI tool command (e.g., "gh", "glab", "hut")
        -- Add platform-specific config options here
    },
},
```

Also add it to the `valid_platforms` table in the `setup` function:

```lua
local valid_platforms = { github = true, gitlab = true, termbin = true, sourcehut = true, your_platform = true }
```

### 2. Create Platform Module

Create a new file `lua/gist/core/your_platform.lua` with the required functions. At minimum, you must implement:

- `create(filename, content, description, private)` - Creates a gist/paste
- `get_create_details(ctx)` - Returns details for gist creation (filename, description, privacy)

Optional functions (implement if supported by the platform):

- `list()` - Lists existing gists
- `get_edit_cmd(hash)` - Returns command to edit a gist
- `fetch_content(hash)` - Fetches content of a gist
- `format(g)` - Formats gist info for display

See existing platform files (`gh.lua`, `gitlab.lua`, `sourcehut.lua`, `termbin.lua`) for implementation examples.

### 3. Update Services Module

In `lua/gist/core/services.lua`:

- Add `local your_platform = require("gist.core.your_platform")` at the top
- Add `elseif` branches in each function that should support your platform

For example, in the `create` function:

```lua
elseif platform == "your_platform" then
    return your_platform.create(...)
```

## Platform Limitations

### Feature Support Matrix

| Feature          | GitHub | GitLab | SourceHut | Termbin |
|------------------|--------|--------|-----------|---------|
| Create gist     | ✅     | ✅     | ✅        | ✅      |
| List gists      | ✅     | ❌     | ❌        | ❌      |
| Edit gist       | ✅     | ❌     | ❌        | ❌      |
| Fetch content   | ✅     | ❌     | ❌        | ❌      |
| Format display  | ✅     | ❌     | ❌        | ❌      |
| Private gists   | ✅     | ✅     | ❌        | ❌      |
| Descriptions    | ✅     | ✅     | ❌        | ❌      |
| File names      | ✅     | ✅     | ✅        | ❌      |

### General Limitations

- **CLI Dependency**: Each platform requires its CLI tool to be installed and authenticated
- **API Differences**: Platforms have different APIs and capabilities - not all features can be uniformly supported
- **Privacy Models**: Privacy handling varies (private/public vs personal/project vs visibility levels)
- **Content Handling**: Some platforms may not support all content types or have size limits
- **Authentication**: User must handle authentication for each platform's CLI tool separately

### Implementation Considerations

- **Error Handling**: Always check `vim.v.shell_error` after executing commands
- **URL Extraction**: Use appropriate regex patterns to extract URLs from CLI output
- **Parameter Mapping**: Map gist.nvim's generic parameters to platform-specific options
- **Testing**: Test with various content types, privacy settings, and error conditions
- **Documentation**: Update user documentation to mention the new platform

## Example: Minimal Platform Implementation

For a platform that only supports basic gist creation:

```lua
local utils = require("gist.core.utils")
local M = {}

function M.create(filename, content, description, private)
    local config = require("gist").config.platforms.your_platform
    local cmd = config.cmd .. " create --content " .. vim.fn.shellescape(content)

    local output = utils.exec(cmd, content)
    if vim.v.shell_error ~= 0 then
        return output, vim.v.shell_error
    end

    local url = output:match("https://yourplatform.com/%S+")
    return url, nil
end

function M.get_create_details(ctx)
    return {
        filename = vim.fn.expand("%:t"),
        description = ctx.description or "",
        is_private = false,  -- or implement privacy logic
    }
end

return M
```

Remember to adapt this to your specific platform's CLI interface and capabilities.