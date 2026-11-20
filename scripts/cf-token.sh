#!/usr/bin/env bash
# Create a scoped Cloudflare API token for Terraform and store it directly in
# the GitHub Actions secret TF_CLOUDFLARE_API_TOKEN (the value is never shown).
#
# Usage (from a regular terminal):
#   ./scripts/cf-token.sh
#
# The script walks you through everything. Optional overrides:
#   ZONE_ID     Cloudflare zone id (default: the oracle-k8s zone)
#   GH_ENV      store as a GitHub environment secret instead of a repo secret
#   TOKEN_DAYS  validity of the new token in days (default 365)
#   REPO        GitHub repository (default germanium-git/oracle-k8s)
set -euo pipefail

ZONE_ID="${ZONE_ID:-7d3f63ac039666ab600b5796c54e7ba6}"
REPO="${REPO:-germanium-git/oracle-k8s}"
TOKEN_DAYS="${TOKEN_DAYS:-365}"
CF=https://api.cloudflare.com/client/v4

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
die()  { printf '    \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# --- checks -----------------------------------------------------------------
step "Checking prerequisites"
for cmd in curl jq gh; do
  command -v "$cmd" >/dev/null || die "Missing '$cmd'. Install it and run again."
done
gh auth status >/dev/null 2>&1 || die "GitHub CLI is not logged in. Run: gh auth login"
[[ -t 0 ]] || die "Run this script in a regular terminal; it needs to ask for input."
ok "curl, jq and gh are available, gh is logged in"

# --- bootstrap token ---------------------------------------------------------
step "Bootstrap token (a short-lived token that is allowed to create the real one)"
TOKENS_URL=https://dash.cloudflare.com/profile/api-tokens
cat <<EOF
    Create it in the Cloudflare dashboard now:

      1. Open ${TOKENS_URL}
         (My Profile -> API tokens. NOT "Manage Account -> Account API Tokens")
      2. Click "Create Token"
      3. Token name:         bootstrap
      4. Policies:           click "Create additional tokens"   (1 permission)
                             NOT "Edit zone DNS" or "Read all resources"
      5. Token expiration:   7 days
      6. Create the token and click the copy button next to it

EOF

open_url() {
  if command -v wslview >/dev/null 2>&1; then wslview "$1"
  elif command -v cmd.exe >/dev/null 2>&1; then cmd.exe /c start "" "$1" 2>/dev/null
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1"
  elif command -v open >/dev/null 2>&1; then open "$1"
  else return 1
  fi
}
read -rp "    Press Enter to open that page in your browser (or 's' to skip): " choice
if [[ "${choice,,}" != "s" ]]; then
  open_url "$TOKENS_URL" >/dev/null 2>&1 || echo "    Couldn't open a browser, open the link above manually."
fi

BOOT=""
# On WSL, take the token straight from the Windows clipboard
if command -v powershell.exe >/dev/null 2>&1; then
  echo
  read -rp "    Token copied? Press Enter to read it from the clipboard (or 'p' to paste it here): " choice
  if [[ "${choice,,}" != "p" ]]; then
    BOOT=$(powershell.exe -NoProfile -Command Get-Clipboard 2>/dev/null | tr -d '\r\n[:space:]')
  fi
else
  echo
  read -rp "    Press Enter once you have copied the token... " _
fi
if [[ -z "$BOOT" ]]; then
  echo "    Paste the token and press Enter (input is hidden; in Windows Terminal"
  echo "    paste with Ctrl+Shift+V or right-click):"
  read -rsp "    > " BOOT
  echo
  BOOT=$(tr -d '\r\n[:space:]' <<<"$BOOT")
fi
[[ -n "$BOOT" ]] || die "Nothing was received. Copy the token again and re-run."
ok "Received a token of ${#BOOT} characters ending in …${BOOT: -4}"

api() {
  curl -sS -H "Authorization: Bearer $BOOT" -H "Content-Type: application/json" "$@"
}
cf_error() { jq -r '[.errors[]? | "\(.code): \(.message)"] | join("; ")' <<<"$1"; }

step "Verifying the bootstrap token"
VERIFY=$(api "$CF/user/tokens/verify")
[[ $(jq -r '.result.status // empty' <<<"$VERIFY") == "active" ]] \
  || die "Cloudflare rejected this token ($(cf_error "$VERIFY")). Copy the token again (the copy button next to it) and re-run. If the clipboard held something else, choose 'p' and paste it."
ok "Token is active"

PG=$(api "$CF/user/tokens/permission_groups")
[[ $(jq -r '.success' <<<"$PG") == "true" ]] \
  || die "This token can't create other tokens ($(cf_error "$PG")). Make a new one with the policy \"Create additional tokens\" and re-run."
DNS_WRITE=$(jq -r '.result[] | select(.name=="DNS Write") | .id' <<<"$PG")
ZONE_READ=$(jq -r '.result[] | select(.name=="Zone Read") | .id' <<<"$PG")
[[ -n "$DNS_WRITE" && -n "$ZONE_READ" ]] || die "Couldn't find the 'DNS Write' / 'Zone Read' permissions."
ok "Token can create other tokens"

# --- create the Terraform token ---------------------------------------------
step "Creating the Terraform token"
EXPIRES=$(date -u -d "+${TOKEN_DAYS} days" +%Y-%m-%dT%H:%M:%SZ)
BODY=$(jq -n --arg z "$ZONE_ID" --arg d "$DNS_WRITE" --arg r "$ZONE_READ" \
  --arg exp "$EXPIRES" --arg name "oracle-k8s terraform $(date -u +%F)" '{
    name: $name,
    expires_on: $exp,
    policies: [{
      effect: "allow",
      resources: { ("com.cloudflare.api.account.zone." + $z): "*" },
      permission_groups: [{id: $d}, {id: $r}]
    }]
  }')
CREATED=$(api -X POST "$CF/user/tokens" -d "$BODY")
TOKEN=$(jq -r '.result.value // empty' <<<"$CREATED")
unset BOOT
[[ -n "$TOKEN" ]] || die "Cloudflare didn't create the token ($(cf_error "$CREATED"))."
ok "Created (DNS Write + Zone Read on zone $ZONE_ID, expires $EXPIRES)"

# --- store in GitHub -------------------------------------------------------
step "Saving to GitHub"
ENV_ARGS=()
[[ -n "${GH_ENV:-}" ]] && ENV_ARGS=(--env "$GH_ENV")
gh secret set TF_CLOUDFLARE_API_TOKEN --repo "$REPO" "${ENV_ARGS[@]}" <<<"$TOKEN" >/dev/null
unset TOKEN
ok "TF_CLOUDFLARE_API_TOKEN updated in $REPO${GH_ENV:+ (environment: $GH_ENV)}"

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command Set-Clipboard -Value "' '" >/dev/null 2>&1 \
    && ok "Clipboard cleared"
fi

cat <<EOF

Done. Next steps:
  - Delete the "bootstrap" token at ${TOKENS_URL} (or let it expire).
  - Re-run the Terraform plan, e.g. push a commit to the PR or:
      gh run rerun \$(gh run list --repo $REPO --workflow plan.yml --limit 1 --json databaseId -q '.[0].databaseId')
  - The new token expires $EXPIRES; run this script again before then.
EOF
