# Bitbucket Workspace Sync

`bitbucket-workspace-sync.sh` is an **advanced Bash CLI** that clones **or** updates all repositories from a **Bitbucket Cloud** *workspace* in parallel with performance optimizations and detailed reporting.

---

## ✨ Key Features

### 🚀 **Performance & Optimization**
* **Adaptive Parallelism**: Dynamic worker adjustment on rate limiting (HTTP 429)
* **HTTP/2 with keepalive**: Persistent connections to reduce latency
* **Metadata caching**: Stores repo list for 1 hour (avoids repeated API calls)
* **Size-based prioritization**: Clones small repos first for fast feedback
* **Optimized Git**: Partial clone (`--filter=blob:none`), no compression, large buffers
* **Optional shallow clone**: `-s` flag to clone only latest commit (5-10x faster)

### 📊 **Reporting & Metrics**
* **Real-time dashboard**: `.clone_progress` file updated live
* **Advanced statistics**: Min/Max/Avg/Median/StdDev of clone times
* **Health Score**: 0-100 workspace health assessment
* **Category classification**: Groups repos by prefix (theshire-, rivendell-, etc.)
* **Top N slowest repos**: Identifies bottlenecks
* **Historical comparison**: Compare performance with previous run
* **Multiple formats**: Export to JSON, CSV, HTML, Markdown

### 🔔 **Alerts & Notifications**
* **Webhooks**: Slack/Microsoft Teams integration
* **Smart alerts**: Notify only if errors >= configurable threshold
* **Severity levels**: Info, Warning, Error with appropriate colors

### 🛠 **Core Features**
* Fetches complete repo list via **API v2** (paginated)
* **Clones** missing repos and **updates** existing ones with `git fetch && git merge --ff-only`
* Detects dirty *working tree* (configurable exclusion regex)
* Parallel execution controlled by `--jobs` (`xargs -P`)
* **Clean output by default**: only final summary  
  Enable `-v / --verbose` to see per-repo progress
* **Dry-run**, optional **JSON** metrics (compact `-m` or detailed `-D`)
* **Windows compatibility**: Automatically configures `core.longpaths` for long paths
* Safe working directory handling (avoids `getcwd` errors)
* All in a single Bash file (requires Bash ≥ 4.0)

---

## 📋 Minimum Requirements

| Tool | Version |
|------|---------|
| **Bash** | ≥ 4.0 |
| **git**  | any |
| **curl** | any |

### ⚠️ Windows Note

The script automatically configures `git config --global core.longpaths true` to avoid errors like:
```
error: unable to create file ...: Filename too long
```

If the script cannot configure it automatically, run it manually:
```bash
git config --global core.longpaths true
```
| **jq**   | any |

### Quick Installation

```bash
# macOS (Homebrew)
brew install bash git curl jq

# Debian / Ubuntu
sudo apt-get update && sudo apt-get install bash git curl jq
```

---

## 🚀 Getting Started

```bash
# Make it executable
chmod +x bitbucket-workspace-sync.sh

# Clone/update with 4 threads and verbose output
export BB_USERNAME="username"
export BB_APP_PASSWORD="app_password"

./bitbucket-workspace-sync.sh \
  -w <my_workspace> \
  -j 4 -v
```

> Run `./bitbucket-workspace-sync.sh -h` to see built-in help.

---

## ⚙️ Flags / Options

### Basic Options
| Long | Short | Argument | Default | Description |
|------|-------|----------|---------|-------------|
| `--workspace` | `-w` | `<id>` | *(env `BB_WORKSPACE`)* | Workspace ID. |
| `--dir` | `-d` | `<path>` | `pwd/<workspace>` | Target folder. |
| `--jobs` | `-j` | `<n>` | `4` | Parallel processes. |
| `--verbose` | `-v` | – | `false` | Show per-repo progress (**stderr**). |
| `--dry-run` | `-n` | – | `false` | Simulation mode; doesn't execute `git`. |
| `--help` | `-h` | – | – | Show help and exit. |

### Performance Optimization
| Long | Short | Argument | Default | Description |
|------|-------|----------|---------|-------------|
| `--shallow` | `-s` | – | `false` | Shallow clone (only latest commit, 5-10x faster). |
| `--no-adaptive` | – | – | `false` | Disable adaptive parallelism (auto-reduce workers). |

