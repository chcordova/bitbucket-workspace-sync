#!/usr/bin/env bash
###############################################################################
# Basic Usage Example
# This example shows the most common use case for bitbucket-workspace-sync
###############################################################################

# Load credentials
source credentials.txt

# Clone/update all repositories with 4 parallel workers
# -j 4  : Use 4 parallel workers
# -v    : Verbose output (show progress per repo)
./bitbucket-workspace-sync.sh -j 4 -v

echo ""
echo "✅ Basic clone/update completed!"
echo "📁 Repositories are in: ./$BB_WORKSPACE/"
