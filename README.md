# Bitbucket Workspace Sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub release](https://img.shields.io/github/v/release/chcordova/bitbucket-workspace-sync)](https://github.com/chcordova/bitbucket-workspace-sync/releases)

> 🚀 High-performance CLI to clone/update all repositories from a Bitbucket Cloud workspace in parallel

[📖 Full Documentation](docs/README_FULL_EN.md) | [🇪🇸 Español](README_ES.md) | [🐛 Report Bug](../../issues) | [✨ Request Feature](../../issues)

---

## ✨ Key Features

### 🚀 **Performance & Optimization**
- **Adaptive Parallelism**: Auto-adjusts workers on rate limiting (HTTP 429)
- **HTTP/2 with Keepalive**: Persistent connections for reduced latency
- **Metadata Caching**: 1-hour TTL to minimize API calls
- **Shallow Clone**: 5-10x faster with `-s` flag (clone only latest commit)
- **Size Prioritization**: Clones small repos first for quick feedback
- **Git Optimization**: Partial clone, no compression, large buffers

### 📊 **Reporting & Metrics**
- **Real-time Dashboard**: Live `.clone_progress` file updates
- **Advanced Statistics**: Min/Max/Avg/Median/StdDev timing
- **Health Score**: 0-100 workspace condition assessment
- **Category Breakdown**: Groups repos by prefix (e.g., `team-*`, `project-*`)
- **Historical Comparison**: Compare with previous runs
- **Multiple Formats**: Export to JSON, CSV, HTML, Markdown

### 🔔 **Alerts & Notifications**
- **Webhook Integration**: Slack and Microsoft Teams
- **Smart Alerts**: Notify only when errors exceed threshold
- **Severity Levels**: Info, Warning, Error with appropriate colors

---

## 🚀 Quick Start

```bash
# 1. Download the script
curl -O https://raw.githubusercontent.com/chcordova/bitbucket-workspace-sync/master/bitbucket-workspace-sync.sh
chmod +x bitbucket-workspace-sync.sh

# 2. Set credentials
export BB_USERNAME="your_username"
export BB_APP_PASSWORD="your_app_password"
export BB_WORKSPACE="your_workspace"

# 3. Run!
./bitbucket-workspace-sync.sh -j 4 -v
```

### With Detailed Metrics
```bash
# Shallow clone (fast) with detailed metrics
./bitbucket-workspace-sync.sh -j 6 -v -s -D
```

---

## 📋 Requirements

| Tool     | Version  |
|----------|----------|
| **Bash** | ≥ 4.0    |
| **git**  | any      |
| **curl** | any      |
| **jq**   | any      |

### Installation

```bash
# macOS (Homebrew)
brew install bash git curl jq

# Ubuntu/Debian
sudo apt-get install bash git curl jq

# Windows (Git Bash)
# Download jq from: https://stedolan.github.io/jq/
```

### ⚠️ Windows Users
The script automatically configures `git config --global core.longpaths true` to avoid:
```
error: unable to create file ...: Filename too long
```

---

## ⚙️ Usage

### Basic Flags
```bash
./bitbucket-workspace-sync.sh [options]

Options:
  -w, --workspace <id>   Workspace ID (or use $BB_WORKSPACE)
  -d, --dir <path>       Destination folder (default: ./<workspace>)
  -j, --jobs <n>         Parallel jobs (default: 4)
  -v, --verbose          Show per-repo progress
  -s, --shallow          Shallow clone (5-10x faster)
  -n, --dry-run          Simulate without making changes
  -m, --metrics          Generate compact JSON metrics
  -D, --detailed         Generate detailed metrics (implies -m)
  --format <fmt>         Export format: json|csv|html|markdown
  --webhook <url>        Webhook URL for alerts (Slack/Teams)
  -h, --help             Show help
```

### Common Examples

| Use Case | Command |
|----------|---------|
| Basic clone/update | `./bitbucket-workspace-sync.sh -j 4 -v` |
| Fast shallow clone | `./bitbucket-workspace-sync.sh -j 6 -v -s -D` |
| With CSV export | `./bitbucket-workspace-sync.sh -D --format csv` |
| Dry-run test | `./bitbucket-workspace-sync.sh -n -v` |
| With alerts | `./bitbucket-workspace-sync.sh -D --webhook <url>` |

See [more examples](examples/)

---

## 📊 Performance Benchmarks

Real-world results from 347 repository workspace:

| Mode | Time | Repos/min | Speedup |
|------|------|-----------|---------|
| **Full Clone** | ~92 min | 3.8 | 1x |
| **Shallow Clone** (`-s`) | ~12 min | 28.9 | **7.6x** |

*Your results may vary based on repository sizes and network speed.*

---

## 📈 Metrics Example

```bash
./bitbucket-workspace-sync.sh -w myteam -j 8 -v -s -D
```

**Output:**
```
════════════════════════════════════════════
📊 FINAL SUMMARY
════════════════════════════════════════════
Results  → cloned: 12 | updated: 25 | unchanged: 308
Issues   → dirty: 2 | no-branch: 0 | errors: 0
Timing   → min: 18s | max: 402s | avg: 95s | median: 52s

🐌 Slowest repositories:
   1. theshire-accounts (402s)
   2. theshire-customers (397s)
   3. rivendell-commons (349s)

🏥 Health Score: 98/100
   ✅ Workspace is in excellent condition
   
📈 Comparison: 28% faster than last run
════════════════════════════════════════════
```

---

## 🔐 Credentials Setup

### Method 1: Environment Variables
```bash
export BB_USERNAME="your_username"
export BB_APP_PASSWORD="your_app_password"
export BB_WORKSPACE="your_workspace"
```

### Method 2: Credentials File
```bash
# Copy template
cp examples/credentials.example.txt credentials.txt

# Edit credentials.txt with your values
# Then load it
source credentials.txt
```

### Creating App Password
1. Go to Bitbucket Settings → App passwords
2. Create new app password with `repository:read` scope
3. Copy the generated password (can't be viewed again)

---

## 🔄 How It Works

1. **Fetches** complete repo list via Bitbucket API v2 (paginated)
2. **Caches** metadata for 1 hour to reduce API calls
3. **Prioritizes** repositories by size (small first)
4. **Clones** missing repos or **updates** existing ones
5. **Detects** dirty working trees and skips them
6. **Generates** detailed metrics and health score
7. **Sends** alerts if configured

**Update Logic:**
- Missing repo → `git clone`
- Existing repo → `git fetch && git merge --ff-only`
- Dirty working tree → skip with warning
- No default branch → skip

---

## 📚 Documentation

- [📖 Installation Guide](docs/INSTALLATION.md)
- [🚀 Advanced Usage](docs/ADVANCED_USAGE.md)
- [🔧 Troubleshooting](docs/TROUBLESHOOTING.md)
- [📝 Changelog](CHANGELOG.md)
- [🤝 Contributing](CONTRIBUTING.md)

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Steps
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by the need to efficiently manage large Bitbucket workspaces
- Built with feedback from DevOps teams managing 300+ repositories
- Thanks to all contributors!

---

## 📞 Support

- 🐛 **Bug Reports**: [Open an issue](../../issues)
- 💡 **Feature Requests**: [Open an issue](../../issues)
- 💬 **Discussions**: [GitHub Discussions](../../discussions)
- 📧 **Email**: [your.email@example.com](mailto:your.email@example.com)

---

<p align="center">
  Made with ❤️ by Charles Córdova
</p>

<p align="center">
  <a href="#bitbucket-workspace-sync">⬆️ Back to top</a>
</p>