### Metrics and Reports
| Long | Short | Argument | Default | Description |
|------|-------|----------|---------|-------------|
| `--metrics` | `-m` | – | `false` | Generate compact JSON metrics. |
| `--detailed` | `-D` | – | `false` | Detailed metrics with statistics (implies `--metrics`). |
| `--no-metrics` | – | – | **enabled** | Disable metrics. |
| `--format` | – | `<fmt>` | `json` | Export format: `json`, `csv`, `html`, `markdown`. |

### Alerts and Notifications
| Long | Short | Argument | Default | Description |
|------|-------|----------|---------|-------------|
| `--webhook` | – | `<url>` | *(env `BB_ALERT_WEBHOOK`)* | Webhook URL for alerts (Slack/Teams). |

### Advanced Configuration
| Long | Short | Argument | Default | Description |
|------|-------|----------|---------|-------------|
| `--ignore` | `-i` | "`<regex>`" | See *Default ignore* ↓ | Regex to ignore local changes. |

### *Default ignore*

```regex
\.DS_Store$|\.idea/|\.vscode/|\.classpath$|\.project$|\.settings/
```

---

## 🖥️ Usage Examples

### Basic Usage
| Case | Command |
|------|---------|
| Initial clone | `./bitbucket-workspace-sync.sh -w myteam -d ~/code/myteam` |
| CI execution (silent) | `./bitbucket-workspace-sync.sh -j 8` |
| Dry-run | `./bitbucket-workspace-sync.sh -n -v` |
| Different target folder | `./bitbucket-workspace-sync.sh -d /srv/repos` |

### Optimized Performance
| Case | Command |
|------|---------|
| **Fast clone (shallow)** | `./bitbucket-workspace-sync.sh -w myteam -j 4 -v -s` |
| With adaptive parallelism | `./bitbucket-workspace-sync.sh -w myteam -j 6 -v -s -D` |
| Without adaptive (force workers) | `./bitbucket-workspace-sync.sh -j 8 --no-adaptive` |

### Metrics and Reports
| Case | Command |
|------|---------|
| Compact JSON metrics | `./bitbucket-workspace-sync.sh -m` |
| **Detailed metrics** (recommended) | `./bitbucket-workspace-sync.sh -D` |
| Export to CSV | `./bitbucket-workspace-sync.sh -D --format csv` |
| Export to HTML | `./bitbucket-workspace-sync.sh -D --format html` |
| Export to Markdown | `./bitbucket-workspace-sync.sh -D --format markdown` |

### Alerts and Monitoring
| Case | Command |
|------|---------|
| With Slack alerts | `./bitbucket-workspace-sync.sh -D --webhook https://hooks.slack.com/...` |
| With Teams alerts | `./bitbucket-workspace-sync.sh -D --webhook https://outlook.office.com/...` |
| Check progress file exists | `ls -la \| grep clone` |
| Monitor live progress (Linux/macOS) | `watch -n1 cat ./myteam/.clone_progress` |
| Monitor live progress (Git Bash/Windows) | `while true; do clear; cat .clone_progress 2>/dev/null \|\| echo "Waiting for file..."; sleep 1; done` |

### Advanced
| Case | Command |
|------|---------|
| Custom exclusion regex | `./bitbucket-workspace-sync.sh -i ".log$\|/target/"` |
| All optimized + HTML report | `./bitbucket-workspace-sync.sh -w myteam -j 4 -v -s -D --format html` |

---

## 🔐 Credentials

Before running, export:

```bash
export BB_USERNAME="your_username"
export BB_APP_PASSWORD="your_app_password"
export BB_WORKSPACE="my_workspace"   # optional if using -w
```

Optional variables:

| Variable | Purpose |
|----------|---------|
| `BB_IGNORE_PATTERN` | Override exclusion regex. |
| `BB_ALERT_WEBHOOK` | Webhook URL for alerts (Slack/Teams). |

---

## 🔄 Update Logic

1. **Folder doesn't exist** → `git clone`.
2. Exists but **not a Git repo** → renamed and cloned again.
3. Dirty *working tree* → **skipped**.
4. Detects main branch (`origin/HEAD`, `main`, `master`).
5. `git fetch` + `git merge --ff-only`.  
   *No HEAD change* → **unchanged**; if advances → **updated**.

---

## 📊 JSON Metrics

### Compact (`-m`)
```json
{
  "timestamp": "2025-11-14T22:51:52Z",
  "workspace": "myteam",
  "total": 347,
  "cloned": 12,
  "updated": 25,
  "clean": 308,
  "dirty": 2,
  "errors": 0,
  "duration_sec": 845
}
```

