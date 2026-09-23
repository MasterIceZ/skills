---
name: discord
description: Send or read Discord messages on demand through one-shot bot REST calls, with no persistent gateway process. Use when the user asks to send a Discord message or embed, or to read or check recent messages in a Discord channel or DM.
when_to_use: Trigger phrases include "send a Discord message", "post this to Discord", "DM them on Discord", "check Discord", "read the last messages in that channel".
---

# Discord (on-demand, REST-only)

The `discord@claude-plugins-official` plugin is intentionally disabled: its MCP server keeps a persistent Bun process with a live Discord gateway connection, which drains laptop battery. Leave it disabled and use the helper script instead. Each call is a single REST request that reads the bot token from `~/.claude/channels/discord/.env` and exits immediately.

## Channel is required

If the request does not name a channel, stop and ask which one. Do not run any `discordctl.sh` command before the answer — not even a read.

This holds even when the request looks like it locates itself:

- **a message ID** — `read` takes a channel ID, and there is no way to resolve a channel from a message ID, so a message ID alone is not a channel
- a username, a topic, "that channel", "the usual one"

Never infer the channel from past transcripts, shell history, or an ID used earlier. A wrong guess reads a channel the user never pointed at, and its contents are then in context for the rest of the session.

## Stay inside the channel you were given

Build the reply, summary, or post only from the channel named in the request, and only from the range asked for. Do not quote, cite, or lean on messages from another channel, or from older history in the same channel outside that range — people in one channel did not agree to be quoted into another. If outside material seems relevant, ask before using it.

## Commands

Send a plain message:

```bash
~/.claude/channels/discord/discordctl.sh send <channel-or-user-id> <message text>
```

Send an embed (title + description card), with a footer naming who sent it:

```bash
DISCORD_MODEL="<your model's display name>" \
  ~/.claude/channels/discord/discordctl.sh embed <channel-or-user-id> <title> <description text>
```

The footer renders as `Sent by <provider> · <model>`, for example `Sent by OpenCode · Qwen 3.5` or `Sent by Claude Code · Claude Opus 5.5`.

- **Provider**: the script detects it from the agent process that launched it (OpenCode, Claude Code). Do not set it yourself. This skill's path under `~/.claude` says nothing about which harness you are running in.
- **Model**: set `DISCORD_MODEL` to the model you actually are, taken from your own system prompt or model ID. Do not copy a name from these examples. If you don't know it, leave `DISCORD_MODEL` unset and the footer shows the provider alone.
- `DISCORD_PROVIDER` is only a fallback for harnesses the script can't detect.

Read the last N messages (default 10, oldest first):

```bash
~/.claude/channels/discord/discordctl.sh read <channel-or-user-id> [limit]
```

Each message prints a `[timestamp] author:` header followed by its indented body. Forwarded
messages are unwrapped from their snapshot and quoted with `>`; attachments and embeds show as
`<attachment: name — url>` and `<embed: title>`.

## Choosing send vs embed

Use `embed` for structured or generated content: summaries, reports, digests, multi-line lists, anything with a natural title. Use plain `send` for short conversational messages such as greetings, quick replies, and one-liners.

Embed descriptions support Discord markdown (`**bold**`, `- lists`, newlines; pass real newlines in the argument) and hold up to 4096 characters; keep the title at or under 256 characters. Every embed carries the `Sent by <provider> · <model>` footer, so leave that attribution out of the title and description.

## Notes

- The script accepts either a channel ID or a user ID; for a user ID it opens a DM channel automatically.
- Leave the bot token alone: the script sources it internally from the `.env` file, so there is no reason to print, echo, or pass it.
- Reading uses REST message history, which needs the View Channel and Read Message History bot permissions. No gateway intents are involved, so Message Content Intent is not required.
- A forwarded message arrives with empty `.content` and flag `16384` (`HAS_SNAPSHOT`) — the real text sits in `.message_snapshots[].message`. `read` unwraps that, so forwarded content is never silently blank.
- `error: Missing Access` means the bot is not in that server or channel; fix the bot's invite or permissions in the Discord Developer Portal.
