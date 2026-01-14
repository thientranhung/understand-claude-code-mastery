#!/usr/bin/env python3
"""
PreToolUse hook to block access to sensitive files.

This hook runs BEFORE Claude can read, edit, or write files.
Exit code 2 blocks the operation and feeds stderr back to Claude.

Usage:
  Add to ~/.claude/settings.json:
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Read|Edit|Write",
          "hooks": [
            {
              "type": "command",
              "command": "python3 ~/.claude/hooks/block-secrets.py"
            }
          ]
        }
      ]
    }
  }

Why this matters:
  - CLAUDE.md rules are suggestions that Claude can override
  - This hook is deterministic enforcement - it ALWAYS runs
  - Even if Claude is "convinced" to read secrets, this blocks it
"""
import json
import sys
from pathlib import Path

# =============================================================================
# CONFIGURATION - Customize these patterns for your environment
# =============================================================================

# Exact filenames to block
SENSITIVE_FILENAMES = {
    # Environment files
    '.env',
    '.env.local',
    '.env.development',
    '.env.development.local',
    '.env.test',
    '.env.test.local',
    '.env.production',
    '.env.production.local',
    '.env.staging',
    
    # Secrets files
    'secrets.json',
    'secrets.yaml',
    'secrets.yml',
    'secrets.toml',
    '.secrets',
    
    # Credentials
    'credentials.json',
    'credentials.yaml',
    'service-account.json',
    'service_account.json',
    
    # SSH keys
    'id_rsa',
    'id_rsa.pub',
    'id_ed25519',
    'id_ed25519.pub',
    'id_ecdsa',
    'id_dsa',
    'known_hosts',
    'authorized_keys',
    
    # Package manager auth
    '.npmrc',
    '.pypirc',
    '.yarnrc',
    '.docker/config.json',
    
    # Cloud credentials
    '.aws/credentials',
    '.aws/config',
    'gcloud/credentials.db',
    '.azure/credentials',
    
    # Git credentials
    '.git-credentials',
    '.gitconfig',  # Can contain credentials
    '.git/config', # Can contain tokens
    
    # Database
    '.pgpass',
    '.my.cnf',
    '.mongorc.js',
}

# File extensions to block
SENSITIVE_EXTENSIONS = {
    '.pem',      # Certificates/keys
    '.key',      # Private keys
    '.p12',      # PKCS#12 certificates
    '.pfx',      # Windows certificates
    '.jks',      # Java keystore
    '.keystore', # Generic keystore
    '.crt',      # Certificates (sometimes contain keys)
    '.cer',      # Certificates
}

# Patterns to match anywhere in path
SENSITIVE_PATH_PATTERNS = [
    'secret',
    'credential',
    'private_key',
    'privatekey',
    '.env.',     # Catches .env.anything
    '/secrets/', # Secrets directories
]

# =============================================================================
# HOOK LOGIC
# =============================================================================

def is_sensitive_file(file_path: str) -> tuple[bool, str]:
    """
    Check if a file path matches sensitive patterns.
    Returns (is_sensitive, reason).
    """
    if not file_path:
        return False, ""
    
    path = Path(file_path)
    file_name = path.name
    file_lower = file_path.lower()
    
    # Check exact filename match
    if file_name in SENSITIVE_FILENAMES:
        return True, f"'{file_name}' is a known sensitive file"
    
    # Check extension
    if path.suffix.lower() in SENSITIVE_EXTENSIONS:
        return True, f"'{path.suffix}' files may contain private keys or certificates"
    
    # Check path patterns
    for pattern in SENSITIVE_PATH_PATTERNS:
        if pattern in file_lower:
            return True, f"path contains sensitive pattern '{pattern}'"
    
    return False, ""


def extract_file_path(data: dict) -> str:
    """
    Extract file path from tool input.
    Different tools use different parameter names.
    """
    tool_input = data.get('tool_input', {})
    
    # Try common parameter names
    for key in ['file_path', 'path', 'filename', 'file']:
        if key in tool_input:
            return tool_input[key]
    
    # For Bash tool, check the command for file references
    command = tool_input.get('command', '')
    if command:
        # This is a simplified check - you might want more sophisticated parsing
        for pattern in SENSITIVE_FILENAMES:
            if pattern in command:
                return pattern
        for ext in SENSITIVE_EXTENSIONS:
            if ext in command:
                return command  # Return command as "file" so it gets blocked
    
    return ""


def main():
    try:
        # Read JSON input from stdin
        data = json.load(sys.stdin)
        
        # Get tool name for better error messages
        tool_name = data.get('tool_name', 'unknown')
        
        # Extract file path
        file_path = extract_file_path(data)
        
        if not file_path:
            # No file path found, allow the operation
            sys.exit(0)
        
        # Check if sensitive
        is_sensitive, reason = is_sensitive_file(file_path)
        
        if is_sensitive:
            # Construct error message that will be fed back to Claude
            error_msg = f"""
╔══════════════════════════════════════════════════════════════════╗
║                    🔒 SECURITY HOOK BLOCKED                       ║
╠══════════════════════════════════════════════════════════════════╣
║ Tool: {tool_name}
║ File: {file_path}
║ 
║ Reason: {reason}
║
║ This file likely contains secrets, credentials, or private keys
║ that should not be accessed programmatically.
║
║ Recommended actions:
║ • Use environment variables instead of reading .env directly
║ • Ask the user for specific (non-sensitive) information
║ • Reference .env.example for variable names only
║ • Store secrets in a proper secrets manager
╚══════════════════════════════════════════════════════════════════╝
""".strip()
            
            # Print to stderr (will be fed back to Claude)
            print(error_msg, file=sys.stderr)
            
            # Exit code 2 = block operation
            sys.exit(2)
        
        # File is not sensitive, allow operation
        sys.exit(0)
        
    except json.JSONDecodeError as e:
        # Invalid JSON input - log but allow (fail open)
        print(f"Hook warning: Invalid JSON input - {e}", file=sys.stderr)
        sys.exit(0)
        
    except Exception as e:
        # Unexpected error - log but allow (fail open)
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == '__main__':
    main()