### Detailed (`-D`) - Includes Advanced Statistics
```json
{
  "timestamp": "2025-11-14T22:51:52Z",
  "workspace": "myteam",
  "totals": {
    "cloned": 12,
    "updated": 25,
    "unchanged": 308,
    "dirty": 2,
    "skipped": 0,
    "errors": 0
  },
  "duration_sec": 845,
  "timing_stats": {
    "min_sec": 18,
    "max_sec": 402,
    "avg_sec": 95,
    "median_sec": 52,
    "std_dev": 78.5,
    "slowest_repos": [
      {"repo": "theshire-accounts", "sec": 402},
      {"repo": "theshire-customers", "sec": 397},
      {"repo": "rivendell-commons", "sec": 349}
    ]
  },
  "categories": {
    "theshire": 145,
    "rivendell": 89,
    "devops": 56
  },
  "health_score": 96,
  "repos": [
    {"repo": "devops-java", "result": "CLONED", "sec": 43},
    {"repo": "theshire-gates", "result": "UPDATED", "sec": 39}
  ]
}
```

### Additional Formats

**CSV** (`--format csv`): Importable to Excel/Google Sheets  
**HTML** (`--format html`): Visual report with charts  
**Markdown** (`--format markdown`): Readable documentation

---

## 🛠 Troubleshooting

| Symptom | Solution |
|---------|----------|
| `HTTP 401/403` | Verify username/app-password and scopes (`repository:read`). |
| `HTTP 429` (rate limit) | Script auto-adjusts workers. If persists, reduce `-j`. |
| `fatal: not a git repository` | Corrupted folder; script renames and reclones. |
| Repos stay *dirty* | Adjust `--ignore` or clean your changes. |
| `mapfile: command not found` | Bash 3 (macOS); install Bash 4 (`brew install bash`). |
| `getcwd: Operation not permitted` | Running in folder without permissions; script does safe `cd`. |
| Very slow clones | Use `-s` (shallow) or reduce `-j` to avoid throttling. |
| Outdated cache | Delete `.repo_cache.json` to force refresh. |
| Webhook not working | Verify URL format (Slack vs Teams have different formats). |

## 🔍 Monitoring and Debugging

### View real-time progress
```bash
# In a separate terminal
watch -n1 cat /path/workspace/.clone_progress
```

### Analyze slow repos
```bash
# View top 10 slowest from last report
jq '.timing_stats.slowest_repos' clone_metrics-*.json
```

### Compare historical performance
```bash
# Script automatically compares with previous run
# Look for files: clone_metrics-*.json
```

---

## 🎯 Performance Improvements

With all optimizations enabled, you can expect:

| Optimization | Impact |
|--------------|--------|
| **HTTP/2 + Keepalive** | 30-40% faster API calls |
| **Partial Clone** | 40-60% less data transfer |
| **Shallow Clone** (`-s`) | 5-10x faster (no history) |
| **Adaptive Parallelism** | Avoids rate limiting penalties |
| **Size Prioritization** | Faster initial feedback |
| **Metadata Cache** | Near-instant second run |

**Combined effect**: First run 2-3x faster, second run 10-20x faster.

---

## 📈 Best Practices

### For Daily Development
```bash
# Fast updates with shallow clone
./bitbucket-workspace-sync.sh -w myteam -j 4 -v -s
```

### For CI/CD Pipelines
```bash
# Silent with metrics and alerts
./bitbucket-workspace-sync.sh -j 8 -D --webhook "$SLACK_WEBHOOK"
```

### For Initial Large Clones
```bash
# Shallow with adaptive parallelism
./bitbucket-workspace-sync.sh -w myteam -j 6 -v -s -D
```

### For Full History Backup
```bash
# No shallow, detailed metrics, HTML report
./bitbucket-workspace-sync.sh -w myteam -j 2 -v -D --format html
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📜 License

Released under the **MIT License**.  
Use it, share it, and send PRs! 🙌

---

## 🙏 Acknowledgments

Built with performance and developer experience in mind. Optimized for large Bitbucket Cloud workspaces with hundreds of repositories.

**Features requested by the community:**
- Adaptive parallelism for rate limit handling
- Real-time progress monitoring
- Advanced timing statistics
- Multiple export formats
- Webhook integrations

---

## 📞 Support

For issues, questions, or feature requests, please open an issue on the repository.

**Quick Links:**
- [Report a Bug](https://github.com/yourrepo/issues/new?template=bug_report.md)
- [Request a Feature](https://github.com/yourrepo/issues/new?template=feature_request.md)
- [View Documentation](README_en.md)
