#!/usr/bin/env bash
set -euo pipefail

# Only folders that contain .tf files count as stacks.
all=()
for dir in "$STACKS_DIR"/*/; do
  [ -d "$dir" ] || continue
  if compgen -G "${dir}*.tf" >/dev/null; then all+=("$(basename "$dir")"); fi
done

selected=()
if [ "$EVENT" = "workflow_dispatch" ] || [ -z "$BASE_SHA" ] \
   || ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "No usable base commit (or manual run): selecting all stacks."
  selected=("${all[@]+"${all[@]}"}")
else
  changed=$(git diff --name-only "${BASE_SHA}...${HEAD_SHA}")
  echo "Changed files:"; echo "$changed"

  run_all=false
  while IFS= read -r path; do
    [ -n "$path" ] && grep -qxF "$path" <<<"$changed" && run_all=true
  done <<<"$RUN_ALL_PATHS"

  if [ "$run_all" = true ]; then
    echo "A run-all path changed: selecting all stacks."
    selected=("${all[@]+"${all[@]}"}")
  else
    for s in "${all[@]+"${all[@]}"}"; do
      while IFS= read -r f; do
        case "$f" in
          "$STACKS_DIR/$s/"* | "$ENV_DIR/$s.tfvars") selected+=("$s"); break ;;
        esac
      done <<<"$changed"
    done
  fi
fi

json=$(printf '%s\n' "${selected[@]+"${selected[@]}"}" | jq -Rsc 'split("\n") | map(select(length > 0))')
echo "Stacks: $json"
echo "stacks=$json" >> "$GITHUB_OUTPUT"
