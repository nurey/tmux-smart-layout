#!/usr/bin/env zsh
# Main orchestrator for tmux-smart-layout.
# Lists all panes, classifies them, picks a layout strategy, and rearranges.

CURRENT_DIR="${0:A:h}"
source "$CURRENT_DIR/layouts.sh"

# Priority ranking (lower number = higher priority = gets more space)
priority_of() {
  case "$1" in
    editor)  echo 1 ;;
    repl)    echo 2 ;;
    tests)   echo 2 ;;
    build)   echo 2 ;;
    logs)    echo 3 ;;
    monitor) echo 3 ;;
    git)     echo 3 ;;
    docs)    echo 4 ;;
    shell)   echo 4 ;;
    *)       echo 5 ;;
  esac
}

# Collect pane IDs
pane_ids=($(tmux list-panes -F '#{pane_id}'))

# Single pane — nothing to do
if [[ ${#pane_ids[@]} -le 1 ]]; then
  exit 0
fi

# Classify each pane
typeset -A pane_categories
editor_count=0
has_primary=false

for pid in "${pane_ids[@]}"; do
  category="$("$CURRENT_DIR/classify_pane.sh" "$pid")"
  pane_categories[$pid]="$category"

  if [[ "$category" == "editor" ]]; then
    (( editor_count++ ))
  elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then
    has_primary=true
  fi
done

# Sort panes by priority (stable: preserves original order for equal priority)
sorted_panes=()
for p in 1 2 3 4 5; do
  for pid in "${pane_ids[@]}"; do
    if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
      sorted_panes+=("$pid")
    fi
  done
done

# Choose and apply layout strategy
if (( editor_count > 1 )); then
  layout_grid "$editor_count" "${sorted_panes[@]}"
elif (( editor_count == 1 )); then
  layout_main_sidebar "${sorted_panes[@]}"
elif $has_primary; then
  layout_top_bottom "${sorted_panes[@]}"
else
  layout_even
fi
