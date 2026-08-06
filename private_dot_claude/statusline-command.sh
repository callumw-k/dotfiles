#!/bin/bash

input=$(cat)

repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
if [ -z "$repo_name" ]; then
  project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd')
  repo_name=$(basename "$project_dir")
fi

cwd=$(echo "$input" | jq -r '.cwd')
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Plan quota usage: 5-hour session + 7-day weekly windows (Pro/Max only, populated
# after the first API response). Fall back to context-window % until they appear.
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
session_id=$(echo "$input" | jq -r '.session_id // empty')
now=$(date +%s)

# The payload carries no terminal width and this script runs detached (no /dev/tty),
# so read the size off the tty of the nearest ancestor that has one. Moshi attaches
# at ~40 columns, where the full line truncates mid-meter.
cols=""
p=$PPID
for _ in 1 2 3 4; do
  t=$(ps -o tty= -p "$p" 2>/dev/null | tr -d ' ')
  case "$t" in
    pts/*|tty[0-9]*) cols=$(stty size < "/dev/$t" 2>/dev/null | cut -d' ' -f2); break ;;
  esac
  p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  case "$p" in ''|0|1) break ;; esac
done
case "$cols" in ''|*[!0-9]*) cols=80 ;; esac

if [ "$cols" -ge 90 ]; then
  tier=full; bar_cells=10
elif [ "$cols" -ge 60 ]; then
  tier=mid; bar_cells=5
else
  tier=min; bar_cells=0
fi

# On-demand overage cost: once quota (5h or 7d) is exhausted, further API calls bill
# at cost.total_cost_usd rates. That field is per-process and cumulative since
# session start (resets on /clear), so each session records an overage baseline:
# the cumulative cost seen at the render where it first observes quota exceeded for
# the current window (keyed by five_reset). window_cost sums (cost - overage_baseline)
# per session that has exceeded, so only spend incurred after crossing exhaustion counts —
# not pre-overage usage, not the whole window.
# The rate_limits header caps at 99% and never reports 100 even once genuinely
# exhausted (verified: stuck at 99% for 20+ minutes of continued spend while the
# web admin console showed 100%), so 99 is treated as the exhaustion point, not 100.
# Once the 5h reset time has passed, treat the session quota as reset even if a stale
# used_percentage still reads 99 (rate limits only refresh on the next API response).
exceeded=$(awk -v a="${five_pct:-0}" -v b="${seven_pct:-0}" -v r="${five_reset:-0}" -v now="$now" \
  'BEGIN{print ((a>=99||b>=99) && (r==0 || now<r)) ? 1 : 0}')
window_cost=0
if [ -n "$session_id" ] && [ -n "$five_reset" ]; then
  sc_dir="$HOME/.claude/metrics/session-cost"
  mkdir -p "$sc_dir"
  sc_file="$sc_dir/${session_id}.json"
  overage_baseline=$(jq -r --argjson fr "$five_reset" \
    'if .five_reset == $fr and .overage_baseline != null then .overage_baseline else empty end' "$sc_file" 2>/dev/null)
  # cost resets to 0 on /clear but the account can still be over quota, so a baseline
  # higher than the current cost means this session cleared mid-window: re-baseline to
  # 0 so the (now small) cost counts in full instead of going negative in the sum below.
  if [ -n "$overage_baseline" ] && awk -v c="$cost" -v b="$overage_baseline" 'BEGIN{exit !(c<b)}'; then
    overage_baseline=0
  fi
  [ "$exceeded" = "1" ] && [ -z "$overage_baseline" ] && overage_baseline=$cost
  ob_json="null"; [ -n "$overage_baseline" ] && ob_json=$overage_baseline
  printf '{"five_reset":%s,"overage_baseline":%s,"cost":%s,"ts":%d}' "$five_reset" "$ob_json" "$cost" "$now" > "$sc_file"
  window_cost=$(jq -s --argjson fr "$five_reset" \
    '[.[]|select(.five_reset==$fr and .overage_baseline!=null)|([(.cost-.overage_baseline),0]|max)]|add // 0' "$sc_dir"/*.json 2>/dev/null || echo 0)

  # Dead sessions' files are never removed otherwise. Sweep files untouched for 2+ days
  # (well past any 5h/7d window), gated to once a day so this doesn't hit the filesystem
  # on every render.
  prune_marker="$sc_dir/.last-prune"
  if [ ! -f "$prune_marker" ] || [ -n "$(find "$prune_marker" -mtime +1 2>/dev/null)" ]; then
    find "$sc_dir" -maxdepth 1 -name '*.json' -mtime +2 -delete 2>/dev/null
    touch "$prune_marker"
  fi
fi

esc() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
esc_bold() { printf '\033[1;38;2;%d;%d;%dm' "$1" "$2" "$3"; }
reset=$'\033[0m'
dim_gray=$'\033[38;2;170;170;170m'

# Green(0,200,80) -> Yellow(220,200,0) -> Red(220,40,20), t in [0,1]
grad() {
  awk -v t="$1" 'BEGIN{
    if (t < 0) t = 0; if (t > 1) t = 1;
    g0r=0; g0g=200; g0b=80;
    y0r=220; y0g=200; y0b=0;
    r0r=220; r0g=40; r0b=20;
    if (t < 0.5) {
      f = t/0.5;
      r = g0r + (y0r-g0r)*f;
      g = g0g + (y0g-g0g)*f;
      b = g0b + (y0b-g0b)*f;
    } else {
      f = (t-0.5)/0.5;
      r = y0r + (r0r-y0r)*f;
      g = y0g + (r0g-y0g)*f;
      b = y0b + (r0b-y0b)*f;
    }
    printf "%d %d %d", r, g, b;
  }'
}

# Render "bar emoji pct%" for a usage percentage.
meter() {
  local p="$1" filled i t rgb r g b pct_int
  filled=$(awk -v p="$p" -v n="$bar_cells" 'BEGIN{v=p/100*n; printf "%d", (v+0.5)}')
  [ "$filled" -gt "$bar_cells" ] && filled=$bar_cells
  [ "$filled" -lt 0 ] && filled=0
  # Solid fill: whole bar takes the single gradient colour for its level, so the
  # bar colour reads as severity (matches the % beside it) rather than position.
  rgb=$(grad "$(awk -v p="$p" 'BEGIN{printf "%.4f", p/100}')")
  r=$(echo "$rgb" | cut -d' ' -f1); g=$(echo "$rgb" | cut -d' ' -f2); b=$(echo "$rgb" | cut -d' ' -f3)
  local out=""
  for i in $(seq 0 $((bar_cells - 1))); do
    if [ "$i" -lt "$filled" ]; then
      out="${out}$(esc "$r" "$g" "$b")█"
    else
      out="${out}$(esc 60 60 60)█"
    fi
  done
  pct_int=$(awk -v p="$p" 'BEGIN{printf "%d", p}')
  [ -n "$out" ] && out="${out}${reset} "
  printf '%s%s%d%%%s' "$out" "$(esc "$r" "$g" "$b")" "$pct_int" "$reset"
}

sep="${dim_gray} │ ${reset}"

line="$(esc_bold 255 215 0)${repo_name}${reset}"
if [ -n "$branch" ]; then
  # A long branch name would push the meters off the right edge, so cap it at a
  # quarter of the terminal: 10 chars at moshi's ~40 cols, 30 at 120.
  max_branch=$((cols / 4))
  [ "${#branch}" -gt "$max_branch" ] && branch="${branch:0:$((max_branch - 1))}…"
  line="${line}${sep}$(esc_bold 0 200 200)(${branch})${reset}"
fi
if [ "$tier" != min ]; then
  line="${line}${sep}$(esc 170 130 255)${model}${reset}"
  [ -n "$effort" ] && [ "$tier" != min ] && line="${line} ${dim_gray}${effort}${reset}"
fi
if [ "$tier" = full ]; then lbl_q="session quota"; lbl_c="context"; else lbl_q="5h"; lbl_c="ctx"; fi
if [ -n "$five_pct" ]; then
  line="${line}${sep}${dim_gray}${lbl_q}${reset} $(meter "$five_pct")"
  if [ -n "$five_reset" ] && [ "$tier" != min ]; then
    reset_str=$(awk -v r="$five_reset" -v now="$now" 'BEGIN{
      d=r-now; if (d<0) d=0;
      h=int(d/3600); m=int((d%3600)/60);
      if (h>0) printf "%dh%02dm", h, m; else printf "%dm", m;
    }')
    line="${line} ${dim_gray}↻ ${reset_str}${reset}"
  fi
  # Quota exhausted -> on-demand spend now applies, so surface the cost at every width.
  if [ "$exceeded" = "1" ]; then
    line="${line} ${dim_gray}→${reset} $(esc 255 140 0)$(awk -v c="$window_cost" 'BEGIN{printf "$%.2f", c}')${reset}"
  fi
  if [ -n "$seven_pct" ] && [ "$tier" != min ]; then
    s_int=$(awk -v p="$seven_pct" 'BEGIN{printf "%d", p}')
    s_rgb=$(grad "$(awk -v p="$seven_pct" 'BEGIN{printf "%.4f", p/100}')")
    sr=$(echo "$s_rgb" | cut -d' ' -f1); sg=$(echo "$s_rgb" | cut -d' ' -f2); sb=$(echo "$s_rgb" | cut -d' ' -f3)
    line="${line}${sep}${dim_gray}7d${reset} $(esc "$sr" "$sg" "$sb")${s_int}%${reset}"
  fi
fi
line="${line}${sep}${dim_gray}${lbl_c}${reset} $(meter "$ctx_pct")"

printf '%s' "$line"
