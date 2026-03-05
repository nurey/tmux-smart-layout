# Mock tmux setup for bats tests.
# Tests set these env vars to control mock output:
#   MOCK_PANE_COMMAND  — pane_current_command value
#   MOCK_PANE_TITLE    — pane_title value
#   MOCK_PANE_CONTENT  — capture-pane output
#   MOCK_PANE_LIST     — list-panes output (newline-separated pane IDs)
#   MOCK_WINDOW_WIDTH  — window width (default: 200)
#   MOCK_WINDOW_HEIGHT — window height (default: 50)

# Create a mock tmux binary and prepend it to PATH
MOCK_BIN="$BATS_TEST_TMPDIR/mock_bin"
mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/tmux" << 'EOF'
#!/usr/bin/env zsh
case "$1" in
  display-message)
    case "$*" in
      *pane_current_command*) echo "$MOCK_PANE_COMMAND" ;;
      *pane_title*)           echo "$MOCK_PANE_TITLE" ;;
      *window_width*)         echo "${MOCK_WINDOW_WIDTH:-200}" ;;
      *window_height*)        echo "${MOCK_WINDOW_HEIGHT:-50}" ;;
    esac
    ;;
  capture-pane)
    echo "$MOCK_PANE_CONTENT"
    ;;
  list-panes)
    echo "$MOCK_PANE_LIST"
    ;;
  show-option)
    echo ""
    ;;
  swap-pane|select-layout|resize-pane|bind-key)
    echo "TMUX_CALL: $*" >&2
    ;;
esac
EOF
chmod +x "$MOCK_BIN/tmux"

export PATH="$MOCK_BIN:$PATH"
