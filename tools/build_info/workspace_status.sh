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

# Stable status using Bazel-recognized keys
# Git commit SHA - Bazel converts this to BUILD_SCM_REVISION macro
if git rev-parse HEAD >/dev/null 2>&1; then
    echo "BUILD_SCM_REVISION $(git rev-parse HEAD)"
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
if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "STABLE_GIT_BRANCH $GIT_BRANCH"
    # BUILD_EMBED_LABEL is recognized by Bazel and becomes a macro in linkstamp
    echo "BUILD_EMBED_LABEL $GIT_BRANCH"
else
    echo "STABLE_GIT_BRANCH unknown"
    echo "BUILD_EMBED_LABEL unknown"
fi

if git rev-parse --short HEAD >/dev/null 2>&1; then
    echo "STABLE_GIT_SHA_SHORT $(git rev-parse --short HEAD)"
else
    echo "STABLE_GIT_SHA_SHORT unknown"
fi
