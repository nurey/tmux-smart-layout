#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/tmux_mock.bash"
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/classify_pane.sh"
  export MOCK_PANE_TITLE=""
  export MOCK_PANE_CONTENT=""
  export MOCK_PANE_COMMAND=""
}

# --- Empty input ---

@test "empty pane ID returns shell" {
  run zsh "$SCRIPT" ""
  [ "$output" = "shell" ]
}

# --- Pass 1: Process name ---

@test "vim is editor" {
  export MOCK_PANE_COMMAND="vim"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "nvim is editor" {
  export MOCK_PANE_COMMAND="nvim"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "emacs is editor" {
  export MOCK_PANE_COMMAND="emacs"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "nano is editor" {
  export MOCK_PANE_COMMAND="nano"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "hx is editor" {
  export MOCK_PANE_COMMAND="hx"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "code is editor" {
  export MOCK_PANE_COMMAND="code"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "irb is repl" {
  export MOCK_PANE_COMMAND="irb"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "pry is repl" {
  export MOCK_PANE_COMMAND="pry"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "node is not immediately classified" {
  export MOCK_PANE_COMMAND="node"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}

@test "python is not immediately classified" {
  export MOCK_PANE_COMMAND="python"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}

@test "tail is logs" {
  export MOCK_PANE_COMMAND="tail"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "logs" ]
}

@test "puma is logs" {
  export MOCK_PANE_COMMAND="puma"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "logs" ]
}

@test "htop is monitor" {
  export MOCK_PANE_COMMAND="htop"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "monitor" ]
}

@test "ngrok is monitor" {
  export MOCK_PANE_COMMAND="ngrok"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "monitor" ]
}

@test "man is docs" {
  export MOCK_PANE_COMMAND="man"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "docs" ]
}

# --- Pass 1: Case insensitivity ---

@test "VIM (uppercase) is editor" {
  export MOCK_PANE_COMMAND="VIM"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "Python (capitalized) falls through to content heuristics" {
  export MOCK_PANE_COMMAND="Python"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}

# --- Pass 2: Pane title ---

@test "pane title with star prefix is editor" {
  export MOCK_PANE_COMMAND="2.1.68"
  export MOCK_PANE_TITLE="✳ Claude Code"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "pane title with star and task name is editor" {
  export MOCK_PANE_COMMAND="2.1.63"
  export MOCK_PANE_TITLE="✳ Fix login bug"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "ruby process with star title is NOT editor (pass 1 wins)" {
  export MOCK_PANE_COMMAND="ruby"
  export MOCK_PANE_TITLE="✳ Claude Code"
  export MOCK_PANE_CONTENT="irb(main):001:0>"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "vim process with star title is still editor" {
  export MOCK_PANE_COMMAND="vim"
  export MOCK_PANE_TITLE="✳ Claude Code"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "editor" ]
}

@test "empty pane title does not match" {
  export MOCK_PANE_COMMAND="some-unknown"
  export MOCK_PANE_TITLE=""
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}

# --- Pass 3: Content heuristics - REPL ---

@test "irb prompt detected as repl" {
  export MOCK_PANE_COMMAND="ruby"
  export MOCK_PANE_CONTENT="irb(main):001:0> puts 'hello'"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "pry prompt detected as repl" {
  export MOCK_PANE_COMMAND="ruby"
  export MOCK_PANE_CONTENT="[1] pry(main)> User.first"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "python interactive prompt detected as repl" {
  export MOCK_PANE_COMMAND="python3"
  export MOCK_PANE_CONTENT=">>> import os"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

@test "ipython prompt detected as repl" {
  export MOCK_PANE_COMMAND="python3"
  export MOCK_PANE_CONTENT="In [1]: import pandas"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "repl" ]
}

# --- Pass 3: Content heuristics - Logs ---

@test "timestamped log levels detected as logs" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="2024-01-01 12:00:00 INFO Starting server
12:00:01 DEBUG Connection established"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "logs" ]
}

@test "webpack compiled output detected as logs" {
  export MOCK_PANE_COMMAND="node"
  export MOCK_PANE_CONTENT="webpack 5.104.1 compiled successfully in 853 ms"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "logs" ]
}

@test "webpack compiled with warnings detected as logs" {
  export MOCK_PANE_COMMAND="node"
  export MOCK_PANE_CONTENT="webpack 5.104.1 compiled with 2 warnings in 1200 ms"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "logs" ]
}

# --- Pass 3: Content heuristics - Tests ---

@test "test PASS/FAIL output detected as tests" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="12 examples, 0 failures
PASS: all tests passed"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "tests" ]
}

@test "checkmark test output detected as tests" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="  ✓ should return 200
  ✗ should handle errors"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "tests" ]
}

# --- Pass 3: Content heuristics - Build ---

@test "compiler error output detected as build" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="src/main.rs:10:5: error: expected ';'"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "build" ]
}

@test "Compiling output detected as build" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="Compiling myproject v0.1.0"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "build" ]
}

# --- Pass 3: Content heuristics - Git ---

@test "git diff output detected as git" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="diff --git a/file.txt b/file.txt
--- a/file.txt
+++ b/file.txt"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "git" ]
}

@test "git log output detected as git" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="commit abc1234def5678
Author: Test User"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "git" ]
}

# --- Pass 3: Fallback ---

@test "plain shell prompt falls back to shell" {
  export MOCK_PANE_COMMAND="zsh"
  export MOCK_PANE_CONTENT="~ $ ls
file1.txt  file2.txt"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}

@test "unknown process with no content falls back to shell" {
  export MOCK_PANE_COMMAND="some-random-tool"
  run zsh "$SCRIPT" "%1"
  [ "$output" = "shell" ]
}
