#!/usr/bin/env bash
# Main orchestrator for tmux-smart-layout.
# Lists all panes, classifies them, picks a layout strategy, and rearranges.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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
declare -A pane_categories
has_editor=false
has_primary=false

for pid in "${pane_ids[@]}"; do
  category="$("$CURRENT_DIR/classify_pane.sh" "$pid")"
  pane_categories["$pid"]="$category"

  if [[ "$category" == "editor" ]]; then
    has_editor=true
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
if $has_editor; then
  # Strategy 1: Main + sidebar
  # Editor is first in sorted list (priority 1), rest follow
  layout_main_sidebar "${sorted_panes[@]}"
elif $has_primary; then
  # Strategy 2: Top + bottom
  # Primary pane (repl/tests/build) is first, rest follow
  layout_top_bottom "${sorted_panes[@]}"
else
  # Strategy 3: Even tiled
  layout_even
fi
