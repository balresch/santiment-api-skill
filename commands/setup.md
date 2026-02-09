---
description: Configure your Santiment API key
allowed-tools: Write, AskUserQuestion
---

Set up the user's Santiment API key for persistent use across sessions.

## What This Does

The Santiment API requires an API key for authentication. This command saves your key locally so it's automatically loaded on every Claude Code session start — no need to paste it each time.

Your key is stored in `.claude/santiment-api.local.md`, which is gitignored and never committed.

## Steps

1. Ask the user for their API key:

> To use the Santiment API, I need your API key. You can get one (free tier available) at:
>
> https://app.santiment.net/account#api-keys
>
> Please paste your Santiment API key.

2. Once the user provides the key, validate that it looks like a non-empty string (no further validation needed — the API will reject invalid keys on first use).

3. Write the key to the local settings file:

Write the file `${CLAUDE_PLUGIN_ROOT}/.claude/santiment-api.local.md` with this exact content (replacing `<KEY>` with the user's key):

```
---
api_key: "<KEY>"
---

Santiment API key configured by /santiment-api:setup.
```

4. Confirm success and instruct the user:

> Your Santiment API key has been saved to the plugin's `.claude/santiment-api.local.md`.
>
> **Restart Claude Code** to activate the key. After restarting, the key will be automatically loaded as `$SANTIMENT_API_KEY` on every session start.
>
> You can update your key at any time by running `/santiment-api:setup` again.
