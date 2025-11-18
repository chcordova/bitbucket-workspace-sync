#!/usr/bin/env bash
###############################################################################
# Advanced Usage with Metrics
# This example demonstrates shallow clone with detailed metrics and alerts
###############################################################################

# Load credentials
source credentials.txt

# Shallow clone with detailed metrics
# -j 8  : Use 8 parallel workers
# -v    : Verbose output
# -s    : Shallow clone (only latest commit, 5-10x faster)
# -D    : Detailed metrics with statistics
./bitbucket-workspace-sync.sh -j 8 -v -s -D

echo ""
echo "✅ Shallow clone with metrics completed!"
echo "📊 Check the clone_metrics-*.json file for detailed statistics"
