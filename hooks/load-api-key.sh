#!/usr/bin/env bash
# SessionStart hook: load Santiment API key from local settings into environment

SETTINGS_FILE="$HOME/.claude/santiment-api.local.md"

# Exit silently if settings file doesn't exist (user hasn't run /santiment-api:setup)
if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

# Extract api_key from YAML frontmatter
API_KEY=$(sed -n '/^---$/,/^---$/{ /^api_key:/{ s/^api_key: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/; p; } }' "$SETTINGS_FILE")

# Exit silently if no key found
if [ -z "$API_KEY" ]; then
  exit 0
fi

# Write to CLAUDE_ENV_FILE so it's available as an environment variable
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "export SANTIMENT_API_KEY='${API_KEY}'" >> "$CLAUDE_ENV_FILE"
fi
