#!/usr/bin/env zsh
# Classifies a single tmux pane by type using a three-pass heuristic.
# Usage: classify_pane.sh <pane_id>
# Output: category string (editor, repl, logs, monitor, docs, tests, build, git, shell)

pane_id="$1"
if [[ -z "$pane_id" ]]; then
  echo "shell"
  exit 0
fi

# Read pane metadata
cmd="$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')"
cmd_lower="${cmd:l}"
pane_title="$(tmux display-message -p -t "$pane_id" '#{pane_title}')"

# Pass 1 — Process name (known processes are classified immediately)
case "$cmd_lower" in
  vim|nvim|vi|emacs|nano|hx|code)
    echo "editor"
    exit 0
    ;;
  irb|pry|ghci|iex|lua)
    echo "repl"
    exit 0
    ;;
  tail|less|more|journalctl|multitail|puma)
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
esac

# Pass 2 — Pane title (for unrecognized process names like Claude's version string)
if [[ "$pane_title" == ✳* ]]; then
  echo "editor"
  exit 0
fi

# Pass 3 — Content heuristics (reached for unrecognized processes without a known title)
content="$(tmux capture-pane -t "$pane_id" -p -S -20 2>/dev/null)"

if echo "$content" | grep -qE '(irb\(main\)|pry\(main\)|rails console|>>> |> \.\.\.|In \[[0-9]+\]:)'; then
  echo "repl"
elif echo "$content" | grep -qE '(INFO|WARN|ERROR|DEBUG)' && echo "$content" | grep -qE '[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  echo "logs"
elif echo "$content" | grep -qE 'webpack.*compiled.*(successfully|with|in [0-9]+ ms)'; then
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
