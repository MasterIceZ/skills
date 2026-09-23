#!/usr/bin/env bash
# On-demand Discord bot helper — one-shot REST calls, no persistent gateway process.
# Token comes from ~/.claude/channels/discord/.env (same file the discord plugin uses).
#
# Usage:
#   discordctl.sh send <channel-or-user-id> <message...>
#   discordctl.sh embed <channel-or-user-id> <title> <description...>
#   discordctl.sh read <channel-or-user-id> [limit]
#
# Embed footer shows "Sent by <provider> · <model>". The provider is detected from the agent
# process that launched this script (so a model can't mislabel its harness); DISCORD_PROVIDER is
# used only when detection fails. The model comes from DISCORD_MODEL, e.g.
#   DISCORD_MODEL="Claude Opus 5.5" discordctl.sh embed ...
set -euo pipefail

ENV_FILE="$HOME/.claude/channels/discord/.env"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi
: "${DISCORD_BOT_TOKEN:?DISCORD_BOT_TOKEN not set (expected in $ENV_FILE)}"

API="https://discord.com/api/v10"

api() { # method path [json-body] — retries on Discord 429 rate limits
  local method=$1 path=$2 body=${3:-} resp wait attempt
  for attempt in 1 2 3; do
    resp=$(curl -s -X "$method" "$API$path" \
      -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
      -H "Content-Type: application/json" \
      ${body:+-d "$body"})
    wait=$(jq -r 'if type == "object" then .retry_after // empty else empty end' <<<"$resp" 2>/dev/null)
    if [ -z "$wait" ]; then printf '%s' "$resp"; return; fi
    sleep "$wait"
  done
  printf '%s' "$resp"
}

detect_provider() { # walk up the parent processes to find the agent harness
  local pid=$PPID comm
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null) || break
    case "${comm##*/}" in
      opencode*) echo "OpenCode"; return ;;
      claude*)   echo "Claude Code"; return ;;
    esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  [ -n "${CLAUDECODE:-}" ] && echo "Claude Code"
}

resolve_channel() { # accepts a channel ID, or a user ID (opens a DM)
  local id=$1
  if api GET "/channels/$id" | jq -e .id >/dev/null 2>&1; then
    echo "$id"
  else
    api POST "/users/@me/channels" "{\"recipient_id\":\"$id\"}" | jq -re .id \
      || { echo "error: $id is neither a channel the bot can see nor a DM-able user" >&2; exit 1; }
  fi
}

# jq program for `read`. A forwarded message carries flag 1<<14 (HAS_SNAPSHOT) and an
# empty .content — the text lives in .message_snapshots[].message, so render that too.
READ_JQ='
def render:
  [ (.content // "") ]
  + ((.attachments // []) | map("<attachment: \(.filename) — \(.url)>"))
  + ((.embeds // []) | map("<embed: \(.title // .url // .type // "?")>"))
  | map(select(. != "")) | join("\n");

def indent($p): split("\n") | map($p + .) | join("\n");

if type != "array" then "error: \(.message // .)"
else reverse | .[] | . as $m
  | ($m | render) as $own
  | (($m.message_snapshots // []) | map(.message | render | indent("> ")) | join("\n")) as $fwd
  | ([$own, $fwd] | map(select(. != "")) | join("\n")) as $all
  | "[\($m.timestamp[0:16])] \($m.author.username):"
    + (if $all == "" then " (no readable content)" else "\n" + ($all | indent("  ")) end)
end'

cmd=${1:-}; shift || true
case "$cmd" in
  send)
    id=$1; shift
    ch=$(resolve_channel "$id")
    api POST "/channels/$ch/messages" "$(jq -cn --arg c "$*" '{content:$c}')" \
      | jq -r 'if .id then "sent [\(.id)] to channel \(.channel_id)" else "error: \(.message // .)" end'
    ;;
  embed)
    id=$1; title=$2; shift 2
    ch=$(resolve_channel "$id")
    footer=$(jq -rn --arg p "$(detect_provider || true)" --arg o "${DISCORD_PROVIDER:-}" --arg m "${DISCORD_MODEL:-}" \
      '[(if $p != "" then $p else $o end), $m] | map(select(. != "")) | "Sent by " + (if length == 0 then "an AI agent" else join(" · ") end)')
    api POST "/channels/$ch/messages" \
      "$(jq -cn --arg t "$title" --arg d "$*" --arg f "$footer" '{embeds:[{title:$t, description:$d, color:5793266, footer:{text:$f}}]}')" \
      | jq -r 'if .id then "sent embed [\(.id)] to channel \(.channel_id)" else "error: \(.message // .)" end'
    ;;
  read)
    id=$1; limit=${2:-10}
    ch=$(resolve_channel "$id")
    api GET "/channels/$ch/messages?limit=$limit" | jq -r "$READ_JQ"
    ;;
  *)
    echo "usage: $(basename "$0") send <id> <message...> | embed <id> <title> <description...> | read <id> [limit]" >&2
    exit 1
    ;;
esac
