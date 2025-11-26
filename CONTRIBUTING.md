# Contributing to gist.nvim

Thank you for your interest in contributing to gist.nvim! This document provides guidelines and information for contributors.

## Ways to Contribute

- **Bug Reports**: Report bugs by opening an issue on GitHub
- **Feature Requests**: Suggest new features or improvements
- **Code Contributions**: Submit pull requests with fixes or enhancements
- **Documentation**: Improve documentation, README, or add examples
- **Testing**: Test the plugin and report issues

## Development Setup

### Prerequisites

- Neovim (latest stable version recommended)
- Git
- Lua knowledge

### Platform Tools

Depending on which platforms you want to test:

- **GitHub**: Install [`gh` CLI](https://cli.github.com/)
- **GitLab**: Install [`glab` CLI](https://gitlab.com/gitlab-org/cli)
- **SourceHut**: Install [`hut` CLI](https://sr.ht/~emersion/hut/)
- **Termbin**: No additional tools needed

### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/gist.nvim.git
   cd gist.nvim
   ```
3. Set up the plugin for development:
   ```lua
   -- In your Neovim config, add the local path
   -- Note: This project uses LazyVim as the reference configuration
   {
     "github.com/rawnly/gist.nvim",
     path = "~/path/to/gist.nvim",
     opts = {
       -- your config here
     }
   }
   ```

## Code Style and Linting

This project uses several tools to maintain code quality:

### Lua Formatting
- **StyLua**: Code formatter
  ```bash
  # Install: cargo install stylua
  # Format: stylua lua/
  ```

### Linting
- **Luacheck**: Static analysis
  ```bash
  # Install: luarocks install luacheck
  # Check: luacheck lua/
  ```

- **Selene**: Additional linting
  ```bash
  # Install: cargo install selene
  # Check: selene lua/
  ```



### Pre-commit Checks

Before committing, please run:
```bash
# Format code
stylua lua/

# Run linters
luacheck lua/
selene lua/
```

## Testing

Currently, testing is manual. Please test your changes with:

1. Different platforms (GitHub, GitLab, Termbin, SourceHut)
2. Various file types and content
3. Different privacy settings
4. Error conditions (invalid tokens, network issues, etc.)

## Adding a New Platform

See [`doc/adding_platforms.md`](doc/adding_platforms.md) for detailed instructions on adding support for new gist platforms.

## Pull Request Process

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines

3. **Test thoroughly** with different platforms and scenarios

4. **Update documentation** if needed (README, doc files, etc.)

5. **Run linting tools** and fix any issues

6. **Commit your changes** with clear, descriptive commit messages:
   ```bash
   git commit -m "feat: add support for new platform

   - Add platform configuration
   - Implement create function
   - Update services.lua
   - Add documentation"
   ```

7. **Push to your fork** and **create a pull request**

### Pull Request Guidelines

- Use a clear, descriptive title
- Provide a detailed description of the changes
- Reference any related issues
- Ensure all tests pass
- Update documentation as needed
- Keep changes focused and atomic

## Commit Message Format

This project follows conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Testing related changes
- `chore`: Maintenance tasks

Examples:
- `feat(gitlab): add support for GitLab snippets`
- `fix(github): handle empty gist descriptions`
- `docs: update installation instructions`

## Code of Conduct

Please be respectful and constructive in all interactions. We follow a code of conduct similar to the [Contributor Covenant](https://www.contributor-covenant.org/).

## License

By contributing to this project, you agree that your contributions will be licensed under the same MIT License that covers the project.

## Questions?

If you have questions about contributing, feel free to open an issue or discussion on GitHub.

Thank you for contributing to gist.nvim! 🎉
