# Troubleshooting Guide

Common issues and solutions for Bitbucket Workspace Sync.

---

## Table of Contents

- [Installation Issues](#installation-issues)
- [Credential Issues](#credential-issues)
- [API Connection Issues](#api-connection-issues)
- [Git Clone Issues](#git-clone-issues)
- [Performance Issues](#performance-issues)
- [Windows-Specific Issues](#windows-specific-issues)
- [Error Messages](#error-messages)

---

## Installation Issues

### "bash: command not found"

**Problem**: Bash is not installed or not in PATH

**Solution**:
```bash
# macOS
brew install bash

# Ubuntu/Debian
sudo apt-get install bash

# Windows: Install Git for Windows
# https://git-scm.com/download/win
```

### "jq: command not found"

**Problem**: jq JSON processor not installed

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows
# Download from: https://stedolan.github.io/jq/download/
# Place jq.exe in C:\Program Files\Git\usr\bin\
```

### "Permission denied" when running script

**Problem**: Script is not executable

**Solution**:
```bash
chmod +x bitbucket-workspace-sync.sh
```

---

## Credential Issues

### "❌ Failed to connect to Bitbucket API"

**Problem**: Invalid credentials or permissions

**Solutions**:

1. **Verify credentials are set**:
   ```bash
   echo $BB_USERNAME
   echo $BB_APP_PASSWORD  # Will show the password
   echo $BB_WORKSPACE
   ```

2. **Check app password permissions**:
   - Go to Bitbucket → Settings → App passwords
   - Verify the password has `repository:read` permission
   - If not, create a new app password

3. **Test API manually**:
   ```bash
   curl -u "$BB_USERNAME:$BB_APP_PASSWORD" \
     "https://api.bitbucket.org/2.0/repositories/$BB_WORKSPACE?pagelen=1"
   ```

4. **Common mistakes**:
   - Using regular password instead of app password
   - Typo in username or workspace name
   - App password expired or deleted
   - Wrong workspace (use workspace slug, not display name)

### "HTTP 401 Unauthorized"

**Problem**: Invalid username or app password

**Solution**:
1. Verify BB_USERNAME matches your Bitbucket username
2. Generate a new app password:
   - Bitbucket → Settings → App passwords → Create
   - Select "repository:read" permission
   - Copy the generated password
3. Update your credentials

### "HTTP 403 Forbidden"

**Problem**: App password lacks required permissions

**Solution**:
1. Go to Bitbucket → Settings → App passwords
2. Find your app password and check permissions
3. Ensure "Repositories: Read" is enabled
4. If not, create a new app password with correct permissions

### "HTTP 404 Not Found"

**Problem**: Workspace doesn't exist or wrong workspace name

**Solution**:
1. Verify workspace slug (not display name)
2. Check URL in browser: `https://bitbucket.org/WORKSPACE_NAME`
3. Update BB_WORKSPACE with correct slug

---

## API Connection Issues

### "Connection timeout" or "Network error"

**Problem**: Network connectivity issues

**Solutions**:

1. **Check internet connection**:
   ```bash
   ping bitbucket.org
   ```

2. **Check if behind proxy**:
   ```bash
   # Set proxy if needed
   export http_proxy="http://proxy:port"
   export https_proxy="http://proxy:port"
   ```

3. **Test API directly**:
   ```bash
   curl -v "https://api.bitbucket.org/2.0/repositories/$BB_WORKSPACE?pagelen=1"
   ```

4. **Check firewall**:
   - Ensure outbound HTTPS (port 443) is allowed
   - Some corporate networks block Git protocols

### "HTTP 429 Too Many Requests"

**Problem**: Rate limiting from Bitbucket API

**Solution**:
- The script handles this automatically with adaptive parallelism
- If you disabled adaptive mode, enable it (remove `--no-adaptive`)
- Reduce parallel jobs: `-j 2` instead of `-j 8`
- Wait a few minutes before retrying

### "Only found 47 repositories, expected 300+"

**Problem**: API pagination not working correctly

**Solution**:
1. Update to latest version of the script
2. Clear cache:
   ```bash
   rm -f ./$BB_WORKSPACE/.repo_cache.json
   ```
3. Run again with verbose mode:
   ```bash
   ./bitbucket-workspace-sync.sh -w $BB_WORKSPACE -v
   ```

---

## Git Clone Issues

### "error: unable to create file ...: Filename too long"

**Problem**: Windows path length limit (260 characters)

**Solution**:
```bash
# Enable long paths (script does this automatically)
git config --global core.longpaths true

# Verify
git config --get core.longpaths  # Should output: true

# If still fails, run Git Bash as Administrator and retry
```

### "fatal: repository not found"

**Problem**: Repository doesn't exist or no read access

**Solutions**:
1. Verify you have read access to the repository
2. Check if repository was deleted
3. Repository might be archived
4. Script continues with other repos

### "fatal: Authentication failed"

**Problem**: Git can't authenticate to Bitbucket

**Solution**:
```bash
# Git should use credentials from environment
# Verify credentials are loaded
echo $BB_USERNAME
echo $BB_APP_PASSWORD

# If empty, source credentials:
source credentials.txt
```

### "warning: You appear to have cloned an empty repository"

**Problem**: Repository has no commits

**Solution**:
- This is just a warning, not an error
- The script continues normally
- Empty repos can't be updated until they have commits

### Clone is extremely slow

**Problem**: Large repository or slow network

**Solutions**:

1. **Use shallow clone** (recommended):
   ```bash
   ./bitbucket-workspace-sync.sh -s -v
   ```

2. **Reduce parallel jobs**:
   ```bash
   ./bitbucket-workspace-sync.sh -j 2 -v
   ```

3. **Check network speed**:
   ```bash
   # Test download speed
   curl -o /dev/null https://bitbucket.org/
   ```

4. **Use partial clone** (already enabled in script):
   - The script automatically uses `--filter=blob:none`
   - This downloads only necessary files initially

---

## Performance Issues

### Script is slower than expected

**Checklist**:

1. **Use shallow clone**:
   ```bash
   ./bitbucket-workspace-sync.sh -s
   ```

2. **Increase parallel jobs** (if network allows):
   ```bash
   ./bitbucket-workspace-sync.sh -j 8
   ```

3. **Clear old cache**:
   ```bash
   rm -f ./$BB_WORKSPACE/.repo_cache.json
   ```

4. **Check CPU and network usage**:
   ```bash
   # Linux/macOS
   top
   # Windows
   Task Manager
   ```

5. **Disable detailed metrics** (for faster execution):
   ```bash
   # Use default (no metrics)
   ./bitbucket-workspace-sync.sh -j 6 -v
   ```

### High CPU usage

**Problem**: Too many parallel jobs

**Solution**:
```bash
# Reduce parallel jobs
./bitbucket-workspace-sync.sh -j 2 -v

# Or let adaptive parallelism handle it
./bitbucket-workspace-sync.sh -j 4 -v  # Remove --no-adaptive
```

### Hitting rate limits frequently

**Problem**: Too many API requests

**Solutions**:
1. Use cache (automatically enabled, 1-hour TTL)
2. Reduce parallel jobs: `-j 2` or `-j 4`
3. Enable adaptive parallelism (default, don't use `--no-adaptive`)
4. Check if cache is being used:
   ```bash
   ls -la ./$BB_WORKSPACE/.repo_cache.json
   ```

---

## Windows-Specific Issues

### "bash: ./bitbucket-workspace-sync.sh: /usr/bin/env: bad interpreter"

**Problem**: Line endings are CRLF instead of LF

**Solution**:
```bash
# Convert line endings
dos2unix bitbucket-workspace-sync.sh

# Or in Git Bash
sed -i 's/\r$//' bitbucket-workspace-sync.sh
```

### Path length issues persist after enabling core.longpaths

**Problem**: Windows Group Policy might override setting

**Solutions**:

1. **Run Git Bash as Administrator**
2. **Enable via Registry** (Windows 10 1607+):
   - Run as Administrator: `regedit`
   - Navigate to: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem`
   - Set `LongPathsEnabled` to `1`
   - Restart computer

3. **Use shorter base path**:
   ```bash
   # Instead of deep path
   ./bitbucket-workspace-sync.sh -d /d/repos/workspace
   
   # Use shorter path
   ./bitbucket-workspace-sync.sh -d /d/w
   ```

### "watch: command not found" for progress monitoring

**Problem**: `watch` command not available in Git Bash

**Solution**:
```bash
# Use this alternative in Git Bash
cd /path/to/workspace
while true; do clear; cat .clone_progress 2>/dev/null || echo "Waiting..."; sleep 1; done

# Or in PowerShell
while ($true) { Clear-Host; Get-Content .clone_progress -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }
```

---

## Error Messages

### "jq: error (at <stdin>:1): Cannot index array with string"

**Problem**: Cache file format mismatch

**Solution**:
```bash
# Remove cache file
rm -f ./$BB_WORKSPACE/.repo_cache.json

# Run again
./bitbucket-workspace-sync.sh -v
```

### "Cannot create directory: File exists"

**Problem**: File with same name as repo directory exists

**Solution**:
```bash
# Check what's blocking
ls -la ./$BB_WORKSPACE/

# Remove or rename the conflicting file
mv ./$BB_WORKSPACE/conflicting-file ./$BB_WORKSPACE/conflicting-file.bak
```

### "Working tree has uncommitted changes"

**Problem**: Repository has local modifications

**Solution**:

1. **Review changes**:
   ```bash
   cd ./$BB_WORKSPACE/repo-name
   git status
   ```

2. **Options**:
   ```bash
   # Option A: Commit changes
   git add .
   git commit -m "Local changes"
   
   # Option B: Stash changes
   git stash
   
   # Option C: Discard changes (DANGER)
   git reset --hard
   ```

3. **Exclude certain files from dirty check**:
   ```bash
   export BB_IGNORE_PATTERN="\.log$|/target/|node_modules/"
   ./bitbucket-workspace-sync.sh -v
   ```

---

## Getting More Help

If your issue isn't listed here:

1. **Enable verbose mode** for detailed output:
   ```bash
   ./bitbucket-workspace-sync.sh -v
   ```

2. **Test with dry-run**:
   ```bash
   ./bitbucket-workspace-sync.sh -n -v
   ```

3. **Check script version**:
   ```bash
   grep "^# Version:" bitbucket-workspace-sync.sh
   ```

4. **Search existing issues**:
   - https://github.com/chcordova/bitbucket-workspace-sync/issues

5. **Open new issue** with:
   - OS and version
   - Bash, Git, curl, jq versions
   - Complete error message
   - Steps to reproduce
   - Command used (remove credentials)

6. **Community support**:
   - GitHub Discussions
   - Stack Overflow (tag: `bitbucket-workspace-sync`)

---

## Debug Mode

For maximum verbosity:

```bash
# Enable bash debug mode
bash -x bitbucket-workspace-sync.sh -w workspace -j 2 -v 2>&1 | tee debug.log

# This will show every command executed
# Send debug.log when reporting issues
```

---

<p align="center">
  <a href="../README.md">⬆️ Back to README</a>
</p>
