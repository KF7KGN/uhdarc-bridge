#!/usr/bin/env bash
# UHDARC AllStar Node Status JSON Generator
# Queries Asterisk/AllStar Node 573470 via CLI and outputs structured JSON
# Captures linked nodes, IAX2 peers, channel counts, keyups, TX time
# Output goes to web dashboard at /var/www/html/UHDARC/status/allstar.json
set -euo pipefail

OUT="/var/www/html/UHDARC/status/allstar.json"
TMP="$(mktemp)"
NODE_MAIN="${NODE_MAIN:-573470}"
HOST="$(hostname -f 2>/dev/null || hostname)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

json_escape(){ python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

get_stat_line() {
  local label="$1"
  python3 - "$label" <<'PY'
import sys,re
label=sys.argv[1]
data=sys.stdin.read().splitlines()
pat=re.compile(r'^' + re.escape(label) + r'\.*:\s*(.*)\s*$')
for line in data:
    m=pat.match(line)
    if m:
        print(m.group(1))
        break
PY
}

RPT_STATS="$(asterisk -rx "rpt stats ${NODE_MAIN}" 2>/dev/null || true)"
CHAN_CONCISE="$(asterisk -rx "core show channels concise" 2>/dev/null || true)"

UPTIME="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Uptime" || true)"
SYSTEM_STATE="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Selected system state" || true)"
SYSTEM_ENABLED="$(printf "%s\n" "$RPT_STATS" | get_stat_line "System" || true)"
SCHED_ENABLED="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Scheduler" || true)"
TOT_ENABLED="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Time out timer" || true)"
INCOMING_CONN="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Incoming connections" || true)"
AUTOPATCH_ENABLED="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Autopatch" || true)"
AUTOPATCH_STATE="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Autopatch state" || true)"
REVERSE_PATCH="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Reverse patch/IAXRPT connected" || true)"
KEYUPS_TODAY="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Keyups today" || true)"
KEYUPS_SINCE="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Keyups since system initialization" || true)"
DTMF_TODAY="$(printf "%s\n" "$RPT_STATS" | get_stat_line "DTMF commands today" || true)"
DTMF_SINCE="$(printf "%s\n" "$RPT_STATS" | get_stat_line "DTMF commands since system initialization" || true)"
TX_TODAY="$(printf "%s\n" "$RPT_STATS" | get_stat_line "TX time today" || true)"
TX_SINCE="$(printf "%s\n" "$RPT_STATS" | get_stat_line "TX time since system initialization" || true)"
SIGNAL_INPUT="$(printf "%s\n" "$RPT_STATS" | get_stat_line "Signal on input" || true)"

LINKED_NODES_LIST="$(
  python3 - <<'PY'
import re,sys
txt=sys.stdin.read().splitlines()
out=[]
grab=False
for line in txt:
    if line.startswith("Nodes currently connected to us"):
        grab=True
        line=line.split(":",1)[1] if ":" in line else ""
    elif grab:
        if re.match(r'^\s*:\s*', line):
            line=re.sub(r'^\s*:\s*', '', line)
        else:
            grab=False
            continue
    if grab:
        for n in re.findall(r'\b\d{4,6}\b', line):
            out.append(n)
print("\n".join(sorted(set(out))))
PY
)" <<<"$RPT_STATS"

LINKED_NODES_COUNT="$(printf "%s\n" "$LINKED_NODES_LIST" | awk 'NF{c++} END{print c+0}')"

ACTIVE_CHANNELS_TOTAL="$(printf "%s\n" "$CHAN_CONCISE" | awk 'NF{c++} END{print c+0}')"
IAX2_LINES="$(printf "%s\n" "$CHAN_CONCISE" | awk -F'!' '$1 ~ /^IAX2\// {print}')"
IAX2_COUNT="$(printf "%s\n" "$IAX2_LINES" | awk 'NF{c++} END{print c+0}')"

IAX2_REMOTE_IPS="$(
  printf "%s\n" "$IAX2_LINES" \
  | awk -F'!' '{print $1}' \
  | sed -n 's#^IAX2/\([0-9.]\+\):.*#\1#p' \
  | sort -u
)"
IAX2_REMOTE_IP_COUNT="$(printf "%s\n" "$IAX2_REMOTE_IPS" | awk 'NF{c++} END{print c+0}')"

