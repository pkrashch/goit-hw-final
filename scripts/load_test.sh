#!/usr/bin/env bash
# Usage: load_test.sh http://<alb-dns> [duration_seconds] [concurrency]
# Hits the CPU-bound /load endpoint to trigger Auto Scaling.
set -euo pipefail
URL=${1:?alb url}; DUR=${2:-300}; CONC=${3:-30}
if command -v hey >/dev/null; then
  hey -z "${DUR}s" -c "$CONC" "$URL/load"
else
  end=$((SECONDS+DUR))
  for _ in $(seq "$CONC"); do
    ( while [ $SECONDS -lt $end ]; do curl -s -o /dev/null "$URL/load"; done ) &
  done
  wait
fi
