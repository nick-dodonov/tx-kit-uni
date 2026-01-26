@echo off
REM Bazel workspace status script for Windows
REM This script outputs build information as key-value pairs
REM
REM Bazel recognizes these special keys:
REM - BUILD_EMBED_LABEL: Embedded in binaries
REM - BUILD_HOST: Build hostname (automatically added to non-volatile)
REM - BUILD_USER: Build username (automatically added to non-volatile)
REM - BUILD_SCM_REVISION: Git commit SHA (becomes BUILD_SCM_REVISION macro)
REM - BUILD_SCM_STATUS: Git status (becomes BUILD_SCM_STATUS macro)
REM
REM Custom keys with STABLE_ prefix go to stable-status.txt
REM Other keys go to volatile-status.txt

setlocal enabledelayedexpansion

REM Change to workspace directory to access .git
if defined BUILD_WORKSPACE_DIRECTORY (
    cd /d "%BUILD_WORKSPACE_DIRECTORY%"
)

REM Volatile status (changes on every build)
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'"') do (
    echo BUILD_TIMESTAMP %%a
)

REM Stable status using Bazel-recognized keys
REM Git commit SHA - Bazel converts this to BUILD_SCM_REVISION macro
git rev-parse HEAD >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('git rev-parse HEAD 2^>nul') do (
        echo BUILD_SCM_REVISION %%a
    )
) else (
    echo BUILD_SCM_REVISION 0
)

REM Git status - Bazel converts this to BUILD_SCM_STATUS macro
git diff-index --quiet HEAD -- >nul 2>&1
if !errorlevel! equ 0 (
    echo BUILD_SCM_STATUS clean
) else (
    echo BUILD_SCM_STATUS dirty
)

REM Custom stable keys (with STABLE_ prefix for our own use)
for /f "tokens=*" %%a in ('git rev-parse --abbrev-ref HEAD 2^>nul') do (
    if not "%%a"=="" (
        echo STABLE_GIT_BRANCH %%a
        REM BUILD_EMBED_LABEL is recognized by Bazel and becomes a macro in linkstamp
        echo BUILD_EMBED_LABEL %%a
        goto :branch_done
    )
)
echo STABLE_GIT_BRANCH unknown
echo BUILD_EMBED_LABEL unknown
:branch_done

for /f "tokens=*" %%a in ('git rev-parse --short HEAD 2^>nul') do (
    if not "%%a"=="" (
        echo STABLE_GIT_SHA_SHORT %%a
        goto :short_done
    )
)
echo STABLE_GIT_SHA_SHORT unknown
:short_done

endlocal
