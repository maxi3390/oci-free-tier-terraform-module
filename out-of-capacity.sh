#!/usr/bin/env bash

# Retries `terraform apply` until it succeeds, with a delay between attempts.
# Useful against OCI "Out of Capacity" errors on the Always Free tier.
#
# Environment overrides:
#   MAX_ATTEMPTS  maximum number of apply attempts (default: 30)
#   SLEEP_SECONDS delay between attempts in seconds (default: 60)

set -u

MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-60}"

attempt=1
until terraform apply -no-color -auto-approve; do
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "Giving up after $attempt attempts." >&2
    exit 1
  fi
  echo "Apply failed (attempt $attempt/$MAX_ATTEMPTS); retrying in ${SLEEP_SECONDS}s..."
  attempt=$((attempt + 1))
  sleep "$SLEEP_SECONDS"
done

echo "Apply succeeded after $attempt attempt(s)."
