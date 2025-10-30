#!/usr/bin/env bash
set -euo pipefail

LABEL_KEY="generate-custom-resources"
LABEL_VAL="true"

log() { printf "%s %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*" >&2; }

# Find all ExternalSecrets with the label across all namespaces.
# For each item, print: namespace;name;targetSecretName
mapfile -t ES_LIST < <(
  oc get externalsecret -A -l "${LABEL_KEY}=${LABEL_VAL}" \
    -o jsonpath='{range .items[*]}{.metadata.namespace}{";"}{.metadata.name}{";"}{.spec.target.name}{"\n"}{end}' \
    || true
)

if [[ ${#ES_LIST[@]} -eq 0 ]]; then
  log "No ExternalSecrets found with label ${LABEL_KEY}=${LABEL_VAL}. Exiting."
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for line in "${ES_LIST[@]}"; do
  [[ -z "$line" ]] && continue
  IFS=";" read -r ns esName targetName <<<"$line"
  secretName="${targetName:-$esName}"

  # Ensure the rendered Secret exists
  if ! oc get secret -n "$ns" "$secretName" >/dev/null 2>&1; then
    log "Rendered Secret not found yet for ${ns}/${esName} (expected: ${secretName}); skipping."
    continue
  fi

  # Enumerate data keys in the Secret (yaml fragments)
  mapfile -t KEYS < <(
    oc get secret -n "$ns" "$secretName" \
      -o go-template='{{range $k,$v := .data}}{{printf "%s\n" $k}}{{end}}'
  )

  if [[ ${#KEYS[@]} -eq 0 ]]; then
    log "Secret ${ns}/${secretName} has no data keys; skipping."
    continue
  fi

  for key in "${KEYS[@]}"; do
    # Only process *.yaml or *.yml keys
    if [[ ! "$key" =~ \.ya?ml$ ]]; then
      log "Skipping ${ns}/${secretName} key ${key} (not *.yaml|*.yml)."
      continue
    fi

    outfile="${tmpdir}/${ns}-${secretName}-${key//\//_}"
    # Extract, decode, and write the manifest to a temp file
    oc get secret -n "$ns" "$secretName" -o go-template="{{ index .data \"${key}\" }}" \
      | base64 -d > "${outfile}"

    # log "Manifest=$(cat "${outfile}")"
    # Apply the manifest; if it fails, log and continue
    if oc apply -f "${outfile}"; then
      log "Applied ${ns}/${secretName}:${key}"
    else
      log "ERROR applying ${ns}/${secretName}:${key}"
    fi
  done
done

log "Done."
