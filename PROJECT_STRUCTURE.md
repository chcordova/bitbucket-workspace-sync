# Project Structure

```
bitbucket-workspace-sync/
├── .github/                          # GitHub configuration
│   ├── workflows/
│   │   └── ci.yml                   # GitHub Actions CI pipeline
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md            # Bug report template
│       └── feature_request.md       # Feature request template
│
├── docs/                             # Documentation
│   ├── images/                      # Screenshots and diagrams
│   ├── INSTALLATION.md              # Installation guide
│   ├── TROUBLESHOOTING.md           # Troubleshooting guide
│   ├── README_FULL_EN.md            # Full documentation (English)
│   └── README_FULL_ES.md            # Full documentation (Spanish)
│
├── examples/                         # Usage examples
│   ├── credentials.example.txt      # Credentials template
│   ├── basic-usage.sh               # Basic usage example
│   ├── advanced-metrics.sh          # Advanced metrics example
│   └── ci-integration.sh            # CI/CD integration example
│
├── tests/                            # Test scripts
│   ├── test_api_pagination.sh       # API pagination tests
│   ├── test_git_operations.sh       # Git operations tests
│   └── test_metrics_generation.sh   # Metrics generation tests
│
├── bitbucket-workspace-sync.sh       # Main script
├── README.md                         # Main README (English)
├── README_es.md                      # README (Spanish)
├── LICENSE                           # MIT License
├── CHANGELOG.md                      # Version history
├── CONTRIBUTING.md                   # Contribution guidelines
└── .gitignore                        # Git ignore rules
```

## File Descriptions

### Root Files

- **`bitbucket-workspace-sync.sh`**: Main executable script
  - ~900 lines of Bash
  - Self-contained (no external dependencies except tools)
  - Handles cloning, updating, metrics, and reporting

- **`README.md`**: Primary documentation (English)
  - Quick start guide
  - Feature overview
  - Basic usage examples
  - Links to detailed docs

- **`README_es.md`**: Spanish version of README
  - Same structure as English version
  - Localized for Spanish-speaking users

- **`LICENSE`**: MIT License
  - Open source license
  - Allows commercial and private use

- **`CHANGELOG.md`**: Version history
  - Follows Keep a Changelog format
  - Semantic versioning
  - Feature roadmap

- **`CONTRIBUTING.md`**: Contribution guide
  - How to contribute
  - Code style guidelines
  - Testing requirements
  - PR process

- **`.gitignore`**: Git ignore rules
  - Excludes credentials
  - Excludes generated metrics
  - Excludes cloned repositories

### `.github/` Directory

GitHub-specific configuration files:

- **`workflows/ci.yml`**: GitHub Actions CI pipeline
  - Runs on push/PR
  - Shellcheck validation
  - Syntax checks
  - Basic tests

- **`ISSUE_TEMPLATE/bug_report.md`**: Bug report template
  - Structured format for bug reports
  - Includes environment details
  - Reproduction steps

- **`ISSUE_TEMPLATE/feature_request.md`**: Feature request template
  - Structured format for feature requests
  - Use case description
  - Proposed solution

### `docs/` Directory

Detailed documentation:

- **`INSTALLATION.md`**: Complete installation guide
  - Platform-specific instructions (macOS, Linux, Windows)
  - Dependency installation
  - Credentials setup
  - Verification steps
  - Troubleshooting

- **`TROUBLESHOOTING.md`**: Common issues and solutions
  - Installation issues
  - Credential problems
  - API connection issues
  - Git clone problems
  - Platform-specific issues
  - Error message reference

- **`README_FULL_EN.md`**: Comprehensive English documentation
  - All features detailed
  - All command-line options
  - Advanced usage patterns
  - Metrics explanation
  - Configuration options

- **`README_FULL_ES.md`**: Comprehensive Spanish documentation
  - Complete Spanish translation
  - Same depth as English version

