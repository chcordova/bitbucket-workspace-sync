#!/usr/bin/env bash
###############################################################################
# bitbucket_workspace_clone.sh
# ---------------------------------------------------------------------------
# Clone or fast-forward update **all** repositories in a Bitbucket Cloud
# workspace (API v2).
#
# FEATURES
#   • Parallel initial clone & fast-forward update.
#   • Detects dirty working trees, supports dry-run and optional verbose output.
#   • Generates compact JSON metrics (-m) or per-repo detailed metrics (-D).
#
# REQUIREMENTS: Bash ≥ 4 · git · curl · jq
#
# CREDENTIALS (required):
#   export BB_USERNAME="your_username"
#   export BB_APP_PASSWORD="your_app_password"
#   export BB_WORKSPACE="my_workspace"   # or pass -w
###############################################################################

# --------------------------------------------------------------------------- #
# Global variables (populated only from env or CLI flags)
# --------------------------------------------------------------------------- #
BB_USERNAME="${BB_USERNAME:-}"
BB_APP_PASSWORD="${BB_APP_PASSWORD:-}"
BB_WORKSPACE="${BB_WORKSPACE:-}"
TARGET_CLONE_DIR=""               # resolved after flag parsing

PAGE_LEN=100
JOBS=4
VERBOSE=false
DRY_RUN=false
GENERATE_METRICS=false
DETAILED_JSON=false
SHALLOW_CLONE=false
ADAPTIVE_PARALLELISM=true
RATE_LIMIT_DETECTED=false
ORIGINAL_JOBS=4
EXPORT_FORMAT="json"  # json, csv, html, markdown
ALERT_WEBHOOK="${BB_ALERT_WEBHOOK:-}"  # Slack/Teams webhook URL
ALERT_THRESHOLD_ERRORS=3  # Alert if errors >= this
DEFAULT_IGNORE='\.DS_Store$|\.idea/|\.vscode/|\.classpath$|\.project$|\.settings/'
IGNORE_REGEX="${BB_IGNORE_PATTERN:-$DEFAULT_IGNORE}"

# --------------------------------------------------------------------------- #
# Usage helper
# --------------------------------------------------------------------------- #
usage() {
cat <<EOF
Usage: $0 [options]

Required environment variables:
  BB_USERNAME       Bitbucket username
  BB_APP_PASSWORD   Bitbucket app password
  (BB_WORKSPACE)    Workspace ID (or use -w)

Options
  -w, --workspace <id>   Workspace ID (overrides \$BB_WORKSPACE)
  -d, --dir <path>       Destination folder (default: \$PWD/<workspace>)
  -j, --jobs <n>         Parallel jobs (default: $JOBS)
  -v, --verbose          Show per-repo progress
  -n, --dry-run          List actions only; do not touch Git
  -s, --shallow          Shallow clone (only latest commit, much faster)
      --no-adaptive      Disable adaptive parallelism (auto-reduce jobs on rate limit)
  -m, --metrics          Produce compact JSON metrics
  -D, --detailed         Produce detailed per-repo metrics (implies -m)
      --no-metrics       Disable metrics (default)
      --format <fmt>     Export format: json|csv|html|markdown (default: json)
      --webhook <url>    Webhook URL for alerts (Slack/Teams)
  -i, --ignore "<regex>" Regex of local changes to ignore
  -h, --help             Show this help and exit

Quick start:
  export BB_USERNAME="alice"
  export BB_APP_PASSWORD="s3cr3t"
  ./bitbucket_workspace_clone.sh -w myteam -v
EOF
exit 0
}

# --------------------------------------------------------------------------- #
# Flag parsing
# --------------------------------------------------------------------------- #
while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--workspace) BB_WORKSPACE="$2";   shift 2;;
    -d|--dir)       TARGET_CLONE_DIR="$2"; shift 2;;
    -j|--jobs)      JOBS="$2";           shift 2;;
    -v|--verbose)   VERBOSE=true;        shift;;
    -n|--dry-run)   DRY_RUN=true;        shift;;
    -s|--shallow)   SHALLOW_CLONE=true;  shift;;
    --no-adaptive)  ADAPTIVE_PARALLELISM=false; shift;;
    -m|--metrics)   GENERATE_METRICS=true; shift;;
    --no-metrics)   GENERATE_METRICS=false; shift;;
    --format)       EXPORT_FORMAT="$2"; shift 2;;
    --webhook)      ALERT_WEBHOOK="$2"; shift 2;;
    -D|--detailed)  DETAILED_JSON=true; GENERATE_METRICS=true; shift;;
    -i|--ignore)    IGNORE_REGEX="$2";   shift 2;;
    -h|--help)      usage;;
    *) echo "❌ Unknown option: $1"; usage;;
  esac
done

# Validate --jobs ------------------------------------------
[[ $JOBS =~ ^[1-9][0-9]*$ ]] || {
  echo "❌ --jobs must be an integer greater than 0 (e.g. -j 4)"; exit 1;
}
ORIGINAL_JOBS=$JOBS

