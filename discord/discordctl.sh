#!/usr/bin/env bash
# On-demand Discord bot helper — one-shot REST calls, no persistent gateway process.
# Token comes from ~/.claude/channels/discord/.env (same file the discord plugin uses).
#
# Usage:
#   discordctl.sh send <channel-or-user-id> <message...>
#   discordctl.sh read <channel-or-user-id> [limit]
set -euo pipefail

ENV_FILE="$HOME/.claude/channels/discord/.env"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi
: "${DISCORD_BOT_TOKEN:?DISCORD_BOT_TOKEN not set (expected in $ENV_FILE)}"

API="https://discord.com/api/v10"

api() { # method path [json-body]
  local method=$1 path=$2 body=${3:-}
  curl -s -X "$method" "$API$path" \
    -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    ${body:+-d "$body"}
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

cmd=${1:-}; shift || true
case "$cmd" in
  send)
    id=$1; shift
    ch=$(resolve_channel "$id")
    api POST "/channels/$ch/messages" "$(jq -cn --arg c "$*" '{content:$c}')" \
      | jq -r 'if .id then "sent [\(.id)] to channel \(.channel_id)" else "error: \(.message // .)" end'
    ;;
  read)
    id=$1; limit=${2:-10}
    ch=$(resolve_channel "$id")
    api GET "/channels/$ch/messages?limit=$limit" \
      | jq -r 'if type == "array" then reverse | .[] |
          "[\(.timestamp[0:16])] \(.author.username): \(.content)\(if (.attachments | length) > 0 then " <\(.attachments | length) attachment(s)>" else "" end)"
        else "error: \(.message // .)" end'
    ;;
  *)
    echo "usage: $(basename "$0") send <id> <message...> | read <id> [limit]" >&2
    exit 1
    ;;
esac
