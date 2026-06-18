#!/usr/bin/env bash
# UHDARC Service Status JSON Generator
# Polls all bridge services and outputs a structured JSON health report
# Runs every minute via systemd timer, consumed by web dashboard
set -euo pipefail

services=(
  ysfgateway ysfparrot YSFReflector
  mmdvm_bridge
  p25gateway p25parrot p25reflector
  nxdngateway nxdnparrot
  analog_bridge analog_bridge_ysf analog_bridge_p25 analog_reflector
  asterisk
)

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
host="$(hostname -s 2>/dev/null || hostname)"

uptime_s="$(cut -d. -f1 /proc/uptime)"
loadavg="$(awk '{print $1,$2,$3}' /proc/loadavg)"
mem_json="$(free -b | awk 'NR==2{printf "{\"total\":%s,\"used\":%s,\"free\":%s}",$2,$3,$4}')"
disk_json="$(df -B1 / | awk 'NR==2{printf "{\"total\":%s,\"used\":%s,\"free\":%s}",$2,$3,$4}')"

svc_items=()
down_count=0
for s in "${services[@]}"; do
  state="$(systemctl is-active "$s" 2>/dev/null || echo unknown)"
  enabled="$(systemctl is-enabled "$s" 2>/dev/null || echo unknown)"
  svc_items+=( "$(printf '{"name":"%s","active":"%s","enabled":"%s"}' "$s" "$state" "$enabled")" )
  [[ "$state" == "active" ]] || ((down_count++)) || true
done

overall="ok"
[[ "$down_count" -eq 0 ]] || overall="degraded"

printf '{'
printf '"generated_utc":"%s",' "$ts"
printf '"host":"%s",' "$host"
printf '"overall":"%s",' "$overall"
printf '"health":{"uptime_seconds":%s,"loadavg":"%s","memory":%s,"disk_root":%s},' \
  "$uptime_s" "$loadavg" "$mem_json" "$disk_json"
printf '"services":[%s]' "$(IFS=,; echo "${svc_items[*]}")"
printf '}\n'
