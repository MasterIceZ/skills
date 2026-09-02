---
name: discord
description: Send or read Discord messages on demand through one-shot bot REST calls, with no persistent gateway process. Use when the user asks to send a Discord message or embed, or to read or check recent messages in a Discord channel or DM.
when_to_use: Trigger phrases include "send a Discord message", "post this to Discord", "DM them on Discord", "check Discord", "read the last messages in that channel".
---

# Discord (on-demand, REST-only)

The `discord@claude-plugins-official` plugin is intentionally disabled: its MCP server keeps a persistent Bun process with a live Discord gateway connection, which drains laptop battery. Leave it disabled and use the helper script instead. Each call is a single REST request that reads the bot token from `~/.claude/channels/discord/.env` and exits immediately.

## Commands

Send a plain message:

```bash
~/.claude/channels/discord/discordctl.sh send <channel-or-user-id> <message text>
```

Send an embed (title + description card):

```bash
~/.claude/channels/discord/discordctl.sh embed <channel-or-user-id> <title> <description text>
```

Read the last N messages (default 10, oldest first):

```bash
~/.claude/channels/discord/discordctl.sh read <channel-or-user-id> [limit]
```

## Choosing send vs embed

Use `embed` for structured or generated content: summaries, reports, digests, multi-line lists, anything with a natural title. Use plain `send` for short conversational messages such as greetings, quick replies, and one-liners.

Embed descriptions support Discord markdown (`**bold**`, `- lists`, newlines; pass real newlines in the argument) and hold up to 4096 characters; keep the title at or under 256 characters. Every embed automatically carries a "Sent by Claude Code" footer, so leave that attribution out of the title and description.

## Notes

- The script accepts either a channel ID or a user ID; for a user ID it opens a DM channel automatically.
- Leave the bot token alone: the script sources it internally from the `.env` file, so there is no reason to print, echo, or pass it.
- Reading uses REST message history, which needs the View Channel and Read Message History bot permissions. No gateway intents are involved, so Message Content Intent is not required.
- `error: Missing Access` means the bot is not in that server or channel; fix the bot's invite or permissions in the Discord Developer Portal.
