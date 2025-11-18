# Contributing to Bitbucket Workspace Sync

## 🎉 Welcome!

Thank you for considering contributing to Bitbucket Workspace Sync! This document outlines the process and guidelines for contributing.

## 📋 How to Contribute

### 1. Fork and Clone
```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/chcordova/bitbucket-workspace-sync.git
cd bitbucket-workspace-sync
```

### 2. Create a Branch
```bash
# Create a feature branch
git checkout -b feature/amazing-feature

# Or a bugfix branch
git checkout -b fix/bug-description
```

### 3. Make Your Changes
- Write clear, commented code
- Follow the existing code style
- Test your changes thoroughly
- Update documentation if needed

### 4. Test Your Changes
```bash
# Test with dry-run first
./bitbucket-workspace-sync.sh -n -v

# Test basic functionality
./bitbucket-workspace-sync.sh -w test-workspace -j 2 -v

# Test advanced features
./bitbucket-workspace-sync.sh -w test-workspace -j 4 -s -D
```

### 5. Commit Your Changes
```bash
# Use conventional commit messages
git commit -m "feat: add amazing feature"
git commit -m "fix: resolve pagination issue"
git commit -m "docs: update README with new examples"
```

**Commit Message Format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

### 6. Push and Create Pull Request
```bash
git push origin feature/amazing-feature
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Reference to any related issues
- Screenshots if applicable
- Test results

## 🧪 Testing Guidelines

### Manual Testing
Before submitting a PR, test the following scenarios:

1. **Basic clone operation**
   ```bash
   ./bitbucket-workspace-sync.sh -w test-workspace -j 4 -v
   ```

2. **Shallow clone with metrics**
   ```bash
   ./bitbucket-workspace-sync.sh -w test-workspace -j 4 -v -s -D
   ```

3. **Dry-run mode**
   ```bash
   ./bitbucket-workspace-sync.sh -w test-workspace -n -v
   ```

4. **Different export formats**
   ```bash
   ./bitbucket-workspace-sync.sh -w test-workspace -D --format csv
   ./bitbucket-workspace-sync.sh -w test-workspace -D --format html
   ```

5. **Edge cases**
   - Empty repositories
   - Repositories with long paths (Windows)
   - Rate limiting scenarios
   - Network interruptions

### Test Script
Run the basic test suite:
```bash
cd tests
chmod +x *.sh
./test_api_pagination.sh
./test_git_operations.sh
```

## 📝 Code Style Guidelines

### Bash Style
- Use **2 spaces** for indentation (not tabs)
- Maximum line length: **100 characters**
- Use `[[` instead of `[` for conditionals
- Quote all variables: `"$variable"`
- Use `${variable}` for clarity
- Add comments for complex logic
- Use functions for reusable code

### Example:
```bash
# Good
if [[ -n "$BB_WORKSPACE" ]]; then
  echo "Workspace: $BB_WORKSPACE"
fi

# Avoid
if [ "$BB_WORKSPACE" != "" ]
then
echo "Workspace: $BB_WORKSPACE"
fi
```

### Function Structure
```bash
# --------------------------------------------------------------------------- #
# Function description
# Arguments:
#   $1 - Description of first argument
#   $2 - Description of second argument
# Returns:
#   0 on success, 1 on failure
# --------------------------------------------------------------------------- #
function_name() {
  local arg1="$1"
  local arg2="$2"
  
  # Function logic here
  
  return 0
}
```

## 🐛 Reporting Bugs

### Before Reporting
1. Check existing [issues](https://github.com/chcordova/bitbucket-workspace-sync/issues)
2. Test with the latest version
3. Try with `--verbose` flag for more details

### Bug Report Should Include
- **Clear description** of the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Environment details**:
  - OS (Windows, macOS, Linux)
  - Bash version (`bash --version`)
  - Git version (`git --version`)
  - Script version
- **Command used** (sanitize credentials)
- **Error messages** or logs
- **Screenshots** if applicable

### Bug Report Template
Use the bug report template in `.github/ISSUE_TEMPLATE/bug_report.md`

## 💡 Feature Requests

### Before Requesting
1. Check if feature already exists
2. Check if it's in the roadmap (CHANGELOG.md)
3. Search existing feature requests

### Feature Request Should Include
- **Clear use case description**
- **Proposed solution** or implementation idea
- **Benefits** to other users
- **Alternatives considered**
- **Additional context** or examples

### Feature Request Template
Use the feature request template in `.github/ISSUE_TEMPLATE/feature_request.md`

## 📚 Documentation

### When to Update Docs
- Adding new features
- Changing existing functionality
- Adding new command-line options
- Fixing bugs that affect usage

### Documentation Files
- `README.md` - Main documentation (English)
- `README_es.md` - Spanish documentation
- `docs/INSTALLATION.md` - Installation guide
- `docs/ADVANCED_USAGE.md` - Advanced usage examples
- `docs/TROUBLESHOOTING.md` - Common issues and solutions
- `CHANGELOG.md` - Version history

## 🏗️ Development Setup

### Prerequisites
```bash
# Install required tools
# On macOS
brew install bash git curl jq shellcheck

# On Ubuntu/Debian
sudo apt-get install bash git curl jq shellcheck

# On Windows (Git Bash)
# Already includes bash, git, curl
# Install jq from: https://stedolan.github.io/jq/download/
```

### Local Development
```bash
# Clone the repository
git clone https://github.com/chcordova/bitbucket-workspace-sync.git
cd bitbucket-workspace-sync

# Create credentials file
cp examples/credentials.example.txt credentials.txt
# Edit credentials.txt with your details

# Make script executable
chmod +x bitbucket-workspace-sync.sh

# Run tests
./bitbucket-workspace-sync.sh -n -v
```

### Code Linting
```bash
# Install shellcheck
# Then run on the script
shellcheck bitbucket-workspace-sync.sh

# Fix any warnings or errors
```

## 🎯 Areas for Contribution

### Good First Issues
- Documentation improvements
- Example scripts
- Test coverage
- Error message clarity
- Code comments

### Advanced Contributions
- Performance optimizations
- New export formats
- Additional webhook integrations
- Multi-platform compatibility
- Feature implementations from roadmap

## 📞 Getting Help

- **Questions**: Open a [Discussion](https://github.com/chcordova/bitbucket-workspace-sync/discussions)
- **Bug Reports**: Open an [Issue](https://github.com/chcordova/bitbucket-workspace-sync/issues)
- **Chat**: Join our community (if available)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort! 🎉
