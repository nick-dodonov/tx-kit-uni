#!/usr/bin/env pwsh
# Bazel workspace status script (PowerShell version)
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

$ErrorActionPreference = 'Stop'

# Change to workspace directory to access .git
if ($env:BUILD_WORKSPACE_DIRECTORY) {
    Set-Location $env:BUILD_WORKSPACE_DIRECTORY
}

# Volatile status (changes on every build)
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
Write-Output "BUILD_TIMESTAMP $timestamp"

# Get git info once to avoid duplicate calls
$gitSha = ""
try {
    $gitSha = git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { $gitSha = "" }
} catch {
    $gitSha = ""
}

# Stable status using Bazel-recognized keys
# Git commit SHA - Bazel converts this to BUILD_SCM_REVISION macro
if ($gitSha) {
    Write-Output "BUILD_SCM_REVISION $gitSha"
} else {
    Write-Output "BUILD_SCM_REVISION 0"
}
# This forces the rebuild because STABLE_ variable is written to bazel-out/stable-status.txt
#   https://bazel.build/docs/user-manual#workspace-status
Write-Output "STABLE_GIT_SHA $(if ($gitSha) { $gitSha } else { '0' })"

# Git status - Bazel converts this to BUILD_SCM_STATUS macro
$gitStatus = "clean"
try {
    git diff-index --quiet HEAD -- 2>$null
    if ($LASTEXITCODE -ne 0) {
        $gitStatus = "dirty"
    }
} catch {
    $gitStatus = "dirty"
}
Write-Output "BUILD_SCM_STATUS $gitStatus"

# Custom stable keys (with STABLE_ prefix for our own use)
if ($gitSha) {
    # Get branch name
    $gitBranch = ""
    try {
        $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -ne 0) { $gitBranch = "" }
    } catch {
        $gitBranch = ""
    }
    
    # If detached HEAD, try to find the tracking branch
    if ($gitBranch -eq "HEAD" -or [string]::IsNullOrEmpty($gitBranch)) {
        # Try symbolic-ref first (works for normal branches)
        try {
            $gitBranch = git symbolic-ref --short HEAD 2>$null
            if ($LASTEXITCODE -ne 0) { $gitBranch = "" }
        } catch {
            $gitBranch = ""
        }
        
        # Find remote branch that matches current commit exactly
        if ([string]::IsNullOrEmpty($gitBranch) -or $gitBranch -eq "HEAD") {
            try {
                $remoteBranches = git for-each-ref --points-at=HEAD --format='%(refname:short)' 'refs/remotes/origin/**' 2>$null
                if ($LASTEXITCODE -eq 0 -and $remoteBranches) {
                    $gitBranch = ($remoteBranches -split "`n" | 
                                  Where-Object { $_ -and $_ -ne 'origin' -and $_ -notmatch '/HEAD$' } | 
                                  Select-Object -First 1) -replace '^origin/', ''
                }
            } catch {
                $gitBranch = ""
            }
        }
        
        # Fallback: find any remote branch containing current commit
        if ([string]::IsNullOrEmpty($gitBranch)) {
            try {
                $containingBranches = git branch -r --contains HEAD 2>$null
                if ($LASTEXITCODE -eq 0 -and $containingBranches) {
                    $gitBranch = ($containingBranches -split "`n" | 
                                  Where-Object { $_ -match '^\s+origin/' -and $_ -notmatch 'HEAD' } | 
                                  Select-Object -First 1).Trim() -replace '^\s*origin/', ''
                }
            } catch {
                $gitBranch = ""
            }
        }
        
        # Last fallback: use short commit SHA
        if ([string]::IsNullOrEmpty($gitBranch)) {
            $gitBranch = $gitSha.Substring(0, 7)
        }

        $gitBranch = "$gitBranch [detached]"
    }
    
    # BUILD_EMBED_LABEL is recognized by Bazel and becomes a macro in linkstamp
    Write-Output "BUILD_EMBED_LABEL $gitBranch"
    Write-Output "STABLE_GIT_BRANCH $gitBranch"
} else {
    Write-Output "BUILD_EMBED_LABEL unknown"
    Write-Output "STABLE_GIT_BRANCH unknown"
}
