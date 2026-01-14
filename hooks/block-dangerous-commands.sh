#!/usr/bin/env bash
# =============================================================================
# PreToolUse Hook: Block Dangerous Bash Commands
# =============================================================================
#
# This hook runs BEFORE bash commands execute.
# It blocks destructive patterns like rm -rf, force pushes, etc.
#
# Exit codes:
#   0 = Allow command
#   2 = Block command (stderr fed back to Claude)
#
# Usage:
#   Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "~/.claude/hooks/block-dangerous-commands.sh"
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

# Extract the command using jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
    exit 0  # No command, allow
fi

# -----------------------------------------------------------------------------
# Dangerous Patterns
# -----------------------------------------------------------------------------

# rm -rf with dangerous paths
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-rf|-fr)\s+(/|~|\.\.|\$HOME|\$\{HOME\})'; then
    echo "🛑 BLOCKED: Destructive rm command targeting root, home, or parent directory" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# rm -rf /* or rm -rf ~/*
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-rf|-fr)\s+(/\*|~/\*|/home)'; then
    echo "🛑 BLOCKED: Destructive rm command with wildcard on sensitive path" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# Force push to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\s+.*(main|master|production|release)'; then
    echo "🛑 BLOCKED: Force push to protected branch" >&2
    echo "Command: $COMMAND" >&2
    echo "Tip: Create a PR instead of force pushing to main/master" >&2
    exit 2
fi

# chmod 777 (world-writable)
if echo "$COMMAND" | grep -qE 'chmod\s+(777|a\+rwx)'; then
    echo "⚠️ BLOCKED: Setting world-writable permissions (777)" >&2
    echo "Command: $COMMAND" >&2
    echo "Tip: Use 755 for directories, 644 for files" >&2
    exit 2
fi

# Piping curl directly to shell (dangerous pattern)
if echo "$COMMAND" | grep -qE 'curl\s+.*\|\s*(ba)?sh'; then
    echo "⚠️ BLOCKED: Piping curl output directly to shell" >&2
    echo "Command: $COMMAND" >&2
    echo "Tip: Download script first, review it, then execute" >&2
    exit 2
fi

# wget piped to shell
if echo "$COMMAND" | grep -qE 'wget\s+.*\|\s*(ba)?sh'; then
    echo "⚠️ BLOCKED: Piping wget output directly to shell" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# dd writing to disk devices
if echo "$COMMAND" | grep -qE 'dd\s+.*of=/dev/(sd|hd|nvme|disk)'; then
    echo "🛑 BLOCKED: dd command writing directly to disk device" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# mkfs (format disk)
if echo "$COMMAND" | grep -qE 'mkfs'; then
    echo "🛑 BLOCKED: mkfs command (disk formatting)" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# Commands that could exfiltrate data
if echo "$COMMAND" | grep -qE '(curl|wget|nc|netcat)\s+.*\.(env|pem|key|secret)'; then
    echo "⚠️ BLOCKED: Command appears to exfiltrate sensitive files" >&2
    echo "Command: $COMMAND" >&2
    exit 2
fi

# Reading .env files via cat/less/head/tail
if echo "$COMMAND" | grep -qE '(cat|less|head|tail|more|bat)\s+.*\.env'; then
    echo "⚠️ BLOCKED: Reading .env file via $COMMAND" >&2
    echo "Tip: Use environment variables instead of reading .env directly" >&2
    exit 2
fi

# -----------------------------------------------------------------------------
# Command is safe, allow it
# -----------------------------------------------------------------------------
exit 0
