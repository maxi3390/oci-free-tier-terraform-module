#!/usr/bin/env bash

# Rewrites the SSH ingress rule of the module's security list so it only allows
# connections from this machine's current public IP. Intended for cron so a
# changing home IP keeps working; run it every midnight with:
#
#   0 0 * * * SECURITY_LIST_OCID="ocid1.networksecuritylist.oc1..." /path/to/update-ssh-ingress.sh >> "$HOME/.update-ssh-ingress.log" 2>&1
#
# Get the OCID with: terraform output -raw security_list_id
# Alternatively set COMPARTMENT_OCID instead and the security list is discovered
# by its "<Name>SecurityList" display name.
#
# Requires: OCI CLI configured (oci setup config), jq and curl.
#
# NOTE: the security list is managed by Terraform. The next `terraform apply`
# reverts the SSH source to whatever ingress_rules has in your tfvars, so avoid
# re-applying between cron runs (or accept the brief widening).

set -euo pipefail

SECURITY_LIST_OCID="${SECURITY_LIST_OCID:-}"
COMPARTMENT_OCID="${COMPARTMENT_OCID:-}"
SSH_PORT="${SSH_PORT:-22}"
IP_SERVICE="${IP_SERVICE:-https://ipv4.icanhazip.com}"

command -v oci >/dev/null 2>&1 || { echo "oci CLI not found in PATH" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found in PATH" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl not found in PATH" >&2; exit 1; }

if [ -z "$SECURITY_LIST_OCID" ]; then
  if [ -z "$COMPARTMENT_OCID" ]; then
    echo "Set SECURITY_LIST_OCID (terraform output -raw security_list_id) or COMPARTMENT_OCID." >&2
    exit 1
  fi
  SECURITY_LIST_OCID=$(oci network security-list list --compartment-id "$COMPARTMENT_OCID" --all \
    | jq -r '[(.data[]? // .[]) | select((."display-name" // "") | test("SecurityList$"))][0].id // empty')
  [ -n "$SECURITY_LIST_OCID" ] || { echo "No security list found in compartment $COMPARTMENT_OCID." >&2; exit 1; }
fi

CURRENT_IP=$(curl -fsS "$IP_SERVICE" | tr -d '[:space:]')
if ! echo "$CURRENT_IP" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
  echo "Could not determine a valid public IPv4 address (got: '$CURRENT_IP')." >&2
  exit 1
fi

RULES=$(oci network security-list get --security-list-id "$SECURITY_LIST_OCID" \
  | jq '."ingress-security-rules" // .data."ingress-security-rules"')

UPDATED=$(echo "$RULES" | jq -c --arg cidr "$CURRENT_IP/32" --argjson port "$SSH_PORT" '
  map(
    if .protocol == "6"
       and ((.["tcp-options"]["destination-port-range"].min // -1) == $port)
       and ((.["tcp-options"]["destination-port-range"].max // -1) == $port)
    then .source = $cidr
    else . end
  )
  | if any(.[]; .protocol == "6"
             and ((.["tcp-options"]["destination-port-range"].min // -1) == $port)
             and ((.["tcp-options"]["destination-port-range"].max // -1) == $port))
    then .
    else . + [{ protocol: "6", source: $cidr, "tcp-options": { "destination-port-range": { min: $port, max: $port } } }]
    end')

oci network security-list update --security-list-id "$SECURITY_LIST_OCID" \
  --ingress-security-rules "$UPDATED" --force >/dev/null

echo "SSH ingress on port $SSH_PORT now limited to $CURRENT_IP/32 in $SECURITY_LIST_OCID"
