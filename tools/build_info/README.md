# Build Info

Tools for generating build information (git SHA, branch, build time).

## Overview

This system uses Bazel's native features:
- **workspace_status.sh** - Script that generates build metadata
- **linkstamp** - Special .cc file recompiled on every link with fresh build info

## Files

### workspace_status.sh

Script executed by Bazel before build to collect build metadata.

**Output to volatile-status.txt** (changes on every build):
- `BUILD_TIMESTAMP` - Build time in RFC 3339 format with timezone

**Output to stable-status.txt** (changes only when values change):
- `BUILD_SCM_REVISION` - Full git SHA
- `BUILD_SCM_STATUS` - Git status (clean/dirty)
- `BUILD_EMBED_LABEL` - Git branch (used to get branch in linkstamp)
- `STABLE_GIT_BRANCH` - Git branch (for other purposes)
- `STABLE_GIT_SHA_SHORT` - Short git SHA

## How It Works

### 1. Workspace Status Command

Bazel invokes `workspace_status.sh` before build and saves results:
- `bazel-out/volatile-status.txt` - Frequently changing values
- `bazel-out/stable-status.txt` - Stable values

```bash
build --workspace_status_command=$(pwd)/uni/tools/build_info/workspace_status.sh
build --stamp
```

### 2. Linkstamp

Bazel converts certain keys from status files into preprocessor macros:

**Volatile macros** (from volatile-status.txt):
- `BUILD_TIMESTAMP` - From `BUILD_TIMESTAMP`
- `BUILD_SCM_REVISION` - From `BUILD_SCM_REVISION`
- `BUILD_SCM_STATUS` - From `BUILD_SCM_STATUS`

**Stable macros** (from stable-status.txt):
- `BUILD_USER` - Automatically added by Bazel
- `BUILD_HOST` - Automatically added by Bazel
- `BUILD_EMBED_LABEL` - From `BUILD_EMBED_LABEL` (**used for branch!**)

⚠️ **Important**: Only these keys are converted to macros! Custom keys with `STABLE_` prefix go to stable-status.txt but are NOT converted to macros in linkstamp.

### 3. BUILD_EMBED_LABEL for Git Branch

To get git branch in linkstamp, use `BUILD_EMBED_LABEL` - the only custom key that Bazel converts to a macro:

```bash
# In workspace_status.sh
echo "BUILD_EMBED_LABEL $GIT_BRANCH"
```

```cpp
// In linkstamp file
const char* Info::GitBranch() {
    return BUILD_EMBED_LABEL;
}
```

## Usage Example

```cpp
#include "Build/Info.h"

std::cout << "Git SHA: " << Build::Info::GitSha() << '\n';
std::cout << "Git Branch: " << Build::Info::GitBranch() << '\n';
std::cout << "Build Time: " << Build::Info::BuildTime() << '\n';
std::cout << "Git Status: " << Build::Info::GitStatus() << '\n';
std::cout << "Build User: " << Build::Info::BuildUser() << '\n';
std::cout << "Build Host: " << Build::Info::BuildHost() << '\n';
```

## BUILD.bazel

```starlark
cc_library(
    name = "pkg-build",
    hdrs = ["Build/Info.h"],
    linkstamp = "Build/Info.linkstamp.cc",
    strip_include_prefix = ".",
    visibility = ["//visibility:public"],
)
```

## Rebuild Behavior

- Linkstamp is recompiled on **every link**
- `BUILD_TIMESTAMP` changes on every build → always rebuilds
- `BUILD_SCM_*` changes only on git state changes → rebuilds on commits/changes

## Timestamp Format

Uses RFC 3339 with local timezone:
```
2026-01-26T21:11:49+01:00
```

Generated with:
```bash
date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/'
```

## Documentation

- [Bazel User Manual: workspace-status](https://bazel.build/docs/user-manual#workspace-status)
- [Bazel Build Encyclopedia: linkstamp](https://bazel.build/reference/be/c-cpp#cc_library.linkstamp)
- Only BUILD_SCM_REVISION, BUILD_SCM_STATUS, BUILD_TIMESTAMP, BUILD_USER, BUILD_HOST, BUILD_EMBED_LABEL are converted to macros

## Solution

`BUILD_EMBED_LABEL` is the only way to pass custom values (like git branch) to linkstamp as a macro. All other custom keys (with `STABLE_` prefix or without) are not automatically converted to macros.

