#!/usr/bin/env bash
# =============================================================================
# End-of-Turn Quality Gate Hook
# =============================================================================
#
# This hook runs when Claude finishes responding (Stop event).
# It performs quality checks to catch issues before they accumulate.
#
# Usage:
#   Add to ~/.claude/settings.json or .claude/settings.json:
#   {
#     "hooks": {
#       "Stop": [
#         {
#           "matcher": "*",
#           "hooks": [
#             {
#               "type": "command",
#               "command": "~/.claude/hooks/end-of-turn.sh"
#             }
#           ]
#         }
#       ]
#     }
#   }
#
# Exit codes:
#   0 = Success (continue normally)
#   1 = Error shown to user
#   2 = Block and feed stderr to Claude (use sparingly for Stop hooks)
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Set to "true" to enable verbose logging
VERBOSE="${CLAUDE_HOOK_VERBOSE:-false}"

# Maximum time for checks (seconds)
TIMEOUT=30

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[end-of-turn] $*" >&2
    fi
}

run_check() {
    local name="$1"
    local cmd="$2"
    
    log "Running: $name"
    
    if timeout "$TIMEOUT" bash -c "$cmd" 2>/dev/null; then
        log "✓ $name passed"
        return 0
    else
        log "✗ $name failed (non-blocking)"
        return 0  # Don't fail the hook, just log
    fi
}

# -----------------------------------------------------------------------------
# Detect Project Type
# -----------------------------------------------------------------------------

is_nodejs() {
    [[ -f "package.json" ]]
}

is_typescript() {
    [[ -f "tsconfig.json" ]]
}

is_python() {
    [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]
}

is_rust() {
    [[ -f "Cargo.toml" ]]
}

is_go() {
    [[ -f "go.mod" ]]
}

# -----------------------------------------------------------------------------
# Project-Specific Checks
# -----------------------------------------------------------------------------

check_nodejs() {
    log "Detected Node.js project"
    
    # Check if node_modules exists
    if [[ ! -d "node_modules" ]]; then
        log "node_modules missing, skipping npm checks"
        return 0
    fi
    
    # Run lint if available
    if grep -q '"lint"' package.json 2>/dev/null; then
        run_check "npm lint" "npm run lint --silent"
    fi
    
    # Run typecheck if TypeScript
    if is_typescript; then
        if grep -q '"typecheck"' package.json 2>/dev/null; then
            run_check "typecheck" "npm run typecheck --silent"
        elif command -v tsc &>/dev/null; then
            run_check "tsc" "tsc --noEmit"
        fi
    fi
}

check_python() {
    log "Detected Python project"
    
    # Ruff (fast Python linter)
    if command -v ruff &>/dev/null; then
        run_check "ruff" "ruff check . --fix --silent"
    fi
    
    # Black (formatter)
    if command -v black &>/dev/null; then
        run_check "black" "black --check --quiet ."
    fi
    
    # MyPy (type checker)
    if command -v mypy &>/dev/null && [[ -f "mypy.ini" || -f "pyproject.toml" ]]; then
        run_check "mypy" "mypy . --silent-imports"
    fi
}

check_rust() {
    log "Detected Rust project"
    
    # Cargo check (fast type checking)
    if command -v cargo &>/dev/null; then
        run_check "cargo check" "cargo check --quiet"
    fi
    
    # Clippy (linter)
    if command -v cargo &>/dev/null; then
        run_check "clippy" "cargo clippy --quiet -- -D warnings"
    fi
}

check_go() {
    log "Detected Go project"
    
    # Go vet
    if command -v go &>/dev/null; then
        run_check "go vet" "go vet ./..."
    fi
    
    # Staticcheck
    if command -v staticcheck &>/dev/null; then
        run_check "staticcheck" "staticcheck ./..."
    fi
}

# -----------------------------------------------------------------------------
# Universal Checks
# -----------------------------------------------------------------------------

check_secrets() {
    log "Checking for exposed secrets"
    
    # Simple grep for common secret patterns in staged files
    if git rev-parse --git-dir &>/dev/null; then
        local staged_files
        staged_files=$(git diff --cached --name-only 2>/dev/null || true)
        
        if [[ -n "$staged_files" ]]; then
            # Check for hardcoded secrets (simplified pattern)
            if echo "$staged_files" | xargs grep -l -E "(API_KEY|SECRET|TOKEN|PASSWORD)\s*[=:]\s*['\"][A-Za-z0-9_\-]{16,}" 2>/dev/null; then
                echo "⚠️  Warning: Possible hardcoded secrets in staged files" >&2
            fi
        fi
    fi
}

check_env_committed() {
    log "Checking .env not staged"
    
    if git rev-parse --git-dir &>/dev/null; then
        if git diff --cached --name-only 2>/dev/null | grep -q "^\.env"; then
            echo "⚠️  Warning: .env file is staged for commit!" >&2
        fi
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    log "Starting end-of-turn checks"
    
    # Run project-specific checks
    if is_nodejs; then
        check_nodejs
    fi
    
    if is_python; then
        check_python
    fi
    
    if is_rust; then
        check_rust
    fi
    
    if is_go; then
        check_go
    fi
    
    # Universal checks
    check_secrets
    check_env_committed
    
    log "End-of-turn checks complete"
    exit 0
}

main "$@"
