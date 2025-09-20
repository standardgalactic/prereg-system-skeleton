#!/bin/bash
set -euo pipefail

###############################################################################
# prereg.sh - Simplified preregistration system (HTTPS version)
#
# Usage:
#   prereg.sh new
#   prereg.sh verify [--strict]
#
# Description:
#   Creates or updates preregistration repositories, updates a central ledger,
#   and ensures claim-index.md stays consistent with the CLAIMS list.
###############################################################################

# Configuration
readonly LEDGER_FILE="LEDGER.md"
readonly CLAIM_INDEX="claim-index.md"
readonly USERNAME="standardgalactic"

# Claims list (repo => description)
declare -A CLAIMS=(
  ["entropic-redshift"]="Redshift as entropy descent in RSVP"
  ["connector-loss"]="Connector as entropy-respecting projection"
  ["unistochastic-rsvp"]="Unistochastic quantum theory as emergent RSVP"
  ["geometry-shear"]="Connector as entropic shear on semantic manifolds"
  ["patch-negentropy"]="Negentropic corridors preserve local injectivity"
  ["lyapunov-stability"]="RSVP stability via Lyapunov control"
  ["entropy-budget"]="Rate–distortion as RSVP entropy budget"
  ["corridor-routing"]="Task-aware negentropic corridor routing"
  ["sheaf-gluing"]="Connector factoring as sheaf-consistent gluing"
  ["conditional-knor"]="Context-conditioned KNOR predicts VQA errors"
  ["corridor-ablation"]="Connector ablation validates negentropic routing"
  ["geometry-hysteresis"]="Geometry–performance hysteresis in RSVP connectors"
  ["dual-use-entropy"]="Entropy production as dual-use capability metric"
  ["human-projectors"]="Humans as lossy entropy-respecting projectors"
  ["functorial-mapping"]="Connector functor as non-faithful entropy projector"
  ["rate-distortion"]="Patch MSE as RSVP entropy budget consumption"
  ["negentropic-corridors"]="Restricted isometry as negentropic channels"
  ["conditional-knor"]="Text-conditioned KNOR improves QA accuracy"
  ["procrustes-failure"]="Irreversible entropy production at connectors"
  ["sheaf-consistency"]="Local reconstructions glue via sheaf maps"
)

###############################################################################
# Helpers
###############################################################################

log() { echo "[$1] ${*:2}"; }

usage() {
  echo "Usage: $0 {new|verify} [--strict]"
  exit 1
}

init_ledger() {
  if [ ! -f "$LEDGER_FILE" ]; then
    cat > "$LEDGER_FILE" <<EOF
| Repo | Version | Timestamp | Claim |
|------|---------|-----------|-------|
EOF
  fi
}

init_claim_index() {
  log INFO "Rebuilding $CLAIM_INDEX"
  cat > "$CLAIM_INDEX" <<EOF
| Repo | Description |
|------|-------------|
EOF
  for repo in "${!CLAIMS[@]}"; do
    echo "| $repo | ${CLAIMS[$repo]} |" >> "$CLAIM_INDEX"
  done
}

###############################################################################
# Repo functions
###############################################################################

create_or_update_repo() {
  local repo=$1
  local claim=${CLAIMS[$repo]}
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ ! -d "$repo" ]; then
    log INFO "Cloning $repo..."
    if ! gh repo view "$USERNAME/$repo" &>/dev/null; then
      gh repo create "$USERNAME/$repo" --public --confirm
    fi
    git clone "https://github.com/$USERNAME/$repo.git"
  fi

  pushd "$repo" >/dev/null

  if [ ! -f README.md ]; then
    echo "# $repo" > README.md
    echo "$claim" >> README.md
  fi

  version=$(grep "^\| $repo " "../$LEDGER_FILE" | wc -l)
  version=$((version + 1))
  echo "| $repo | $version | $ts | $claim |" >> "../$LEDGER_FILE"

  git add README.md
  git commit -m "Preregistration claim v$version: $claim" || true
  git push origin main || true

  popd >/dev/null
}

verify_claim_index() {
  local strict=$1
  if [ ! -f "$CLAIM_INDEX" ]; then
    if [ "$strict" == "true" ]; then
      log ERROR "$CLAIM_INDEX missing (strict mode)"
      exit 1
    else
      log WARN "$CLAIM_INDEX missing – regenerating..."
      init_claim_index
      git add "$CLAIM_INDEX"
      git commit -m "Regenerate claim index" || true
      git push origin main || true
      exit 1
    fi
  fi

  while IFS="|" read -r _ repo desc _; do
    [[ "$repo" == " Repo " || "$repo" == "------" ]] && continue
    repo=$(echo "$repo" | xargs)
    desc=$(echo "$desc" | xargs)
    expected="${CLAIMS[$repo]:-}"
    if [ "$desc" != "$expected" ]; then
      if [ "$strict" == "true" ]; then
        log ERROR "Mismatch for $repo (strict mode)"
        exit 1
      else
        log WARN "Mismatch for $repo – repairing..."
        init_claim_index
        git add "$CLAIM_INDEX"
        git commit -m "Repair claim index" || true
        git push origin main || true
        exit 1
      fi
    fi
  done < "$CLAIM_INDEX"
}

###############################################################################
# Main
###############################################################################

mode=${1:-}
shift || true
strict="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict="true" ;;
    *) usage ;;
  esac
  shift
done

init_ledger

case "$mode" in
  new)
    for repo in "${!CLAIMS[@]}"; do
      create_or_update_repo "$repo"
    done
    init_claim_index
    git add "$CLAIM_INDEX" "$LEDGER_FILE"
    git commit -m "Update ledger and claim index" || true
    git push origin main || true
    ;;
  verify)
    verify_claim_index "$strict"
    log INFO "Verification passed"
    ;;
  *)
    usage
    ;;
esac
