#!/usr/bin/env bash
# Bazel workspace status script
# This script outputs build information as key-value pairs
#
# Bazel recognizes these special keys:
# - BUILD_EMBED_LABEL: Embedded in binaries
# - BUILD_HOST: Build hostname (automatically added to non-volatile)
# - BUILD_USER: Build username (automatically added to non-volatile)
# - BUILD_SCM_REVISION: Git commit SHA (becomes BUILD_SCM_REVISION macro)
# - BUILD_SCM_STATUS: Git status (becomes BUILD_SCM_STATUS macro)
#
# Custom keys with STABLE_ prefix go to stable-status.txt
# Other keys go to volatile-status.txt

set -eu

# Change to workspace directory to access .git
if [ -n "${BUILD_WORKSPACE_DIRECTORY:-}" ]; then
    cd "$BUILD_WORKSPACE_DIRECTORY"
fi

# Volatile status (changes on every build)
echo "BUILD_TIMESTAMP $(date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/')"

# Get git info once to avoid duplicate calls
GIT_SHA=""
if git rev-parse HEAD >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse HEAD)
fi

# Stable status using Bazel-recognized keys
# Git commit SHA - Bazel converts this to BUILD_SCM_REVISION macro
if [ -n "$GIT_SHA" ]; then
    echo "BUILD_SCM_REVISION $GIT_SHA"
else
    echo "BUILD_SCM_REVISION 0"
fi

# Git status - Bazel converts this to BUILD_SCM_STATUS macro
if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "BUILD_SCM_STATUS clean"
else
    echo "BUILD_SCM_STATUS dirty"
fi

# Custom stable keys (with STABLE_ prefix for our own use)
if [ -n "$GIT_SHA" ]; then
    # Get branch name
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # If detached HEAD, try to find the tracking branch
    if [ "$GIT_BRANCH" = "HEAD" ]; then
        # Try symbolic-ref first (works for normal branches)
        GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
        
        # Find remote branch that matches current commit exactly
        if [ -z "$GIT_BRANCH" ] || [ "$GIT_BRANCH" = "HEAD" ]; then
            GIT_BRANCH=$(git for-each-ref --points-at=HEAD --format='%(refname:short)' 'refs/remotes/origin/**' 2>/dev/null | grep -v '^origin$' | grep -v '/HEAD$' | head -1 | sed 's|^origin/||' || echo "")
        fi
        
        # Fallback: find any remote branch containing current commit
        if [ -z "$GIT_BRANCH" ]; then
            GIT_BRANCH=$(git branch -r --contains HEAD 2>/dev/null | grep -E '^\s+origin/' | grep -v 'HEAD' | head -1 | sed -e 's|^[[:space:]]*origin/||' -e 's|^[[:space:]]*||' || echo "")
        fi
        
        # Last fallback: use short commit SHA
        if [ -z "$GIT_BRANCH" ]; then
            GIT_BRANCH="${GIT_SHA:0:7}"
        fi

        GIT_BRANCH="$GIT_BRANCH [detached]"
    fi
    
    # BUILD_EMBED_LABEL is recognized by Bazel and becomes a macro in linkstamp
    echo "BUILD_EMBED_LABEL $GIT_BRANCH"
    echo "STABLE_GIT_BRANCH $GIT_BRANCH"
else
    echo "BUILD_EMBED_LABEL unknown"
    echo "STABLE_GIT_BRANCH unknown"
fi
