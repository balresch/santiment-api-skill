---
description: Configure your Santiment API key
allowed-tools: AskUserQuestion, Bash(curl:*), Bash(mkdir:*), Bash(cat:*)
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

3. Write the key to the local settings file using Bash (do NOT use the Write tool — it cannot expand `$HOME`):

```bash
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/santiment-api.local.md" << 'KEYFILE'
---
api_key: "<KEY>"
---

Santiment API key configured by /santiment-api:setup.
KEYFILE
```

Replace `<KEY>` with the user's actual key in the heredoc above.

4. Validate the key by making a lightweight API call:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <KEY>" \
  -d '{"query": "{ currentUser { id } }"}'
```

- If the response contains `"currentUser"` with a non-null `id` → the key is valid. Proceed to step 5.
- If the response contains an error or `currentUser` is null → warn the user their key appears invalid. Ask if they want to re-enter it (go back to step 1) or keep it anyway.

5. Confirm success and instruct the user:

> Your Santiment API key has been saved and validated successfully.
>
> **Restart Claude Code** to activate the key. After restarting, the key will be automatically loaded as `$SANTIMENT_API_KEY` on every session start.
>
> You can update your key at any time by running `/santiment-api:setup` again.
