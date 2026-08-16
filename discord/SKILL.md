---
name: discord
description: Send or read Discord messages on demand via one-shot bot REST calls — no persistent gateway process. Use when the user asks to send a Discord message or read/check messages in a Discord channel or DM.
---

# Discord (on-demand, REST-only)

The `discord@claude-plugins-official` plugin is **intentionally disabled** — its MCP server keeps a persistent Bun process with a live Discord gateway connection, which drains laptop power. Do not re-enable it. Use the helper script instead; it makes single REST calls with the bot token stored in `~/.claude/channels/discord/.env` and exits immediately.

Send a plain message:

```bash
~/.claude/channels/discord/discordctl.sh send <channel-or-user-id> <message text>
```

Send an embed (title + description card):

```bash
~/.claude/channels/discord/discordctl.sh embed <channel-or-user-id> <title> <description text>
```

**Choosing send vs embed:** use `embed` whenever the content is structured or generated — summaries, reports, digests, multi-line lists, anything that has a natural title. Use plain `send` for short conversational messages (greetings, quick replies, one-liners). Embed descriptions support Discord markdown (`**bold**`, `- lists`, newlines — pass real newlines in the argument) and hold up to 4096 chars; keep the title ≤ 256 chars.

Read the last N messages (default 10, oldest first):

```bash
~/.claude/channels/discord/discordctl.sh read <channel-or-user-id> [limit]
```

Notes:

- The script accepts either a **channel ID** or a **user ID** — for a user ID it opens a DM channel automatically.
- Never print or echo the bot token; the script sources it internally from the `.env` file.
- Reading uses REST message history (needs View Channel + Read Message History bot permissions); no gateway intents are involved, so Message Content Intent is not required for this path.
- If the API returns `error: Missing Access` the bot isn't in that server/channel — fix the bot's invite/permissions in the Discord Developer Portal.
