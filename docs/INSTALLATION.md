# Installation Guide

## Prerequisites

Before installing Bitbucket Workspace Sync, ensure you have the following tools installed:

### Required Tools

| Tool     | Minimum Version | Check Command      |
|----------|----------------|--------------------|
| **Bash** | 4.0+           | `bash --version`   |
| **Git**  | Any            | `git --version`    |
| **curl** | Any            | `curl --version`   |
| **jq**   | Any            | `jq --version`     |

---

## Platform-Specific Installation

### macOS

#### Using Homebrew (Recommended)
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install bash git curl jq

# Update to latest Bash (macOS includes old version)
brew install bash
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash

# Verify versions
bash --version  # Should be 5.x
git --version
curl --version
jq --version
```

### Linux

#### Ubuntu/Debian
```bash
# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install -y bash git curl jq

# Verify installation
bash --version
git --version
curl --version
jq --version
```

#### CentOS/RHEL/Fedora
```bash
# Install dependencies
sudo yum install -y bash git curl jq

# Or with dnf (Fedora)
sudo dnf install -y bash git curl jq

# Verify installation
bash --version
git --version
curl --version
jq --version
```

#### Arch Linux
```bash
# Install dependencies (most should already be installed)
sudo pacman -S bash git curl jq

# Verify installation
bash --version
git --version
curl --version
jq --version
```

### Windows

#### Git Bash (Recommended)

1. **Install Git for Windows** (includes Git Bash):
   - Download from: https://git-scm.com/download/win
   - During installation, select "Git Bash Here" option
   - This includes `bash`, `git`, and `curl`

2. **Install jq**:
   - Download from: https://stedolan.github.io/jq/download/
   - Download `jq-win64.exe`
   - Rename to `jq.exe`
   - Move to a directory in your PATH (e.g., `C:\Program Files\Git\usr\bin\`)

3. **Verify installation** (in Git Bash):
   ```bash
   bash --version
   git --version
   curl --version
   jq --version
   ```

#### WSL (Windows Subsystem for Linux)
```bash
# Update and install (same as Ubuntu)
sudo apt-get update
sudo apt-get install -y bash git curl jq
```

---

## Script Installation

### Method 1: Direct Download
```bash
# Download the script
curl -O https://raw.githubusercontent.com/chcordova/bitbucket-workspace-sync/master/bitbucket-workspace-sync.sh

# Make it executable
chmod +x bitbucket-workspace-sync.sh

# Verify it works
./bitbucket-workspace-sync.sh --help
```

### Method 2: Clone Repository
```bash
# Clone the entire repository
git clone https://github.com/chcordova/bitbucket-workspace-sync.git
cd bitbucket-workspace-sync

# Make script executable
chmod +x bitbucket-workspace-sync.sh

# Run it
./bitbucket-workspace-sync.sh --help
```

### Method 3: System-wide Installation
```bash
# Download the script
curl -O https://raw.githubusercontent.com/chcordova/bitbucket-workspace-sync/master/bitbucket-workspace-sync.sh

# Move to system bin directory
sudo mv bitbucket-workspace-sync.sh /usr/local/bin/bitbucket-workspace-sync
sudo chmod +x /usr/local/bin/bitbucket-workspace-sync

# Now you can run it from anywhere
bitbucket-workspace-sync --help
```

---

## Credentials Setup

### Step 1: Create Bitbucket App Password

1. Log in to Bitbucket
2. Click your avatar → **Personal settings**
3. Go to **App passwords** (under Access management)
4. Click **Create app password**
5. Enter a label (e.g., "Workspace Sync")
6. Select permissions:
   - ✅ **Repositories: Read**
   - ✅ **Workspace membership: Read** (optional, for team info)
7. Click **Create**
8. **Copy the password** (you won't be able to see it again!)

### Step 2: Configure Credentials

#### Option A: Environment Variables
```bash
# Add to ~/.bashrc or ~/.bash_profile
export BB_USERNAME="your_username"
export BB_APP_PASSWORD="your_app_password"
export BB_WORKSPACE="your_workspace"

# Reload shell configuration
source ~/.bashrc
```

#### Option B: Credentials File
```bash
# Copy the template
cp examples/credentials.example.txt credentials.txt

# Edit with your credentials
nano credentials.txt
# or
vim credentials.txt

# Load credentials when needed
source credentials.txt
```

#### Option C: Per-Command
```bash
# Set inline (not recommended for scripts)
BB_USERNAME="user" BB_APP_PASSWORD="pass" ./bitbucket-workspace-sync.sh -w workspace -v
```

---

## Verification

### Test Installation
```bash
# Test help display
./bitbucket-workspace-sync.sh --help

# Test with dry-run (no actual cloning)
./bitbucket-workspace-sync.sh -w your_workspace -n -v
```

### Test Credentials
```bash
# Quick test with 1 worker
./bitbucket-workspace-sync.sh -w your_workspace -j 1 -v

# If successful, you'll see:
# 🔌 Testing API connectivity...
# ✅ API connection successful
# 🔍 Fetching repository list from Bitbucket API...
```

---

## Windows-Specific Configuration

### Enable Long Paths

The script automatically tries to enable long paths, but you can do it manually:

```bash
# In Git Bash
git config --global core.longpaths true

# Verify
git config --get core.longpaths  # Should output: true
```

If you get permission errors, run Git Bash as Administrator.

### Path Issues

If the script can't find tools:

```bash
# Check if tools are in PATH
which bash
which git
which curl
which jq

# If jq is missing, ensure it's in:
# C:\Program Files\Git\usr\bin\
# or add its location to PATH
```

---

## Troubleshooting

### "bash: command not found"
- **Linux/Mac**: Install bash using your package manager
- **Windows**: Install Git for Windows

### "jq: command not found"
- **macOS**: `brew install jq`
- **Linux**: `sudo apt-get install jq` or `sudo yum install jq`
- **Windows**: Download from https://stedolan.github.io/jq/

### "Permission denied"
```bash
# Make script executable
chmod +x bitbucket-workspace-sync.sh
```

### "API connection failed"
- Check your credentials
- Verify app password has `repository:read` permission
- Check internet connection
- Verify workspace name is correct

### "Filename too long" (Windows)
```bash
# Enable long paths
git config --global core.longpaths true
```

---

## Next Steps

After successful installation:

1. 📖 Read [Advanced Usage](ADVANCED_USAGE.md) for optimization tips
2. 🔧 Check [Troubleshooting](TROUBLESHOOTING.md) for common issues
3. 🚀 Run your first sync with `-v` flag to see progress
4. 📊 Try `-D` flag to generate detailed metrics

---

## Uninstallation

```bash
# Remove script
rm /usr/local/bin/bitbucket-workspace-sync
# or
rm bitbucket-workspace-sync.sh

# Remove credentials
rm ~/.bitbucket_credentials
# or
unset BB_USERNAME BB_APP_PASSWORD BB_WORKSPACE

# Remove cloned repositories (optional)
rm -rf <workspace_directory>

# Remove git configuration (optional)
git config --global --unset core.longpaths
```

---

## Support

If you encounter issues during installation:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Search [existing issues](../../issues)
3. [Open a new issue](../../issues/new) with:
   - Your OS and version
   - Output of `bash --version`, `git --version`, `jq --version`
   - Complete error message
