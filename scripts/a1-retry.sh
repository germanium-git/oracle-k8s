#!/usr/bin/env bash
# Keep trying to launch an Always Free Ampere A1 VM (VM.Standard.A1.Flex)
# until OCI has capacity. Rotates through all availability domains in the
# region, backs off on throttling, and stops at the first success.
#
# Usage:
#   ./scripts/a1-retry.sh                    # 2 OCPU / 12 GB, name "control1"
#   NAME=saturn OCPUS=4 MEMORY_GB=24 ./scripts/a1-retry.sh
#
# Keep it running after you close the terminal:
#   nohup ./scripts/a1-retry.sh --yes > a1-retry.log 2>&1 &
#
# Options (environment variables):
#   NAME        display name of the VM                  (default control1)
#   OCPUS       OCPUs                                   (default 2)
#   MEMORY_GB   memory in GB                            (default 12)
#   BOOT_GB     boot volume in GB, min 47               (default 50)
#   INTERVAL    seconds between rounds over all ADs     (default 60)
#   PROFILE     profile in ~/.oci/config                (default DEFAULT)
#   REGION      region; must be the tenancy home region (default eu-frankfurt-1)
#   SSH_KEY     public key file  (default terraform/sshkey/..._putty.pub)
#   VCN_NAME / SUBNET_NAME / NSG_NAME   network created by Terraform
#
# The instance is created outside Terraform. Once it exists, add it to
# terraform/main.tf and import it (see the hint printed at the end).
set -euo pipefail

cd "$(dirname "$0")/.."

NAME="${NAME:-control1}"
OCPUS="${OCPUS:-2}"
MEMORY_GB="${MEMORY_GB:-12}"
BOOT_GB="${BOOT_GB:-50}"
INTERVAL="${INTERVAL:-60}"
PROFILE="${PROFILE:-DEFAULT}"
REGION="${REGION:-eu-frankfurt-1}"
SSH_KEY="${SSH_KEY:-terraform/sshkey/petr.nemec@gmx.com_2023-05-21T20_18_59.854Z_putty.pub}"
VCN_NAME="${VCN_NAME:-vcn_01}"
SUBNET_NAME="${SUBNET_NAME:-subnet1}"
NSG_NAME="${NSG_NAME:-vcn_01-nsg}"
SHAPE=VM.Standard.A1.Flex
ASSUME_YES=false
[[ "${1:-}" == "--yes" ]] && ASSUME_YES=true

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '    \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
ts()   { date '+%Y-%m-%d %H:%M:%S'; }

ocic() { oci --profile "$PROFILE" --region "$REGION" "$@"; }

# --- prerequisites -------------------------------------------------------------
step "Checking prerequisites"
if ! oci --version >/dev/null 2>&1; then
  die "OCI CLI not found or not working in this shell. Install it in WSL:
        bash -c \"\$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)\"
      then configure it (creates ~/.oci/config and an API key):
        oci setup config
      and upload the printed public key in the console:
        My Profile -> Tokens and keys -> API keys -> Add API key"
fi
command -v jq >/dev/null || die "Missing 'jq'. Install it and run again."
[[ -f ~/.oci/config ]] || die "No ~/.oci/config. Run: oci setup config"
[[ -f "$SSH_KEY" ]] || die "SSH public key not found: $SSH_KEY"
(( BOOT_GB >= 47 )) || die "BOOT_GB must be at least 47"

