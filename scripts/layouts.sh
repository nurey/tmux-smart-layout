#!/usr/bin/env zsh
# Layout strategy functions for tmux-smart-layout.
# Each function receives ordered pane IDs as arguments and rearranges the current window.

get_option() {
  local option="$1"
  local default="$2"
  local val
  val="$(tmux show-option -gqv "$option")"
  echo "${val:-$default}"
}

# Reorder secondary panes to match the desired priority order.
# Args: desired_pane1 desired_pane2 ...
# Reads current pane list from tmux, skips the first (primary) pane.
reorder_secondary_panes() {
  local desired=("$@")
  local current
  current=($(tmux list-panes -F '#{pane_id}'))
  local secondary=("${current[@]:2}") # zsh arrays are 1-indexed; skip primary

  for (( i = 1; i <= $#desired; i++ )); do
    if (( i <= $#secondary )) && [[ "${desired[$i]}" != "${secondary[$i]}" ]]; then
      for (( j = i; j <= $#secondary; j++ )); do
        if [[ "${secondary[$j]}" == "${desired[$i]}" ]]; then
          tmux swap-pane -s "${secondary[$j]}" -t "${secondary[$i]}"
          local tmp="${secondary[$i]}"
          secondary[$i]="${secondary[$j]}"
          secondary[$j]="$tmp"
          break
        fi
      done
    fi
  done
}

# Move a pane to the first position if it isn't already there.
ensure_primary_pane() {
  local target="$1"
  local first
  first="$(tmux list-panes -F '#{pane_id}' | head -1)"
  if [[ "$target" != "$first" ]]; then
    tmux swap-pane -s "$target" -t "$first"
  fi
}

# Strategy 1: Main editor on the left (~65%), remaining panes stacked on the right.
# Args: editor_pane other_pane1 other_pane2 ...
layout_main_sidebar() {
  local editor_pane="$1"
  shift
  local other_panes=("$@")
  local editor_size
  editor_size="$(get_option @smart-layout-editor-size 65)"

  local window_width
  window_width="$(tmux display-message -p '#{window_width}')"
  local editor_width=$(( window_width * editor_size / 100 ))

  ensure_primary_pane "$editor_pane"
  tmux select-layout main-vertical
  reorder_secondary_panes "${other_panes[@]}"
  tmux resize-pane -t "$(tmux list-panes -F '#{pane_id}' | head -1)" -x "$editor_width"
}

# Strategy 2: Primary pane on top (~60%), remaining panes split horizontally below.
# Args: primary_pane other_pane1 other_pane2 ...
layout_top_bottom() {
  local primary_pane="$1"
  shift
  local other_panes=("$@")
  local primary_size
  primary_size="$(get_option @smart-layout-primary-size 60)"

  local window_height
  window_height="$(tmux display-message -p '#{window_height}')"
  local primary_height=$(( window_height * primary_size / 100 ))

  ensure_primary_pane "$primary_pane"
  tmux select-layout main-horizontal
  reorder_secondary_panes "${other_panes[@]}"
  tmux resize-pane -t "$(tmux list-panes -F '#{pane_id}' | head -1)" -y "$primary_height"
}

# Strategy 3: Even tiled layout (fallback).
layout_even() {
  tmux select-layout tiled
}
