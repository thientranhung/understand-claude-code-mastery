#!/usr/bin/env bash
# =============================================================================
# PostToolUse Hook: After File Edit
# =============================================================================
#
# This hook runs AFTER Claude edits or writes a file.
# Use it for fast operations like formatting that should run immediately.
#
# For heavier checks (tests, full linting), use the end-of-turn (Stop) hook.
#
# Usage:
#   Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PostToolUse": [
#         {
#           "matcher": "Edit|Write",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "~/.claude/hooks/after-edit.sh"
#             }
#           ]
#         }
#       ]
#     }
#   }
# =============================================================================

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract the file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [[ -z "$FILE_PATH" ]]; then
    exit 0  # No file path, nothing to do
fi

# Get file extension
EXTENSION="${FILE_PATH##*.}"

# -----------------------------------------------------------------------------
# Format based on file type
# -----------------------------------------------------------------------------

case "$EXTENSION" in
    js|jsx|ts|tsx|json|md|yaml|yml|css|scss|html)
        # Prettier for web files
        if command -v prettier &>/dev/null; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    
    py)
        # Black for Python
        if command -v black &>/dev/null; then
            black --quiet "$FILE_PATH" 2>/dev/null || true
        fi
        # Ruff for linting
        if command -v ruff &>/dev/null; then
            ruff check --fix --silent "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    
    go)
        # gofmt for Go
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    
    rs)
        # rustfmt for Rust
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    
    sh|bash)
        # shfmt for shell scripts
        if command -v shfmt &>/dev/null; then
            shfmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

# Always exit 0 - formatting failures shouldn't block work
exit 0