# --------------------------------------------------------------------------- #
# Credential validation
# --------------------------------------------------------------------------- #
if [[ -z $BB_USERNAME || -z $BB_APP_PASSWORD ]]; then
cat >&2 <<'ERR'
❌ Missing Bitbucket credentials.

Example:
  export BB_USERNAME="your_username"
  export BB_APP_PASSWORD="your_app_password"
  export BB_WORKSPACE="my_workspace"   # or pass -w
  ./bitbucket_workspace_clone.sh -v
ERR
  exit 1
fi
[[ -z $BB_WORKSPACE ]] && { echo "❌ BB_WORKSPACE is missing. Set it or use -w."; exit 1; }

# --------------------------------------------------------------------------- #
# Resolve destination directory
# --------------------------------------------------------------------------- #
[[ -z $TARGET_CLONE_DIR ]] && TARGET_CLONE_DIR="$PWD/$BB_WORKSPACE"
TARGET_CLONE_DIR="${TARGET_CLONE_DIR/#\~/$HOME}"

# --------------------------------------------------------------------------- #
# Basic checks
# --------------------------------------------------------------------------- #
((BASH_VERSINFO[0] >= 4)) || { echo "❌ Bash 4 or newer is required." >&2; exit 1; }
for cmd in git curl jq; do command -v "$cmd" >/dev/null || { echo "❌ $cmd is required."; exit 1; }; done
mkdir -p "$TARGET_CLONE_DIR" || { echo "❌ Cannot create $TARGET_CLONE_DIR"; exit 1; }

# --------------------------------------------------------------------------- #
# Detect curl capabilities
# --------------------------------------------------------------------------- #
CURL_SUPPORTS_HTTP2=false
CURL_SUPPORTS_KEEPALIVE=false

if curl --version 2>/dev/null | grep -q "HTTP2"; then
  CURL_SUPPORTS_HTTP2=true
fi

if curl --help all 2>/dev/null | grep -q "keepalive-time"; then
  CURL_SUPPORTS_KEEPALIVE=true
fi

# --------------------------------------------------------------------------- #
# Display configuration
# --------------------------------------------------------------------------- #
echo "Workspace : $BB_WORKSPACE"
echo "Target    : $TARGET_CLONE_DIR"
echo "Parallel  : $JOBS"
echo "User      : $BB_USERNAME"
$ADAPTIVE_PARALLELISM && echo "Adaptive  : enabled (auto-adjust on rate limit)"
$SHALLOW_CLONE && echo "Mode      : shallow (fast clone)"
$DRY_RUN       && echo "Mode      : dry-run"
$DETAILED_JSON && echo "Report    : detailed (per-repo)"
$GENERATE_METRICS || echo "Metrics   : disabled"
echo "Ignore RE : $IGNORE_REGEX"
echo "────────────────────────────────────────────"