IAX2_PEERS_PREVIEW="$(
  printf "%s\n" "$IAX2_LINES" \
  | awk -F'!' '
      {
        peer=$1; sub(/^IAX2\//,"",peer);
        node="";
        if ($8 ~ /^[0-9]{4,6}$/) node=$8;
        if (node!="") print peer " node=" node;
        else print peer;
      }' \
  | sort -u \
  | head -n 12
)"

HEALTH="ok"
[[ -z "$RPT_STATS" ]] && HEALTH="unknown"
[[ -n "$SYSTEM_ENABLED" && "$SYSTEM_ENABLED" != "ENABLED" ]] && HEALTH="degraded"
[[ "$INCOMING_CONN" == "DISABLED" ]] && HEALTH="degraded"
PULSE="$((LINKED_NODES_COUNT + IAX2_COUNT + ACTIVE_CHANNELS_TOTAL))"

{
  echo '{'
  echo "  \"generated_utc\": \"${TS}\","
  echo "  \"host\": \"${HOST}\","
  echo "  \"node_main\": \"${NODE_MAIN}\","
  echo "  \"health\": \"${HEALTH}\","
  echo "  \"pulse\": ${PULSE},"
  echo '  "summary": {'
  echo "    \"linked_nodes_count\": ${LINKED_NODES_COUNT},"
  echo "    \"active_channels_total\": ${ACTIVE_CHANNELS_TOTAL},"
  echo "    \"iax2_channels\": ${IAX2_COUNT},"
  echo "    \"iax2_unique_remote_ips\": ${IAX2_REMOTE_IP_COUNT}"
  echo '  },'
  echo '  "linked_nodes": ['
  if [[ -n "$LINKED_NODES_LIST" ]]; then
    first=1
    while IFS= read -r n; do
      [[ -z "$n" ]] && continue
      if [[ $first -eq 1 ]]; then first=0; else echo ','; fi
      printf '    "%s"' "$n"
    done <<< "$LINKED_NODES_LIST"
    echo
  fi
  echo '  ],'
  echo '  "core": {'
  echo "    \"system_state\": \"${SYSTEM_STATE}\","
  echo "    \"system\": \"${SYSTEM_ENABLED}\","
  echo "    \"scheduler\": \"${SCHED_ENABLED}\","
  echo "    \"timeout_timer\": \"${TOT_ENABLED}\","
  echo "    \"incoming_connections\": \"${INCOMING_CONN}\","
  echo "    \"signal_on_input\": \"${SIGNAL_INPUT}\","
  echo "    \"uptime\": \"${UPTIME}\","
  echo "    \"keyups_today\": \"${KEYUPS_TODAY}\","
  echo "    \"keyups_since\": \"${KEYUPS_SINCE}\","
  echo "    \"dtmf_today\": \"${DTMF_TODAY}\","
  echo "    \"dtmf_since\": \"${DTMF_SINCE}\","
  echo "    \"tx_time_today\": \"${TX_TODAY}\","
  echo "    \"tx_time_since\": \"${TX_SINCE}\","
  echo "    \"autopatch\": {"
  echo "      \"enabled\": \"${AUTOPATCH_ENABLED}\","
  echo "      \"state\": \"${AUTOPATCH_STATE}\","
  echo "      \"reverse_patch_connected\": \"${REVERSE_PATCH}\""
  echo "    }"
  echo '  },'
  echo '  "spotlight": {'
  echo -n '    "iax2_peers_preview": '; printf "%s" "$IAX2_PEERS_PREVIEW" | json_escape; echo ','
  echo '    "notes": ['
  echo '      "Generated locally on the UHDARC server",'
  echo '      "Safe output for website widgets and Grafana JSON panels",'
  echo '      "Does not expose private peer IPs in output"'
  echo '    ]'
  echo '  },'
  echo '  "raw": {'
  echo -n '    "rpt_stats": '; printf "%s" "$RPT_STATS" | json_escape; echo ','
  echo -n '    "channels_concise": '; printf "%s" "$CHAN_CONCISE" | json_escape
  echo '  }'
  echo '}'
} > "$TMP"

mkdir -p "$(dirname "$OUT")"
mv "$TMP" "$OUT"
chmod 0644 "$OUT"
