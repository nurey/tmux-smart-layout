#!/usr/bin/env zsh
CURRENT_DIR="${0:A:h}"

default_key="L"
key="$(tmux show-option -gqv @smart-layout-key)"
key="${key:-$default_key}"

tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/smart_layout.sh"