# --------------------------------------------------------------------------- #
# cURL helper with retries
# --------------------------------------------------------------------------- #
retry_curl() {
  local url=$1 retries=3 delay=2 attempt=1 body code curl_exit
  
  # Build curl command with supported flags
  local curl_cmd="curl -s -u \"${BB_USERNAME}:${BB_APP_PASSWORD}\""
  $CURL_SUPPORTS_HTTP2 && curl_cmd="$curl_cmd --http2"
  $CURL_SUPPORTS_KEEPALIVE && curl_cmd="$curl_cmd --keepalive-time 60"
  curl_cmd="$curl_cmd --write-out \"HTTP_STATUS:%{http_code}\""
  
  while (( attempt <= retries )); do
    # Execute curl and capture both output and exit code
    body=$(eval "$curl_cmd \"$url\" 2>&1")
    curl_exit=$?
    
    # Check if curl command failed completely
    if [[ $curl_exit -ne 0 ]]; then
      echo "❌ curl failed (exit code: $curl_exit)" >&2
      echo "   Command: $curl_cmd \"$url\"" >&2
      echo "   Output: ${body:0:200}" >&2
      if [[ $attempt -lt $retries ]]; then
        echo "   Retrying ($attempt/$retries)..." >&2
        (( attempt++ )); sleep $(( delay ** attempt ))
        continue
      else
        return 1
      fi
    fi
    
    # Extract HTTP status code
    code=${body##*HTTP_STATUS:}; body=${body%HTTP_STATUS:*}
    
    # Check if we got a valid HTTP code
    if [[ ! $code =~ ^[0-9]+$ ]]; then
      echo "❌ Invalid HTTP response (no status code)" >&2
      echo "   Response: ${body:0:200}" >&2
      return 1
    fi
    
    # Success
    [[ $code =~ ^2 ]] && { printf '%s' "$body"; return 0; }
    
    # Handle specific error codes
    if [[ $code == 429 ]]; then
      RATE_LIMIT_DETECTED=true
      echo "⚠️  HTTP 429 (rate limit) – retry $attempt/$retries…" >&2
    elif [[ $code =~ ^(401|403) ]]; then
      echo "❌ HTTP $code (authentication/authorization failed)" >&2
      echo "   Check BB_USERNAME and BB_APP_PASSWORD" >&2
      return 1
    elif [[ $code == 404 ]]; then
      echo "❌ HTTP 404 (workspace not found: $BB_WORKSPACE)" >&2
      return 1
    elif [[ $code =~ ^5 ]]; then
      echo "⚠️  HTTP $code (server error) – retry $attempt/$retries…" >&2
    else
      echo "❌ HTTP $code (unexpected error)" >&2
      return 1
    fi
    
    (( attempt++ )); sleep $(( delay ** attempt ))
  done
  
  echo "❌ Failed after $retries retries" >&2
  return 1
}

# --------------------------------------------------------------------------- #
# Helper functions
# --------------------------------------------------------------------------- #
if ! $VERBOSE; then print_status(){ :; }
else                print_status(){ printf "· %-35s %-25s %4ss\n" "$1" "$2" "${3:-0}" >&2; }
fi
is_dirty() { git -C "$1" status -s | grep -Ev "$IGNORE_REGEX" -q; }

# --------------------------------------------------------------------------- #
# Test API connectivity (quick sanity check)
# --------------------------------------------------------------------------- #
echo "🔌 Testing API connectivity..."
TEST_URL="https://api.bitbucket.org/2.0/repositories/${BB_WORKSPACE}?pagelen=1"
if ! test_response=$(retry_curl "$TEST_URL" 2>&1); then
  echo "❌ Failed to connect to Bitbucket API" >&2
  echo "" >&2
  echo "Troubleshooting tips:" >&2
  echo "  1. Verify internet connection" >&2
  echo "  2. Check BB_USERNAME is correct: '$BB_USERNAME'" >&2
  echo "  3. Check BB_APP_PASSWORD is valid" >&2
  echo "  4. Verify workspace name: '$BB_WORKSPACE'" >&2
  echo "  5. Ensure app password has 'repository:read' scope" >&2
  exit 1
fi
echo "✅ API connection successful"

# --------------------------------------------------------------------------- #
# Configure Git for long paths (Windows compatibility)
# --------------------------------------------------------------------------- #
echo "⚙️  Configuring Git for long paths..."
if git config --global core.longpaths true 2>/dev/null; then
  echo "✅ Git configured: core.longpaths = true"
else
  echo "⚠️  Could not configure core.longpaths (may require elevated permissions)"
fi

# Also set protectNTFS for better Windows compatibility
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
  git config --global core.protectNTFS false 2>/dev/null
fi

# --------------------------------------------------------------------------- #
# Retrieve repo list with caching
# --------------------------------------------------------------------------- #
CACHE_FILE="${TARGET_CLONE_DIR}/.repo_cache.json"
CACHE_MAX_AGE=3600  # 1 hour

declare -a REPOS
declare -A REPO_SIZES  # For prioritization

if [[ -f $CACHE_FILE ]]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
    # Detect cache format (old format has .values, new is direct array)
    cache_type=$(jq -r 'type' "$CACHE_FILE" 2>/dev/null)
    
    if [[ $cache_type == "object" ]]; then
      # Old format: {"values": [...]}
      cache_count=$(jq '.values | length' "$CACHE_FILE" 2>/dev/null || echo 0)
      if [[ $cache_count -gt 0 ]]; then
        echo "📦 Using cached repository list (${cache_age}s old, $cache_count repos)"
        mapfile -t REPOS < <(jq -r '.values[].slug' "$CACHE_FILE" 2>/dev/null | sed 's/[<>:"|?*\\\/]//g')
        # Load sizes for prioritization
        while IFS='|' read -r slug size; do
          REPO_SIZES["$slug"]=$size
        done < <(jq -r '.values[] | "\(.slug)|\(.size // 0)"' "$CACHE_FILE" 2>/dev/null)
      else
        echo "⚠️  Cache is empty, fetching fresh data..."
        rm -f "$CACHE_FILE"
      fi
    elif [[ $cache_type == "array" ]]; then
      # New format: [...]
      cache_count=$(jq 'length' "$CACHE_FILE" 2>/dev/null || echo 0)
      if [[ $cache_count -gt 0 ]]; then
        echo "📦 Using cached repository list (${cache_age}s old, $cache_count repos)"
        mapfile -t REPOS < <(jq -r '.[].slug' "$CACHE_FILE" 2>/dev/null | sed 's/[<>:"|?*\\\/]//g')
        # Load sizes for prioritization
        while IFS='|' read -r slug size; do
          REPO_SIZES["$slug"]=$size
        done < <(jq -r '.[] | "\(.slug)|\(.size // 0)"' "$CACHE_FILE" 2>/dev/null)
      else
        echo "⚠️  Cache is empty, fetching fresh data..."
        rm -f "$CACHE_FILE"
      fi
    else
      echo "⚠️  Invalid cache format, fetching fresh data..."
      rm -f "$CACHE_FILE"
    fi
  else
    echo "⚠️  Cache expired, fetching fresh data..."
    rm -f "$CACHE_FILE"
  fi
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "🔍 Fetching repository list from Bitbucket API..."
  API_URL="https://api.bitbucket.org/2.0/repositories/${BB_WORKSPACE}?pagelen=${PAGE_LEN}"
  
  # Create temp file for accumulating repos
  TEMP_REPOS=$(mktemp)
  echo "[]" > "$TEMP_REPOS"
  page_num=1
  
  while [[ -n $API_URL ]]; do
    echo "   Fetching page $page_num..."
    page=$(retry_curl "$API_URL") || exit 1
    
    # Extract just the values array from this page
    page_repos=$(jq '.values' <<< "$page")
    page_count=$(jq 'length' <<< "$page_repos")
    echo "   Got $page_count repositories from page $page_num"
    
    # Append to accumulated repos (proper array concatenation)
    # Use printf to pass both arrays to jq -s on stdin
    combined=$(printf '%s\n%s' "$(cat "$TEMP_REPOS")" "$page_repos" | jq -s '.[0] + .[1]')
    echo "$combined" > "$TEMP_REPOS"
    
    # Get next page URL
    API_URL=$(jq -r '.next // empty' <<< "$page")
    
    if [[ -n $API_URL ]]; then
      ((page_num++))
    fi
  done
  
  # Read final result
  full_data=$(cat "$TEMP_REPOS")
  rm -f "$TEMP_REPOS"
  
  # Count total
  total_fetched=$(jq 'length' <<< "$full_data")
  echo "✅ Total repositories fetched: $total_fetched"
  
  # Save cache
  echo "$full_data" > "$CACHE_FILE"
  
  # Extract slugs and sizes
  mapfile -t REPOS < <(jq -r '.[].slug' "$CACHE_FILE" | sed 's/[<>:"|?*\\\/]//g')
  while IFS='|' read -r slug size; do
    REPO_SIZES["$slug"]=$size
  done < <(jq -r '.[] | "\(.slug)|\(.size // 0)"' "$CACHE_FILE")
fi

TOTAL=${#REPOS[@]}
echo "Repositories found: $TOTAL"

# Validate we have repos to process
if [[ $TOTAL -eq 0 ]]; then
  echo "⚠️  No repositories found in workspace '$BB_WORKSPACE'"
  echo "   Possible causes:"
  echo "   • Workspace name is incorrect"
  echo "   • No repositories exist in this workspace"
  echo "   • Credentials don't have access to this workspace"
  echo "   • API returned empty result"
  exit 0
fi

# --------------------------------------------------------------------------- #
# Prioritize by size (small repos first for faster feedback)
# --------------------------------------------------------------------------- #
if [[ ${#REPO_SIZES[@]} -gt 0 ]]; then
  echo "🎯 Prioritizing repositories by size (small first)..."
  mapfile -t REPOS < <(
    for repo in "${REPOS[@]}"; do
      size=${REPO_SIZES[$repo]:-999999999}  # Unknown size goes last
      echo "$size|$repo"
    done | sort -n | cut -d'|' -f2
  )
fi

$DRY_RUN && printf '%s\n' "${REPOS[@]}" && exit 0

# --------------------------------------------------------------------------- #
# Clone or update function
# --------------------------------------------------------------------------- #
clone_or_update() {
  local repo=$1
  [[ -z $repo ]] && { print_status "<empty>" "🛑 empty slug"; echo "ERROR"; return; }

  cd "$TARGET_CLONE_DIR" 2>/dev/null || cd "$HOME"

  # Repo name is already sanitized when retrieved from API
  local dst="${TARGET_CLONE_DIR}/${repo}"
  local auth="https://${BB_USERNAME}:${BB_APP_PASSWORD}@bitbucket.org/${BB_WORKSPACE}/${repo}.git"
  local start=$SECONDS state token

  # --- Clone -----------------------------------------------------------------
  if [[ ! -d $dst/.git ]]; then
    if $DRY_RUN; then state="would clone"; token="DRY"
    else
      # Build optimized git clone command
      local clone_cmd="GIT_TERMINAL_PROMPT=0 git clone --quiet"
      
      # Shallow clone if requested
      $SHALLOW_CLONE && clone_cmd="$clone_cmd --depth 1 --single-branch"
      
      # Performance optimizations
      clone_cmd="$clone_cmd --config transfer.fsckobjects=false"
      clone_cmd="$clone_cmd --config receive.fsckobjects=false"
      clone_cmd="$clone_cmd --config fetch.fsckobjects=false"
      clone_cmd="$clone_cmd --config core.compression=0"  # No compression during transfer
      clone_cmd="$clone_cmd --config http.postBuffer=524288000"  # 500MB buffer
      
      # Use HTTP/2 only if curl supports it (git uses libcurl)
      if $CURL_SUPPORTS_HTTP2; then
        clone_cmd="$clone_cmd --config http.version=HTTP/2"
      fi
      
      # Partial clone for very large repos (fetches trees but not all blobs)
      # Only if not shallow (shallow already minimizes data)
      if ! $SHALLOW_CLONE; then
        clone_cmd="$clone_cmd --filter=blob:none"
      fi
      
      eval "$clone_cmd \"$auth\" \"$dst\"" \
        && { state="cloned"; token="CLONED"; } \
        || { state="❌ clone failed"; token="ERROR"; }
    fi
    local elapsed=$((SECONDS - start))
    print_status "$repo" "$state" "$elapsed"
    build_detail "$repo" "$token" "$elapsed"
    echo "$token"; return
  fi

  # --- Dirty -----------------------------------------------------------------
  if is_dirty "$dst"; then
    state="local changes – skipped"; token="DIRTY"
    local elapsed=$((SECONDS - start))
    print_status "$repo" "$state" "$elapsed"
    build_detail "$repo" "$token" "$elapsed"
    echo "$token"; return
  fi

  # --- Main branch detection --------------------------------------------------
  local branch
  branch=$(git -C "$dst" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  branch=${branch#origin/}
  [[ -z $branch ]] && git -C "$dst" show-ref -q refs/heads/main   && branch=main
  [[ -z $branch ]] && git -C "$dst" show-ref -q refs/heads/master && branch=master
  if [[ -z $branch ]]; then
    local elapsed=$((SECONDS - start))
    print_status "$repo" "no default branch – skipped" "$elapsed"
    build_detail "$repo" "SKIPPED" "$elapsed"
    echo "SKIPPED"; return
  fi

  # --- Fast-forward update ----------------------------------------------------
  local before after
  before=$(git -C "$dst" rev-parse HEAD)
  git -C "$dst" fetch --quiet
  git -C "$dst" merge --ff-only "origin/$branch" --quiet 2>/dev/null || true
  after=$(git -C "$dst" rev-parse HEAD)
  if [[ $before == $after ]]; then
    state="unchanged"; token="UNCHANGED"
  else
    state="updated"; token="UPDATED"
  fi
  local elapsed=$((SECONDS - start))
  print_status "$repo" "$state" "$elapsed"
  build_detail "$repo" "$token" "$elapsed"
  echo "$token"
}

build_detail() {
  $DETAILED_JSON || return 0
  printf '{"repo":"%s","result":"%s","sec":%s}\n' "$1" "$2" "$3" >> "$METRICS_TMP"
}

adjust_parallelism() {
  if ! $ADAPTIVE_PARALLELISM || [[ $JOBS -le 1 ]]; then return; fi
  if $RATE_LIMIT_DETECTED; then
    local new_jobs=$((JOBS / 2))
    [[ $new_jobs -lt 1 ]] && new_jobs=1
    if [[ $new_jobs -lt $JOBS ]]; then
      echo "⚡ Rate limit detected - reducing parallelism: $JOBS → $new_jobs workers" >&2
      JOBS=$new_jobs
      RATE_LIMIT_DETECTED=false
      sleep 5  # Brief pause to let rate limit reset
    fi
  fi
}

# --------------------------------------------------------------------------- #
# Prepare exports for xargs
# --------------------------------------------------------------------------- #
METRICS_TMP=$(mktemp)
export METRICS_TMP
export -f clone_or_update is_dirty print_status build_detail adjust_parallelism
export BB_USERNAME BB_APP_PASSWORD BB_WORKSPACE TARGET_CLONE_DIR \
       IGNORE_REGEX DRY_RUN DETAILED_JSON VERBOSE SHALLOW_CLONE \
       ADAPTIVE_PARALLELISM RATE_LIMIT_DETECTED CURL_SUPPORTS_HTTP2 CURL_SUPPORTS_KEEPALIVE

# --------------------------------------------------------------------------- #
# Parallel processing with adaptive parallelism
# --------------------------------------------------------------------------- #
PROGRESS_FILE="${TARGET_CLONE_DIR}/.clone_progress"
echo "0/$TOTAL (0%)" > "$PROGRESS_FILE"

if $ADAPTIVE_PARALLELISM; then
  # Process in batches with dynamic adjustment
  BATCH_SIZE=20
  TOKENS=()
  processed=0
  
  for ((i=0; i<TOTAL; i+=BATCH_SIZE)); do
    batch=("${REPOS[@]:i:BATCH_SIZE}")
    batch_size=${#batch[@]}
    
    # Check if we need to adjust parallelism
    adjust_parallelism
    
    mapfile -t batch_tokens < <(
      printf '%s\n' "${batch[@]}" |
      xargs -P "$JOBS" -I{} bash -c \
        'cd "$TARGET_CLONE_DIR" 2>/dev/null || cd "$HOME"; clone_or_update "$1"' _ {}
    )
    TOKENS+=("${batch_tokens[@]}")
    
    processed=$((processed + batch_size))
    percent=$((processed * 100 / TOTAL))
    echo "$processed/$TOTAL ($percent%)" > "$PROGRESS_FILE"
  done
else
  # Original single-pass processing
  mapfile -t TOKENS < <(
    printf '%s\n' "${REPOS[@]}" |
    xargs -P "$JOBS" -I{} bash -c \
      'cd "$TARGET_CLONE_DIR" 2>/dev/null || cd "$HOME"; clone_or_update "$1"' _ {}
  )
fi

rm -f "$PROGRESS_FILE"

# --------------------------------------------------------------------------- #
# Totals
# --------------------------------------------------------------------------- #
CLONED=0 UPDATED=0 UNCHANGED=0 DIRTY=0 SKIPPED=0 ERRORS=0
for t in "${TOKENS[@]}"; do
  case $t in
    CLONED)    ((CLONED++));;
    UPDATED)   ((UPDATED++));;
    UNCHANGED) ((UNCHANGED++));;
    DIRTY)     ((DIRTY++));;
    SKIPPED)   ((SKIPPED++));;
    ERROR)     ((ERRORS++));;
  esac
done

# --------------------------------------------------------------------------- #
# Calculate timing statistics
# --------------------------------------------------------------------------- #
declare -a TIMING_STATS
if $DETAILED_JSON && [[ -f $METRICS_TMP ]]; then
  mapfile -t TIMING_STATS < <(jq -r '.sec' "$METRICS_TMP" | sort -n)
fi

calc_statistics() {
  local -a times=("${TIMING_STATS[@]}")
  [[ ${#times[@]} -eq 0 ]] && return
  
  local sum=0 min=${times[0]} max=${times[-1]} count=${#times[@]}
  for t in "${times[@]}"; do sum=$((sum + t)); done
  local avg=$((sum / count))
  
  # Median
  local median_idx=$((count / 2))
  local median=${times[$median_idx]}
  
  # Standard deviation (simplified)
  local variance_sum=0
  for t in "${times[@]}"; do
    local diff=$((t - avg))
    variance_sum=$((variance_sum + diff * diff))
  done
  local std_dev=$(echo "scale=1; sqrt($variance_sum / $count)" | bc 2>/dev/null || echo "0")
  
  echo "$min|$max|$avg|$median|$std_dev"
}

# --------------------------------------------------------------------------- #
# Write metrics JSON with enhanced statistics
# --------------------------------------------------------------------------- #
if $GENERATE_METRICS; then
  ts=$(date -u +%Y-%m-%dT%H%M%SZ)
  outfile="${TARGET_CLONE_DIR}/clone_metrics-${ts}.json"

  if $DETAILED_JSON; then
    # Calculate timing statistics
    IFS='|' read -r min_time max_time avg_time median_time std_dev < <(calc_statistics)
    
    # Find slowest repos
    slowest=$(jq -s 'sort_by(.sec) | reverse | .[0:10] | map({repo, sec})' "$METRICS_TMP")
    
    # Categorize repos by prefix
    declare -A categories
    while IFS= read -r repo; do
      prefix=$(echo "$repo" | cut -d'-' -f1)
      categories[$prefix]=$((${categories[$prefix]:-0} + 1))
    done < <(jq -r '.repo' "$METRICS_TMP")
    
    {
      printf '{\n  "timestamp": "%s",\n  "workspace": "%s",\n' "$ts" "$BB_WORKSPACE"
      printf '  "totals": { "cloned": %s, "updated": %s, "unchanged": %s,' \
             "$CLONED" "$UPDATED" "$UNCHANGED"
      printf ' "dirty": %s, "skipped": %s, "errors": %s },\n' \
             "$DIRTY" "$SKIPPED" "$ERRORS"
      printf '  "duration_sec": %s,\n' "$SECONDS"
      
      # Timing statistics
      if [[ -n $min_time ]]; then
        printf '  "timing_stats": {\n'
        printf '    "min_sec": %s, "max_sec": %s, "avg_sec": %s,\n' "$min_time" "$max_time" "$avg_time"
        printf '    "median_sec": %s, "std_dev": %s,\n' "$median_time" "$std_dev"
        printf '    "slowest_repos": %s\n' "$slowest"
        printf '  },\n'
      fi
      
      # Category breakdown
      if [[ ${#categories[@]} -gt 0 ]]; then
        printf '  "categories": {\n'
        first=true
        for prefix in "${!categories[@]}"; do
          $first || printf ',\n'
          printf '    "%s": %s' "$prefix" "${categories[$prefix]}"
          first=false
        done
        printf '\n  },\n'
      fi
      
      # Health score (0-100)
      health=$((100 - (ERRORS * 10) - (DIRTY * 2)))
      [[ $health -lt 0 ]] && health=0
      printf '  "health_score": %s,\n' "$health"
      
      printf '  "repos": [\n'
      sed '$!s/$/,/' "$METRICS_TMP"
      printf '\n  ]\n}\n'
    } > "$outfile"
  else
    jq -n --arg ts "$ts" --arg ws "$BB_WORKSPACE" \
       --argjson total $TOTAL --argjson clo $CLONED --argjson upd $UPDATED \
       --argjson unc $UNCHANGED --argjson dir $DIRTY --argjson sk $SKIPPED \
       --argjson err $ERRORS --argjson dur $SECONDS \
       '{
         timestamp: $ts, workspace: $ws, total: $total,
         cloned: $clo, updated: $upd, clean: $unc,
         dirty: $dir, skipped: $sk, errors: $err,
         duration_sec: $dur
       }' > "$outfile"
  fi
  echo "📊 Metrics written to: $outfile"
  
  # Generate additional formats if requested
  if [[ $EXPORT_FORMAT != "json" ]] && $DETAILED_JSON; then
    case $EXPORT_FORMAT in
      csv)
        csv_file="${outfile%.json}.csv"
        {
          echo "repo,result,time_sec"
          jq -r '.repos[] | "\(.repo),\(.result),\(.sec)"' "$outfile"
        } > "$csv_file"
        echo "📄 CSV exported to: $csv_file"
        ;;
        
      html)
        html_file="${outfile%.json}.html"
        {
          cat <<'HTML'
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Bitbucket Clone Report</title>
<style>
body{font-family:Arial,sans-serif;margin:20px;background:#f5f5f5}
.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
h1{color:#0052CC}
table{width:100%;border-collapse:collapse;margin-top:20px}
th,td{padding:10px;text-align:left;border-bottom:1px solid #ddd}
th{background:#0052CC;color:white}
tr:hover{background:#f5f5f5}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;margin:20px 0}
.stat-box{background:#f8f9fa;padding:15px;border-radius:5px;border-left:4px solid #0052CC}
.stat-label{color:#666;font-size:12px;text-transform:uppercase}
.stat-value{font-size:24px;font-weight:bold;color:#0052CC}
.CLONED{color:#36B37E}.UPDATED{color:#00B8D9}.ERROR{color:#FF5630}.DIRTY{color:#FF991F}
</style></head><body><div class="container">
HTML
          echo "<h1>📊 Bitbucket Workspace Clone Report</h1>"
          echo "<p><strong>Workspace:</strong> $BB_WORKSPACE | <strong>Date:</strong> $ts</p>"
          
          echo '<div class="stats">'
          echo "<div class='stat-box'><div class='stat-label'>Cloned</div><div class='stat-value'>$CLONED</div></div>"
          echo "<div class='stat-box'><div class='stat-label'>Updated</div><div class='stat-value'>$UPDATED</div></div>"
          echo "<div class='stat-box'><div class='stat-label'>Errors</div><div class='stat-value'>$ERRORS</div></div>"
          echo "<div class='stat-box'><div class='stat-label'>Duration</div><div class='stat-value'>${SECONDS}s</div></div>"
          echo '</div>'
          
          echo '<table><thead><tr><th>Repository</th><th>Status</th><th>Time (s)</th></tr></thead><tbody>'
          jq -r '.repos[] | "<tr><td>\(.repo)</td><td class=\"\(.result)\">\(.result)</td><td>\(.sec)</td></tr>"' "$outfile"
          echo '</tbody></table></div></body></html>'
        } > "$html_file"
        echo "🌐 HTML report: $html_file"
        ;;
        
      markdown)
        md_file="${outfile%.json}.md"
        {
          echo "# 📊 Bitbucket Clone Report"
          echo ""
          echo "**Workspace:** $BB_WORKSPACE  "
          echo "**Date:** $ts  "
          echo "**Duration:** ${SECONDS}s"
          echo ""
          echo "## Summary"
          echo ""
          echo "| Metric | Count |"
          echo "|--------|-------|"
          echo "| ✅ Cloned | $CLONED |"
          echo "| 🔄 Updated | $UPDATED |"
          echo "| ⏸️ Unchanged | $UNCHANGED |"
          echo "| ⚠️ Dirty | $DIRTY |"
          echo "| ❌ Errors | $ERRORS |"
          echo ""
          echo "## Repository Details"
          echo ""
          echo "| Repository | Status | Time (s) |"
          echo "|------------|--------|----------|"
          jq -r '.repos[] | "| \(.repo) | \(.result) | \(.sec) |"' "$outfile"
        } > "$md_file"
        echo "📝 Markdown: $md_file"
        ;;
    esac
  fi
  
  # Compare with previous run
  prev_metrics=$(ls -t "${TARGET_CLONE_DIR}"/clone_metrics-*.json 2>/dev/null | sed -n '2p')
  if [[ -n $prev_metrics ]] && [[ -f $prev_metrics ]]; then
    prev_duration=$(jq -r '.duration_sec // 0' "$prev_metrics")
    prev_cloned=$(jq -r '.totals.cloned // 0' "$prev_metrics")
    
    if [[ $prev_duration -gt 0 ]]; then
      improvement=$((100 - (SECONDS * 100 / prev_duration)))
      echo ""
      echo "📈 Comparison with previous run:"
      if [[ $improvement -gt 0 ]]; then
        echo "   ⚡ ${improvement}% faster than last run (was ${prev_duration}s)"
      elif [[ $improvement -lt 0 ]]; then
        echo "   🐌 $((0 - improvement))% slower than last run (was ${prev_duration}s)"
      else
        echo "   ⏱️ Same duration as last run"
      fi
      
      new_repos=$((CLONED - prev_cloned))
      [[ $new_repos -gt 0 ]] && echo "   ➕ $new_repos new repositories cloned"
    fi
  fi
fi
rm -f "$METRICS_TMP"

# --------------------------------------------------------------------------- #
# Summary with timing statistics
# --------------------------------------------------------------------------- #
echo ""
echo "════════════════════════════════════════════"
echo "📊 FINAL SUMMARY"
echo "════════════════════════════════════════════"
echo "Results  → cloned: $CLONED | updated: $UPDATED | unchanged: $UNCHANGED"
echo "Issues   → dirty: $DIRTY | no-branch: $SKIPPED | errors: $ERRORS"

if $DETAILED_JSON && [[ ${#TIMING_STATS[@]} -gt 0 ]]; then
  IFS='|' read -r min_time max_time avg_time median_time std_dev < <(calc_statistics)
  echo "Timing   → min: ${min_time}s | max: ${max_time}s | avg: ${avg_time}s | median: ${median_time}s"
  
  # Show slowest repos
  echo ""
  echo "🐌 Slowest repositories:"
  jq -r 'sort_by(.sec) | reverse | .[0:5] | .[] | "   \(.repo): \(.sec)s"' "$METRICS_TMP" 2>/dev/null || true
fi

if $ADAPTIVE_PARALLELISM && [[ $JOBS -lt $ORIGINAL_JOBS ]]; then
  echo ""
  echo "⚡ Parallelism adjusted: $ORIGINAL_JOBS → $JOBS (rate limiting detected)"
fi

# Health assessment
if [[ ${#TIMING_STATS[@]} -gt 0 ]]; then
  health=$((100 - (ERRORS * 10) - (DIRTY * 2)))
  [[ $health -lt 0 ]] && health=0
  echo ""
  echo "🏥 Health Score: $health/100"
  
  if [[ $ERRORS -gt 0 ]]; then
    echo "   ⚠️  $ERRORS repositories failed to clone"
  fi
  if [[ $DIRTY -gt 0 ]]; then
    echo "   ⚠️  $DIRTY repositories have uncommitted changes"
  fi
  if [[ $health -ge 90 ]]; then
    echo "   ✅ Workspace is in excellent condition"
  elif [[ $health -ge 70 ]]; then
    echo "   ⚠️  Minor issues detected"
  else
    echo "   ❌ Multiple issues need attention"
  fi
fi

echo "════════════════════════════════════════════"
echo "✅ Done. Total time: ${SECONDS}s"

# --------------------------------------------------------------------------- #
# Send alerts if configured
# --------------------------------------------------------------------------- #
if [[ -n $ALERT_WEBHOOK ]]; then
  should_alert=false
  alert_level="info"
  alert_msg=""
  
  # Check for critical issues
  if [[ $ERRORS -ge $ALERT_THRESHOLD_ERRORS ]]; then
    should_alert=true
    alert_level="error"
    alert_msg="❌ $ERRORS repositories failed to clone"
  elif [[ $ERRORS -gt 0 ]]; then
    should_alert=true
    alert_level="warning"
    alert_msg="⚠️  $ERRORS repository failed"
  elif [[ $DIRTY -ge 5 ]]; then
    should_alert=true
    alert_level="warning"
    alert_msg="⚠️  $DIRTY repositories have uncommitted changes"
  fi
  
  if $should_alert; then
    # Determine emoji and color
    case $alert_level in
      error)   emoji="🚨"; color="#FF5630";;
      warning) emoji="⚠️"; color="#FF991F";;
      *)       emoji="✅"; color="#36B37E";;
    esac
    
    # Build alert payload
    alert_title="$emoji Bitbucket Clone Report - $BB_WORKSPACE"
    alert_body="$alert_msg\\n\\nResults: ✅ $CLONED cloned | 🔄 $UPDATED updated | ⏸️ $UNCHANGED unchanged\\nIssues: ⚠️ $DIRTY dirty | ❌ $ERRORS errors\\nDuration: ${SECONDS}s"
    
    # Detect webhook type and send appropriate format
    if [[ $ALERT_WEBHOOK == *"hooks.slack.com"* ]]; then
      # Slack format
      payload=$(jq -n --arg text "$alert_title" --arg msg "$alert_body" --arg color "$color" '{
        text: $text,
        attachments: [{
          color: $color,
          text: $msg,
          footer: "Bitbucket Workspace Clone",
          ts: (now | floor)
        }]
      }')
    else
      # Microsoft Teams / generic webhook format
      payload=$(jq -n --arg title "$alert_title" --arg text "$alert_body" --arg color "$color" '{
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        summary: $title,
        themeColor: $color,
        title: $title,
        text: $text
      }')
    fi
    
    # Send webhook
    response=$(curl -s -X POST "$ALERT_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      -w "HTTP_STATUS:%{http_code}")
    
    http_code=${response##*HTTP_STATUS:}
    if [[ $http_code =~ ^2 ]]; then
      echo "📧 Alert sent successfully to webhook"
    else
      echo "⚠️  Failed to send alert (HTTP $http_code)"
    fi
  else
    echo "✅ No alerts needed (all within thresholds)"
  fi
fi

