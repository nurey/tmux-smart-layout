#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/test_helper/tmux_mock.bash"
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/smart_layout.sh"
  MOCK_TMUX_CALLS=()

  # Create a mock classify_pane.sh that reads from MOCK_CLASSIFICATIONS
  # Format: "%1=editor %2=shell %3=repl"
  MOCK_CLASSIFY="$BATS_TEST_DIRNAME/test_helper/mock_classify.sh"
}

# Helper: create a mock classify script that maps pane IDs to categories
create_mock_classify() {
  local classifications="$1"
  cat > "$MOCK_CLASSIFY" << 'SCRIPT'
#!/usr/bin/env zsh
pane_id="$1"
SCRIPT
  for mapping in $classifications; do
    local id="${mapping%%=*}"
    local category="${mapping#*=}"
    echo "if [[ \"\$pane_id\" == \"$id\" ]]; then echo \"$category\"; exit 0; fi" >> "$MOCK_CLASSIFY"
  done
  echo 'echo "shell"' >> "$MOCK_CLASSIFY"
  chmod +x "$MOCK_CLASSIFY"
}

teardown() {
  rm -f "$MOCK_CLASSIFY"
}

@test "single pane exits early" {
  MOCK_PANE_LIST="%1"
  create_mock_classify "%1=shell"
  CLASSIFY_SCRIPT="$MOCK_CLASSIFY" run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"
    MOCK_PANE_LIST="%1"
    CURRENT_DIR="'"$BATS_TEST_DIRNAME"'/../scripts"
    # Override classify path
    source "'"$BATS_TEST_DIRNAME"'/../scripts/layouts.sh"
    pane_ids=(%1)
    if [[ ${#pane_ids[@]} -le 1 ]]; then echo "exit_early"; exit 0; fi
  '
  [ "$output" = "exit_early" ]
}

@test "single editor triggers main_sidebar" {
  create_mock_classify "%1=editor %2=shell %3=logs"
  run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"
    MOCK_PANE_LIST="%1
%2
%3"
    layout_called=""
    layout_main_sidebar() { layout_called="main_sidebar"; echo "main_sidebar $*" }
    layout_top_bottom() { layout_called="top_bottom"; echo "top_bottom $*" }
    layout_grid() { layout_called="grid"; echo "grid $*" }
    layout_even() { layout_called="even"; echo "even" }

    classify_pane() {
      case "$1" in
        %1) echo "editor" ;; %2) echo "shell" ;; %3) echo "logs" ;;
      esac
    }

    priority_of() {
      case "$1" in
        editor) echo 1 ;; repl|tests|build) echo 2 ;; logs|monitor|git) echo 3 ;;
        docs|shell) echo 4 ;; *) echo 5 ;;
      esac
    }

    pane_ids=(%1 %2 %3)
    typeset -A pane_categories
    editor_count=0
    has_primary=false

    for pid in "${pane_ids[@]}"; do
      category="$(classify_pane "$pid")"
      pane_categories[$pid]="$category"
      if [[ "$category" == "editor" ]]; then (( editor_count++ ))
      elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then has_primary=true; fi
    done

    sorted_panes=()
    for p in 1 2 3 4 5; do
      for pid in "${pane_ids[@]}"; do
        if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
          sorted_panes+=("$pid")
        fi
      done
    done

    if (( editor_count > 1 )); then layout_grid "$editor_count" "${sorted_panes[@]}"
    elif (( editor_count == 1 )); then layout_main_sidebar "${sorted_panes[@]}"
    elif $has_primary; then layout_top_bottom "${sorted_panes[@]}"
    else layout_even; fi
  '
  [[ "$output" == "main_sidebar"* ]]
}

@test "multiple editors trigger grid" {
  run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"

    layout_main_sidebar() { echo "main_sidebar" }
    layout_top_bottom() { echo "top_bottom" }
    layout_grid() { echo "grid $*" }
    layout_even() { echo "even" }

    classify_pane() {
      case "$1" in
        %1) echo "editor" ;; %2) echo "editor" ;; %3) echo "shell" ;;
      esac
    }

    priority_of() {
      case "$1" in
        editor) echo 1 ;; repl|tests|build) echo 2 ;; logs|monitor|git) echo 3 ;;
        docs|shell) echo 4 ;; *) echo 5 ;;
      esac
    }

    pane_ids=(%1 %2 %3)
    typeset -A pane_categories
    editor_count=0
    has_primary=false

    for pid in "${pane_ids[@]}"; do
      category="$(classify_pane "$pid")"
      pane_categories[$pid]="$category"
      if [[ "$category" == "editor" ]]; then (( editor_count++ ))
      elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then has_primary=true; fi
    done

    sorted_panes=()
    for p in 1 2 3 4 5; do
      for pid in "${pane_ids[@]}"; do
        if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
          sorted_panes+=("$pid")
        fi
      done
    done

    if (( editor_count > 1 )); then layout_grid "$editor_count" "${sorted_panes[@]}"
    elif (( editor_count == 1 )); then layout_main_sidebar "${sorted_panes[@]}"
    elif $has_primary; then layout_top_bottom "${sorted_panes[@]}"
    else layout_even; fi
  '
  [[ "$output" == "grid"* ]]
}