- **`images/`**: Visual assets (to be added)
  - Logo
  - Screenshots
  - Architecture diagrams
  - Metrics examples

### `examples/` Directory

Practical usage examples:

- **`credentials.example.txt`**: Credentials template
  - Template for user credentials
  - Usage examples included
  - Environment variable format
  - Should be copied to `credentials.txt`

- **`basic-usage.sh`**: Basic usage example
  - Simple clone/update scenario
  - 4 parallel workers
  - Verbose output
  - Good for first-time users

- **`advanced-metrics.sh`**: Advanced metrics example
  - Shallow clone mode
  - Detailed metrics enabled
  - 8 parallel workers
  - Shows performance optimization

- **`ci-integration.sh`**: CI/CD integration example
  - Environment variable validation
  - Error threshold checks
  - Health score validation
  - Webhook alerts
  - Exit code handling

### `tests/` Directory

Test scripts (to be implemented):

- **`test_api_pagination.sh`**: API pagination tests
  - Test fetching large workspace (300+ repos)
  - Verify pagination logic
  - Cache validation

- **`test_git_operations.sh`**: Git operations tests
  - Test clone, update, merge
  - Test dirty working tree detection
  - Test shallow clone mode

- **`test_metrics_generation.sh`**: Metrics tests
  - Test JSON generation
  - Test CSV export
  - Test HTML export
  - Verify statistics calculations

## Usage Workflow

### First Time Setup
1. Read `README.md` or `README_es.md`
2. Follow `docs/INSTALLATION.md`
3. Copy `examples/credentials.example.txt` to `credentials.txt`
4. Run `examples/basic-usage.sh`

### Regular Use
1. Source `credentials.txt`
2. Run `bitbucket-workspace-sync.sh` with desired flags
3. Check generated metrics in workspace directory

### Contributing
1. Read `CONTRIBUTING.md`
2. Check `CHANGELOG.md` for roadmap
3. Follow GitHub templates for issues/PRs

### Troubleshooting
1. Check `docs/TROUBLESHOOTING.md`
2. Enable verbose mode `-v`
3. Search GitHub issues
4. Open new issue with bug report template

## Key Design Principles

1. **Self-contained**: Single script, no modules
2. **Well-documented**: Inline comments, external docs
3. **Examples-first**: Learn by example
4. **Multi-language**: English and Spanish support
5. **CI/CD ready**: GitHub Actions, templates
6. **Open source**: MIT license, welcome contributions

## Generated Files (Not in Repo)

These files are created by the script during execution:

```
<workspace_name>/
├── .repo_cache.json                  # API response cache (1h TTL)
├── .clone_progress                   # Real-time progress file
├── clone_metrics-<timestamp>.json    # Metrics JSON output
├── clone_metrics-<timestamp>.csv     # Metrics CSV output
├── clone_metrics-<timestamp>.html    # Metrics HTML output
├── clone_metrics-<timestamp>.md      # Metrics Markdown output
└── <repo1>, <repo2>, ...            # Cloned repositories
```

These are excluded by `.gitignore`.

## Maintenance

### Adding New Features
1. Update `bitbucket-workspace-sync.sh`
2. Update relevant docs (README, INSTALLATION, etc.)
3. Add example if applicable
4. Update `CHANGELOG.md`
5. Add tests if possible

### Releasing New Version
1. Update version in script header
2. Update `CHANGELOG.md`
3. Tag release: `git tag v1.x.x`
4. Create GitHub release
5. Update README badges if needed

## Size Estimates

- **Main script**: ~900 lines, ~35KB
- **Total documentation**: ~500 lines, ~50KB
- **Examples**: ~150 lines, ~10KB
- **Tests**: ~200 lines (estimated), ~15KB
- **Templates/Config**: ~100 lines, ~5KB

**Total project size**: ~115KB (excluding cloned repos)

---

<p align="center">
  <a href="../README.md">⬆️ Back to README</a>
</p>
