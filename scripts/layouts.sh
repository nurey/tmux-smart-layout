#!/usr/bin/env bash
# Layout strategy functions for tmux-smart-layout.
# Each function receives ordered pane IDs as arguments and rearranges the current window.

get_option() {
  local option="$1"
  local default="$2"
  local val
  val="$(tmux show-option -gqv "$option")"
  echo "${val:-$default}"
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

  # Break all panes into the window first, then rejoin in order.
  # Move editor pane to be the first (top-left) pane.
  local first_pane
  first_pane="$(tmux list-panes -F '#{pane_id}' | head -1)"

  if [[ "$editor_pane" != "$first_pane" ]]; then
    tmux swap-pane -s "$editor_pane" -t "$first_pane"
    # After swap, the editor is now at first_pane's position, and the ID follows the content.
    # So editor_pane still refers to the editor content, which is now in first position.
    # But swap-pane swaps by position, so we need to track by position.
    # Let's use a simpler approach: set up main-vertical then swap into position.
  fi

  # Apply main-vertical base layout (first pane gets the left column).
  tmux select-layout main-vertical

  # Reorder the right-side panes by priority (they're already passed in priority order).
  # After main-vertical, panes are: first (left), then the rest stacked vertically on right.
  local current_panes
  current_panes=($(tmux list-panes -F '#{pane_id}'))
  local right_panes=("${current_panes[@]:1}")

  # Swap right-side panes into priority order
  for i in "${!other_panes[@]}"; do
    if [[ $i -lt ${#right_panes[@]} ]] && [[ "${other_panes[$i]}" != "${right_panes[$i]}" ]]; then
      # Find where the desired pane currently is
      for j in "${!right_panes[@]}"; do
        if [[ "${right_panes[$j]}" == "${other_panes[$i]}" ]]; then
          tmux swap-pane -s "${right_panes[$j]}" -t "${right_panes[$i]}"
          # Update tracking array
          local tmp="${right_panes[$i]}"
          right_panes[$i]="${right_panes[$j]}"
          right_panes[$j]="$tmp"
          break
        fi
      done
    fi
  done

  # Resize editor pane
  local final_first
  final_first="$(tmux list-panes -F '#{pane_id}' | head -1)"
  tmux resize-pane -t "$final_first" -x "$editor_width"
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

  # Ensure primary pane is first
  local first_pane
  first_pane="$(tmux list-panes -F '#{pane_id}' | head -1)"

  if [[ "$primary_pane" != "$first_pane" ]]; then
    tmux swap-pane -s "$primary_pane" -t "$first_pane"
  fi

  # Apply main-horizontal base layout (first pane on top, rest below side-by-side).
  tmux select-layout main-horizontal

  # Reorder bottom panes by priority
  local current_panes
  current_panes=($(tmux list-panes -F '#{pane_id}'))
  local bottom_panes=("${current_panes[@]:1}")

  for i in "${!other_panes[@]}"; do
    if [[ $i -lt ${#bottom_panes[@]} ]] && [[ "${other_panes[$i]}" != "${bottom_panes[$i]}" ]]; then
      for j in "${!bottom_panes[@]}"; do
        if [[ "${bottom_panes[$j]}" == "${other_panes[$i]}" ]]; then
          tmux swap-pane -s "${bottom_panes[$j]}" -t "${bottom_panes[$i]}"
          local tmp="${bottom_panes[$i]}"
          bottom_panes[$i]="${bottom_panes[$j]}"
          bottom_panes[$j]="$tmp"
          break
        fi
      done
    fi
  done

  # Resize primary pane
  local final_first
  final_first="$(tmux list-panes -F '#{pane_id}' | head -1)"
  tmux resize-pane -t "$final_first" -y "$primary_height"
}

# Strategy 3: Even tiled layout (fallback).
layout_even() {
  tmux select-layout tiled
}