TENANCY=$(awk -v p="[$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^tenancy *=/{sub(/^tenancy *= */,"");print;exit}' ~/.oci/config)
[[ -n "$TENANCY" ]] || die "No tenancy= in profile [$PROFILE] of ~/.oci/config"
ocic iam region-subscription list --tenancy-id "$TENANCY" >/dev/null 2>&1 \
  || die "OCI CLI can't authenticate (profile $PROFILE). Check ~/.oci/config and the API key."
HOME_REGION=$(ocic iam region-subscription list --tenancy-id "$TENANCY" \
  --query 'data[?"is-home-region"]|[0]."region-name"' --raw-output)
[[ "$HOME_REGION" == "$REGION" ]] \
  || die "$REGION is not the home region ($HOME_REGION). Always Free A1 only works there; set REGION=$HOME_REGION."
ok "OCI CLI works, home region is $HOME_REGION"

# --- look up everything the launch needs -------------------------------------
step "Looking up network, image and availability domains"
VCN_ID=$(ocic network vcn list --compartment-id "$TENANCY" --display-name "$VCN_NAME" \
  --query 'data[0].id' --raw-output)
[[ -n "$VCN_ID" && "$VCN_ID" != "null" ]] || die "VCN '$VCN_NAME' not found"
SUBNET_ID=$(ocic network subnet list --compartment-id "$TENANCY" --vcn-id "$VCN_ID" \
  --display-name "$SUBNET_NAME" --query 'data[0].id' --raw-output)
[[ -n "$SUBNET_ID" && "$SUBNET_ID" != "null" ]] || die "Subnet '$SUBNET_NAME' not found"
NSG_ID=$(ocic network nsg list --compartment-id "$TENANCY" --vcn-id "$VCN_ID" \
  --display-name "$NSG_NAME" --query 'data[0].id' --raw-output)
[[ -n "$NSG_ID" && "$NSG_ID" != "null" ]] || die "NSG '$NSG_NAME' not found"
ok "Network: $VCN_NAME / $SUBNET_NAME / $NSG_NAME"

IMAGE_JSON=$(ocic compute image list --compartment-id "$TENANCY" \
  --operating-system "Canonical Ubuntu" --operating-system-version "24.04" \
  --shape "$SHAPE" --sort-by TIMECREATED --sort-order DESC --limit 1)
IMAGE_ID=$(jq -r '.data[0].id // empty' <<<"$IMAGE_JSON")
[[ -n "$IMAGE_ID" ]] || die "No Ubuntu 24.04 image found for $SHAPE"
ok "Image: $(jq -r '.data[0]."display-name"' <<<"$IMAGE_JSON")"

mapfile -t ADS < <(ocic iam availability-domain list --compartment-id "$TENANCY" \
  --query 'data[].name' | jq -r '.[]')
(( ${#ADS[@]} > 0 )) || die "No availability domains found"
ok "Availability domains: ${#ADS[@]}"

existing() {
  ocic compute instance list --compartment-id "$TENANCY" --display-name "$NAME" --all \
    --query 'data[?"lifecycle-state"!=`TERMINATED` && "lifecycle-state"!=`TERMINATING`]' 2>/dev/null \
    | jq -r '.[0] // empty | "\(.id) \(."lifecycle-state")"'
}
[[ -z "$(existing)" ]] || die "An instance named '$NAME' already exists: $(existing)"

# --- confirm -----------------------------------------------------------------
step "Plan"
cat <<EOF
    VM:      $NAME  ($SHAPE, $OCPUS OCPU, $MEMORY_GB GB RAM, ${BOOT_GB} GB boot)
    Image:   Ubuntu 24.04 (aarch64)
    Network: public IP, $SUBNET_NAME, NSG $NSG_NAME
    Retry:   every ${INTERVAL}s over ${#ADS[@]} ADs until it succeeds (Ctrl+C to stop)
EOF
warn "Always Free block storage is 200 GB in total. uran and neptun already use"
warn "about 200 GB (2x 50 GB boot + 2x 50 GB block volume), so this boot volume"
warn "will probably be billed unless you free storage first."
if ! $ASSUME_YES; then
  read -rp "    Start? [y/N] " answer
  [[ "${answer,,}" == "y" ]] || die "Cancelled"
fi

# --- retry loop --------------------------------------------------------------
step "Trying to launch (started $(ts))"
attempt=0
backoff=0
while true; do
  for AD in "${ADS[@]}"; do
    attempt=$((attempt + 1))
    set +e
    OUT=$(ocic compute instance launch \
      --availability-domain "$AD" \
      --compartment-id "$TENANCY" \
      --shape "$SHAPE" \
      --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORY_GB}" \
      --image-id "$IMAGE_ID" \
      --boot-volume-size-in-gbs "$BOOT_GB" \
      --subnet-id "$SUBNET_ID" \
      --nsg-ids "[\"$NSG_ID\"]" \
      --assign-public-ip true \
      --display-name "$NAME" \
      --ssh-authorized-keys-file "$SSH_KEY" 2>&1)
    rc=$?
    set -e

    if (( rc == 0 )); then
      ID=$(jq -r '.data.id' <<<"$OUT" 2>/dev/null || true)
      printf '\a'
      step "Success after $attempt attempts ($(ts))"
      ok "Instance $NAME launched in $AD"
      ok "OCID: $ID"
      cat <<EOF

    Public IP (once running):
      oci compute instance list-vnics --instance-id $ID --query 'data[0]."public-ip"' --raw-output

    To manage it with Terraform: add "$NAME" to vm_config in terraform/main.tf
    (shape $SHAPE, cpu_count $OCPUS, memory_gb $MEMORY_GB, the same zone index
    as $AD) and import it:
      terraform import 'module.virtual_machine.oci_core_instance.vm["$NAME"]' $ID
EOF
      exit 0
    fi

    short="${AD##*:}"
    if grep -qi "out of host capacity" <<<"$OUT"; then
      echo "$(ts)  #$attempt  $short  out of capacity"
    elif grep -qiE "TooManyRequests|429" <<<"$OUT"; then
      backoff=$(( backoff == 0 ? 60 : (backoff * 2 > 600 ? 600 : backoff * 2) ))
      echo "$(ts)  #$attempt  $short  throttled, waiting extra ${backoff}s"
      sleep "$backoff"
    elif grep -qiE "LimitExceeded|service limit" <<<"$OUT"; then
      echo "$OUT" >&2
      die "Service limit reached: your tenancy's A1 limit is lower than $OCPUS OCPU / $MEMORY_GB GB (or already used). Lower OCPUS/MEMORY_GB."
    elif grep -qiE "InternalError|Timeout|timed out|Connection|ServiceUnavailable|50[0-9]" <<<"$OUT"; then
      echo "$(ts)  #$attempt  $short  transient error, will retry"
      # A launch may have gone through despite the error: don't create a duplicate
      if [[ -n "$(existing)" ]]; then
        step "An instance named '$NAME' now exists: $(existing)"
        exit 0
      fi
    else
      echo "$OUT" >&2
      die "Unexpected error (shown above), stopping."
    fi
  done
  (( backoff > 0 )) && backoff=$(( backoff / 2 ))
  sleep $(( INTERVAL + RANDOM % 15 ))
done
