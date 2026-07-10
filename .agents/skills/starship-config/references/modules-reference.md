# Starship Modules Reference — v1.26.0

> All modules below are available in Tzemed's `format` string. See `config/starship.toml` for the full ordered list.

## Prompt-Level Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `format` | string | `"$all"` | Prompt format string |
| `right_format` | string | `""` | Right-aligned prompt section |
| `add_newline` | bool | `true` | Blank line before each prompt |
| `scan_timeout` | int (ms) | `30` | Max time for file scanning |
| `command_timeout` | int (ms) | `500` | Max time for subcommands |
| `palette` | string | — | Palette name from `[palettes.<name>]` |

## Format String Syntax

- **`$module_name`** — renders a module
- **`[text](style)`** — text group with optional styling
- **`(content)`** — conditional group (renders only if variables non-empty)
- **`\(escape\)`** — escaped parentheses
- **`$all`** — expands to all default modules

## UI / Shell Modules

| Module | Key Options | Default | Notes |
|--------|-------------|---------|-------|
| `character` | `success_symbol`, `error_symbol`, `vicmd_symbol` | `[❯](bold green)` / `[❯](bold red)` | vimcmd uses `[❮](bold green)` |
| `shell` | `bash_indicator`, `powershell_indicator`, `style` | disabled | Show current shell name |
| `line_break` | `disabled` | — | Set `disabled = true` for single-line |
| `status` | `format`, `symbol`, `pipestatus`, `pipestatus_format` | disabled | Exit code of last command |
| `sudo` | `format`, `style`, `allow_windows` | disabled | Sudo/cached credential indicator |
| `cmd_duration` | `min_time` (ms), `format`, `show_milliseconds` | `min_time = 2000` | Command execution time |

## Info Modules

| Module | Key Options | Notes |
|--------|-------------|-------|
| `username` | `format`, `show_always` | Show always or only when root/remote |
| `hostname` | `ssh_only`, `trim_at` | Show only over SSH by default |
| `directory` | `truncation_length`, `truncate_to_repo`, `format` | `truncate_to_repo = true` shortens in git repos |
| `localip` | `format`, `ssh_only` | Show local IP address |
| `shlvl` | `threshold`, `format` | Shell level (for nested shells) |
| `os` | `format`, `style`, `[os.symbols]` | OS name and icon per platform |
| `time` | `time_format`, `utc_time_offset`, `time_range` | **Disabled by default** |
| `memory_usage` | `format`, `threshold`, `disabled` | RAM usage percentage |
| `jobs` | `symbol`, `number_threshold`, `symbol_threshold` | Background job count |
| `battery` | `full_symbol`, `charging_symbol`, `display` | Power status (laptops) |
| `container` | `symbol`, `style`, `format` | Detect container environments |

## Git Modules

| Module | Key Options | Notes |
|--------|-------------|-------|
| `git_branch` | `format`, `style`, `symbol`, `truncation_length` | Show current branch |
| `git_status` | `format`, `conflicted`, `ahead`, `behind`, `modified`, `staged`, `deleted`, `untracked`, `stashed`, `renamed` | Per-change-type symbols |
| `git_commit` | `format`, `commit_hash_length` | Show commit hash |
| `git_state` | `format`, `rebase`, `merge`, `cherry_pick` | Show in-progress git operations |
| `git_metrics` | `format`, `added_style`, `deleted_style` | Added/deleted lines count |

## Language Runtimes (partial list)

| Module | Key Options | Detect Heuristic |
|--------|-------------|------------------|
| `nodejs` | `format`, `symbol`, `style`, `detect_files` | `package.json` |
| `python` | `format`, `symbol`, `style` | `.py` files, `venv` |
| `rust` | `format`, `symbol`, `style` | `Cargo.toml` |
| `golang` | `format`, `symbol`, `style` | `go.mod` |
| `java` | `format`, `symbol`, `style` | `pom.xml`, `build.gradle` |
| `ruby` | `format`, `symbol`, `style` | `Gemfile` |
| `php` | `format`, `symbol`, `style` | `composer.json` |
| `lua` | `format`, `symbol`, `style` | `.lua` files, `.rockspec` |
| `c` | `format`, `symbol`, `style` | `.h`, `.c` files |

## Custom & Env Modules

| Module | Key Options | Notes |
|--------|-------------|-------|
| `env_var` | `variable`, `format`, `default` | Show an environment variable value |
| `custom.<name>` | `command`, `when`, `detect_files`, `detect_folders`, `detect_extensions`, `shell`, `format`, `style`, `os` | Run arbitrary commands; `shell` expects `["path/to/shell", "-c"]` |
| `direnv` | `format`, `style` | Show `.envrc` loading status |

## Palette Definition

```toml
[palettes.tzemed]
violet_800 = "#5b21b6"
violet_600 = "#7c3aed"
violet_400 = "#a78bfa"
bg = "#0c0c0c"
fg = "#c0caf5"
fg_dim = "#565f89"
blue = "#7aa2f7"
cyan = "#7dcfff"
green = "#9ece6a"
red = "#f7768e"
yellow = "#e0af68"
orange = "#ff9e64"
```

Enable with `palette = "tzemed"` at top level.

## Common Pitfalls

- **Arrays in keybindings** — NOT a thing in Starship. Use format strings only.
- **`$all` includes everything** — if you see a module you don't want, disable it explicitly with `disabled = true`.
- **Colors** — hex codes MUST have `#` prefix. Named colors (16 standard terminal colors + `purple`/`bright-*`) work outside palettes.
- **Custom command `shell`** — on Windows use `["pwsh", "-NoProfile", "-c"]` to avoid profile contamination.
- Test with `starship timings` after any change; debug single modules with `starship module <name>`.

> Source: official Starship docs at <https://starship.rs/config/> — v1.26.0
