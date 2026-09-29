#!/usr/bin/env bash

# Retries `terraform apply` until it succeeds, with a delay between attempts.
# Useful against OCI "Out of Capacity" errors on the Always Free tier.
#
# Only retries on capacity/rate-limit errors; any other failure (config,
# validation, auth, etc.) is printed and aborts immediately.
#
# Environment overrides:
#   MAX_ATTEMPTS       maximum number of apply attempts (default: 30)
#   SLEEP_SECONDS      initial delay between attempts in seconds (default: 60)
#   MAX_SLEEP_SECONDS  ceiling for the exponential backoff (default: 600)

set -u

MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-60}"
MAX_SLEEP_SECONDS="${MAX_SLEEP_SECONDS:-600}"

# OCI errors worth retrying (case-insensitive).
RETRY_PATTERN='out of host capacity|out of capacity|TooManyRequests'

attempt=1
sleep_seconds="$SLEEP_SECONDS"

until output=$(terraform apply -no-color -auto-approve 2>&1); do
  if ! echo "$output" | grep -qiE "$RETRY_PATTERN"; then
    echo "$output" >&2
    echo "Apply failed with a non-retryable error after $attempt attempt(s)." >&2
    exit 1
  fi
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "$output" >&2
    echo "Giving up after $attempt attempts." >&2
    exit 1
  fi
  echo "Apply failed with a capacity error (attempt $attempt/$MAX_ATTEMPTS); retrying in ${sleep_seconds}s..." >&2
  attempt=$((attempt + 1))
  sleep "$sleep_seconds"
  sleep_seconds=$((sleep_seconds * 2))
  [ "$sleep_seconds" -le "$MAX_SLEEP_SECONDS" ] || sleep_seconds="$MAX_SLEEP_SECONDS"
done

echo "$output"
echo "Apply succeeded after $attempt attempt(s)."
