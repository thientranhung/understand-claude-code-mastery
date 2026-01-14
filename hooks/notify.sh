#!/usr/bin/env bash
# =============================================================================
# Notification Hook: Desktop Alerts
# =============================================================================
#
# This hook runs when Claude Code sends notifications.
# It triggers desktop notifications so you know when Claude needs input.
#
# Works on:
#   - macOS (osascript)
#   - Linux (notify-send)
#   - Windows WSL (powershell)
#
# Usage:
#   Add to ~/.claude/settings.json:
#   {
#     "hooks": {
#       "Notification": [
#         {
#           "matcher": "*",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "~/.claude/hooks/notify.sh"
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

# Extract notification content
CONTENT=$(echo "$INPUT" | jq -r '.content // "Claude needs your attention"')

# Truncate long messages
if [[ ${#CONTENT} -gt 100 ]]; then
    CONTENT="${CONTENT:0:100}..."
fi

# -----------------------------------------------------------------------------
# Send notification based on OS
# -----------------------------------------------------------------------------

send_notification() {
    local title="Claude Code"
    local message="$1"
    
    # macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null || true
        return
    fi
    
    # Linux with notify-send
    if command -v notify-send &>/dev/null; then
        notify-send "$title" "$message" -u normal -t 5000 2>/dev/null || true
        return
    fi
    
    # Windows WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        powershell.exe -Command "
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
            \$template = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$title</text><text id=\"2\">$message</text></binding></visual></toast>'
            \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            \$xml.LoadXml(\$template)
            \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
        " 2>/dev/null || true
        return
    fi
    
    # Fallback: terminal bell
    echo -e '\a'
}

send_notification "$CONTENT"
exit 0
