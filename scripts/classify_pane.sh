#!/usr/bin/env zsh
# Classifies a single tmux pane by type using a two-pass heuristic.
# Usage: classify_pane.sh <pane_id>
# Output: category string (editor, repl, logs, monitor, docs, tests, build, git, shell)

pane_id="$1"
if [[ -z "$pane_id" ]]; then
  echo "shell"
  exit 0
fi

# Pass 1 — Process name
cmd="$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')"
cmd_lower="${cmd:l}"

case "$cmd_lower" in
  vim|nvim|vi|emacs|nano|hx|code)
    echo "editor"
    exit 0
    ;;
  irb|pry|ghci|iex|lua|claude)
    echo "repl"
    exit 0
    ;;
  tail|less|more|journalctl|multitail|puma|webpack)
    echo "logs"
    exit 0
    ;;
  htop|top|btop|glances|nmon|ngrok)
    echo "monitor"
    exit 0
    ;;
  man|info)
    echo "docs"
    exit 0
    ;;
  zsh|bash|fish|sh|ruby|python|python3|node)
    # Fall through to pass 2
    ;;
  *)
    echo "shell"
    exit 0
    ;;
esac

# Pass 2 — Content heuristics (only reached for shell processes)
content="$(tmux capture-pane -t "$pane_id" -p 2>/dev/null)"

if echo "$content" | grep -qE '(irb\(main\)|pry\(main\)|rails console|>>> |> \.\.\.|In \[[0-9]+\]:)'; then
  echo "repl"
elif echo "$content" | grep -qE '(INFO|WARN|ERROR|DEBUG)' && echo "$content" | grep -qE '[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  echo "logs"
elif echo "$content" | grep -qE '(PASS|FAIL|examples?|assertions?|✓|✗|passed|failed|[0-9]+ tests?)'; then
  echo "tests"
elif echo "$content" | grep -qE '(error:|warning:|Compiling|Building|COMPILE|webpack|vite|esbuild)'; then
  echo "build"
elif echo "$content" | grep -qE '(^commit [0-9a-f]{7,}|diff --git|\+\+\+|---)'; then
  echo "git"
else
  echo "shell"
fi
