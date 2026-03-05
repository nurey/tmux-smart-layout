# tmux-smart-layout

A tmux plugin that automatically rearranges panes based on their contents. Uses process name and content pattern matching to classify panes and apply the best layout.

## How it works

When triggered, the plugin:

1. **Classifies** each pane using a two-pass heuristic:
   - **Process name** — detects editors, REPLs, log viewers, monitors, etc.
   - **Content patterns** — for shell panes, scans visible text for log output, test results, build output, or git diffs

2. **Chooses a layout** based on the pane mix:
   - **Main + sidebar** — when an editor is present, it gets ~65% width on the left
   - **Top + bottom** — when a REPL/test/build pane is the primary, it gets ~60% height on top
   - **Even tiled** — fallback when all panes are shells or no clear primary exists

## Requirements

- tmux
- zsh (pre-installed on macOS)

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm)

Add to `~/.tmux.conf`:

```tmux
set -g @plugin 'nurey/tmux-smart-layout'
```

Then press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/nurey/tmux-smart-layout ~/.tmux/plugins/tmux-smart-layout
```

Add to `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-smart-layout/smart-layout.tmux
```

## Usage

Press `prefix + L` (default) to rearrange panes in the current window.

## Configuration

Add to `~/.tmux.conf` before the plugin line:

```tmux
# Keybinding (default: L)
set -g @smart-layout-key 'L'

# Editor pane width % for main+sidebar layout (default: 65)
set -g @smart-layout-editor-size '65'

# Primary pane height % for top+bottom layout (default: 60)
set -g @smart-layout-primary-size '60'
```

## Pane Classification

| Process | Category |
|---|---|
| `vim`, `nvim`, `vi`, `emacs`, `nano`, `hx`, `code`, `claude` | `editor` |
| `irb`, `pry`, `ghci`, `iex`, `lua` | `repl` |
| `tail`, `less`, `more`, `journalctl`, `multitail`, `puma` | `logs` |
| `htop`, `top`, `btop`, `glances`, `nmon`, `ngrok` | `monitor` |
| `man`, `info` | `docs` |
| `ruby`/`python`/`node` with REPL prompt (`>>>`, `irb(main)`, `pry(main)`, etc.) | `repl` |
| Shell with `webpack ... compiled successfully` output | `logs` |
| Shell with log patterns | `logs` |
| Shell with test output | `tests` |
| Shell with compiler output | `build` |
| Shell with git output | `git` |
| Everything else | `shell` |

## Layout Strategies

### Main + sidebar (single editor)

```
┌──────────────┬────────┐
│              │ shell  │
│   editor     ├────────┤
│   (65%)      │ tests  │
│              ├────────┤
│              │ logs   │
└──────────────┴────────┘
```

### Grid (multiple editors, e.g. two Claude panes)

```
┌────────────┬────────────┐
│  claude    │  claude    │
│            │   (60%)    │
├────────────┬────────────┤
│   repl     │   shell    │
└────────────┴────────────┘
```

### Top + bottom (REPL/tests/build present, no editor)

```
┌─────────────────────────┐
│   repl / tests (60%)    │
├────────────┬────────────┤
│   shell    │   logs     │
└────────────┴────────────┘
```

### Even tiled (fallback)

Standard tmux `tiled` layout.

## License

MIT
