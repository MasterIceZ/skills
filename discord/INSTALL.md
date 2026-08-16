# Installing the discord skill

Instructions for installing this skill on a new machine. Written to be executed by an AI agent (Claude Code) or a human, step by step. All paths are exact; run commands from this directory (`discord/` in this repo).

## What this skill is

On-demand Discord send/read for Claude Code via one-shot REST calls. It deliberately replaces the `discord@claude-plugins-official` plugin, whose MCP server keeps a persistent Bun process with a live Discord gateway connection running (battery drain). This skill runs nothing in the background: each send/read is a single `curl` call that exits immediately.

## Prerequisites

| Requirement | Check | Notes |
|---|---|---|
| `curl` | `which curl` | preinstalled on macOS/Linux |
| `jq` | `which jq` | install via `brew install jq` / `apt install jq` |
| Discord bot token | see "Discord bot setup" below | stored locally, never committed |
| Claude Code | `claude --version` | skill loads from `~/.claude/skills/` |

## Installation steps

Execute in order. Step 4 requires a secret only the user can provide — if the token is not already available at the target path, stop and ask the user for it; never guess or reuse a token from another source.

1. **Install the skill definition** (makes `/discord` available to Claude Code):

   ```bash
   mkdir -p ~/.claude/skills/discord
   cp SKILL.md ~/.claude/skills/discord/SKILL.md
   ```

2. **Install the helper script** at the exact path SKILL.md references:

   ```bash
   mkdir -p ~/.claude/channels/discord
   cp discordctl.sh ~/.claude/channels/discord/discordctl.sh
   chmod +x ~/.claude/channels/discord/discordctl.sh
   ```

3. **Check for an existing token** — if `~/.claude/channels/discord/.env` already exists and contains `DISCORD_BOT_TOKEN=`, skip to step 5:

   ```bash
   grep -q '^DISCORD_BOT_TOKEN=' ~/.claude/channels/discord/.env 2>/dev/null && echo "token present, skip step 4" || echo "token missing, do step 4"
   ```

4. **Store the bot token** (ask the user for it; see "Discord bot setup" if they don't have one):

   ```bash
   printf 'DISCORD_BOT_TOKEN=%s\n' '<token>' > ~/.claude/channels/discord/.env
   chmod 600 ~/.claude/channels/discord/.env
   ```

   Never echo, log, or commit the token. The script sources this file internally.

5. **Verify** — read a channel the bot can see (any known channel or user ID):

   ```bash
   ~/.claude/channels/discord/discordctl.sh read <channel-or-user-id> 3
   ```

   Expected: up to 3 message lines like `[2026-08-16T07:05] username: text`. See "Troubleshooting" for error outputs.

6. **Reload Claude Code** so the skill registers: run `/reload-plugins` in an existing session, or start a new session. Confirm `discord` appears in the available-skills list.

## Discord bot setup (only if no bot/token exists yet)

The user must do this in a browser at https://discord.com/developers/applications — an agent cannot do it for them:

1. **New Application** → name it → **Bot** page → **Reset Token** → copy the token (shown once).
2. Bot permissions needed by this skill: **View Channels**, **Send Messages**, **Embed Links** (for the `embed` subcommand), **Read Message History**. (Message Content Intent is NOT required — that gates gateway events; this skill uses REST only.)
3. Invite the bot: **OAuth2 → URL Generator** → scope `bot` → the three permissions above → open the generated URL and add the bot to the target server. To DM a user, the bot must share at least one server with them.

## Important constraints (for the installing agent)

- **Do not** install or enable the `discord@claude-plugins-official` plugin as part of this setup. If it is present in `~/.claude/settings.json` under `enabledPlugins`, its value must be `false`. This skill exists specifically to avoid the plugin's persistent gateway process.
- This skill is **pull-only**: it cannot notify on incoming messages. That limitation is intentional; do not "fix" it by enabling the plugin.
- The `.env` file and the token must never be committed to any repo or printed to any output.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `error: Missing Access` | Bot not in that server/channel or lacks permissions | Re-invite bot with the three permissions above |
| `error: 401: Unauthorized` | Token wrong/reset | Get a fresh token (Reset Token), redo step 4 |
| `error: <id> is neither a channel...` | ID invalid, or user shares no server with the bot | Verify the ID; add the bot to a shared server |
| `jq: command not found` | jq missing | `brew install jq` / `apt install jq` |
| Skill not in skills list | Session predates install | `/reload-plugins` or new session |
