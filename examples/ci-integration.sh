#!/usr/bin/env bash
###############################################################################
# CI/CD Integration Example
# This example shows how to use the script in a CI/CD pipeline
###############################################################################

set -e  # Exit on error

# Credentials should be set as environment variables in your CI/CD system
# BB_USERNAME, BB_APP_PASSWORD, BB_WORKSPACE

# Check required environment variables
if [[ -z "$BB_USERNAME" || -z "$BB_APP_PASSWORD" || -z "$BB_WORKSPACE" ]]; then
  echo "❌ Error: Required environment variables not set"
  echo "   BB_USERNAME, BB_APP_PASSWORD, BB_WORKSPACE must be defined"
  exit 1
fi

# Create a dedicated directory for clones
CLONE_DIR="ci-workspace-backup"
mkdir -p "$CLONE_DIR"

# Run with:
# - Shallow clone for speed
# - Detailed metrics for reporting
# - JSON format for parsing
# - Webhook alerts for failures
./bitbucket-workspace-sync.sh \
  -w "$BB_WORKSPACE" \
  -d "$CLONE_DIR" \
  -j 8 \
  -s \
  -D \
  --format json \
  --webhook "${BB_ALERT_WEBHOOK:-}"

# Parse results
METRICS_FILE=$(ls -t "$CLONE_DIR"/clone_metrics-*.json | head -1)

if [[ -f "$METRICS_FILE" ]]; then
  echo "📊 Metrics generated: $METRICS_FILE"
  
  # Extract key metrics using jq
  ERRORS=$(jq -r '.totals.errors // 0' "$METRICS_FILE")
  HEALTH_SCORE=$(jq -r '.health_score // 0' "$METRICS_FILE")
  
  echo "🏥 Health Score: $HEALTH_SCORE/100"
  echo "❌ Errors: $ERRORS"
  
  # Fail if too many errors
  if [[ $ERRORS -gt 5 ]]; then
    echo "❌ Too many errors detected ($ERRORS)"
    exit 1
  fi
  
  # Fail if health score too low
  if [[ $HEALTH_SCORE -lt 90 ]]; then
    echo "⚠️  Health score below threshold ($HEALTH_SCORE < 90)"
    exit 1
  fi
fi

echo "✅ CI/CD sync completed successfully!"
