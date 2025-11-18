# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-17

### Added
- ✨ **Adaptive parallelism** with HTTP 429 rate limit detection and auto-adjustment
- 🚀 **HTTP/2 with keepalive** connections for reduced latency
- 💾 **Repository metadata caching** with 1-hour TTL to minimize API calls
- 📊 **Advanced timing statistics**: min/max/avg/median/standard deviation
- 🏥 **Health score calculation** (0-100) for workspace condition assessment
- 📈 **Historical comparison** with previous runs (faster/slower metrics)
- 📤 **Multiple export formats**: JSON, CSV, HTML, Markdown
- 🔔 **Webhook alerts** for Slack and Microsoft Teams integration
- 🎯 **Repository prioritization** by size (small repos first for quick feedback)
- 🪟 **Windows long path support** (automatic `core.longpaths` configuration)
- 🔄 **Real-time progress dashboard** (`.clone_progress` file)
- 📦 **Shallow clone option** (`-s` flag) for 5-10x faster operations
- 🔍 **Category classification** for repository grouping and analysis
- 📋 **Top N slowest repos** identification for performance optimization
- 🎨 **Clean output by default** with optional verbose mode
- 🧪 **Dry-run mode** for testing without making changes
- 📝 **Detailed per-repo metrics** with timing and status tracking
- 🔧 **Configurable ignore patterns** for dirty working tree detection
- 🌐 **API connectivity pre-check** with troubleshooting tips
- 🔁 **Retry logic** with exponential backoff for API calls
- 🚦 **Alert threshold configuration** for error reporting
- 📍 **Progress tracking** across batches with adaptive processing

### Changed
- Improved **API pagination handling** for workspaces with 300+ repositories
- Enhanced **error messages** with actionable troubleshooting steps
- Better **Git configuration** for performance (partial clone, buffer tuning)
- Optimized **parallel processing** with batch-based execution
- Refined **metrics calculation** for accuracy and completeness

### Fixed
- **Repository cache format validation** (supports both object and array formats)
- **Long filename support** on Windows (>260 character paths)
- **curl HTTP/2 auto-detection** for systems without HTTP/2 support
- **Pagination bug** that limited repository discovery to 47 instead of full list
- **Working directory handling** to avoid `getcwd` errors in subshells

### Security
- Credentials passed via environment variables (not command line arguments)
- App password requirement (not plain passwords)
- Secure webhook URL handling

## [0.1.0] - 2025-11-14

### Added
- Initial release with basic clone/update functionality
- Parallel execution with `xargs -P`
- Basic API pagination support
- Simple JSON metrics output
- Verbose mode for debugging

---

## Upcoming Features (Roadmap)

- [ ] Multi-workspace support in single run
- [ ] GitHub integration for cross-platform sync
- [ ] Archive mode for long-term backup
- [ ] Incremental backup with rsync integration
- [ ] Custom hooks for pre/post clone operations
- [ ] Branch filtering and selection
- [ ] LFS support optimization
- [ ] Docker image for containerized execution
- [ ] Web UI for metrics visualization
- [ ] Database export for metrics history

---

[1.0.0]: https://github.com/chcordova/bitbucket-workspace-sync/releases/tag/v1.0.0
[0.1.0]: https://github.com/chcordova/bitbucket-workspace-sync/releases/tag/v0.1.0
