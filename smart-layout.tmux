#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

default_key="L"
key="$(tmux show-option -gqv @smart-layout-key)"
key="${key:-$default_key}"

tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/smart_layout.sh"