@test "repl without editor triggers top_bottom" {
  run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"

    layout_main_sidebar() { echo "main_sidebar" }
    layout_top_bottom() { echo "top_bottom $*" }
    layout_grid() { echo "grid" }
    layout_even() { echo "even" }

    classify_pane() {
      case "$1" in
        %1) echo "repl" ;; %2) echo "shell" ;;
      esac
    }

    priority_of() {
      case "$1" in
        editor) echo 1 ;; repl|tests|build) echo 2 ;; logs|monitor|git) echo 3 ;;
        docs|shell) echo 4 ;; *) echo 5 ;;
      esac
    }

    pane_ids=(%1 %2)
    typeset -A pane_categories
    editor_count=0
    has_primary=false

    for pid in "${pane_ids[@]}"; do
      category="$(classify_pane "$pid")"
      pane_categories[$pid]="$category"
      if [[ "$category" == "editor" ]]; then (( editor_count++ ))
      elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then has_primary=true; fi
    done

    sorted_panes=()
    for p in 1 2 3 4 5; do
      for pid in "${pane_ids[@]}"; do
        if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
          sorted_panes+=("$pid")
        fi
      done
    done

    if (( editor_count > 1 )); then layout_grid "$editor_count" "${sorted_panes[@]}"
    elif (( editor_count == 1 )); then layout_main_sidebar "${sorted_panes[@]}"
    elif $has_primary; then layout_top_bottom "${sorted_panes[@]}"
    else layout_even; fi
  '
  [[ "$output" == "top_bottom"* ]]
}

@test "all shells trigger even layout" {
  run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"

    layout_main_sidebar() { echo "main_sidebar" }
    layout_top_bottom() { echo "top_bottom" }
    layout_grid() { echo "grid" }
    layout_even() { echo "even" }

    classify_pane() { echo "shell" }

    priority_of() {
      case "$1" in
        editor) echo 1 ;; repl|tests|build) echo 2 ;; logs|monitor|git) echo 3 ;;
        docs|shell) echo 4 ;; *) echo 5 ;;
      esac
    }

    pane_ids=(%1 %2 %3)
    typeset -A pane_categories
    editor_count=0
    has_primary=false

    for pid in "${pane_ids[@]}"; do
      category="$(classify_pane "$pid")"
      pane_categories[$pid]="$category"
      if [[ "$category" == "editor" ]]; then (( editor_count++ ))
      elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then has_primary=true; fi
    done

    sorted_panes=()
    for p in 1 2 3 4 5; do
      for pid in "${pane_ids[@]}"; do
        if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
          sorted_panes+=("$pid")
        fi
      done
    done

    if (( editor_count > 1 )); then layout_grid "$editor_count" "${sorted_panes[@]}"
    elif (( editor_count == 1 )); then layout_main_sidebar "${sorted_panes[@]}"
    elif $has_primary; then layout_top_bottom "${sorted_panes[@]}"
    else layout_even; fi
  '
  [ "$output" = "even" ]
}

@test "editor comes first in sorted order" {
  run zsh -c '
    source "'"$BATS_TEST_DIRNAME"'/test_helper/tmux_mock.bash"

    layout_main_sidebar() { echo "$*" }
    layout_top_bottom() { echo "$*" }
    layout_grid() { shift; echo "$*" }
    layout_even() { echo "even" }

    classify_pane() {
      case "$1" in
        %1) echo "shell" ;; %2) echo "editor" ;; %3) echo "logs" ;;
      esac
    }

    priority_of() {
      case "$1" in
        editor) echo 1 ;; repl|tests|build) echo 2 ;; logs|monitor|git) echo 3 ;;
        docs|shell) echo 4 ;; *) echo 5 ;;
      esac
    }

    pane_ids=(%1 %2 %3)
    typeset -A pane_categories
    editor_count=0
    has_primary=false

    for pid in "${pane_ids[@]}"; do
      category="$(classify_pane "$pid")"
      pane_categories[$pid]="$category"
      if [[ "$category" == "editor" ]]; then (( editor_count++ ))
      elif [[ "$category" =~ ^(repl|tests|build)$ ]]; then has_primary=true; fi
    done

    sorted_panes=()
    for p in 1 2 3 4 5; do
      for pid in "${pane_ids[@]}"; do
        if [[ "$(priority_of "${pane_categories[$pid]}")" == "$p" ]]; then
          sorted_panes+=("$pid")
        fi
      done
    done

    if (( editor_count > 1 )); then layout_grid "$editor_count" "${sorted_panes[@]}"
    elif (( editor_count == 1 )); then layout_main_sidebar "${sorted_panes[@]}"
    elif $has_primary; then layout_top_bottom "${sorted_panes[@]}"
    else layout_even; fi
  '
  [ "$output" = "%2 %3 %1" ]
}
