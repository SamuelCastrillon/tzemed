---
name: herdr-config
description: "Trigger: herdr config, keybinding, config.toml, pane, multiplexor. Guide for Herdr configuration syntax, keybinding format, and known pitfalls."
license: Apache-2.0
metadata:
  author: "SamuelCastrillon"
  version: "1.0"
---

## Activation Contract

Load this skill when editing `config/herdr/config.toml`, `~/.config/herdr/config.toml`, or any file under `config/herdr/`. Also activate when the user asks about Herdr keybinding warnings, format questions, or `[keys]` configuration.

## Hard Rules

1. **Keybinding format MUST be a single string** with `+` separators: `"ctrl+shift+r"`. Arrays like `["ctrl", "shift", "r"]` are invalid — each element is interpreted as a standalone binding, causing `ctrl` and `shift` to emit "disabled" warnings.
2. **Built-in actions** (`focus_pane_left`, `split_vertical`, etc.) go in `[keys]` as `action = "key"`.
3. **Custom commands** use `[[keys.command]]` with a `type` field, NOT a flat key in `[keys]`.
4. Do NOT invent action names. Only default actions from Herdr docs are valid in `[keys]`.

## Decision Gates

| Need | Action |
|------|--------|
| Built-in Herdr action (focus, split, close, zoom, etc.) | `[keys] action_name = "key"` |
| Run any shell command on keypress | `[[keys.command]] type = "shell"` |
| Trigger a plugin action | `[[keys.command]] type = "plugin_action"` |
| Two alternative bindings for same action | String array: `action = ["key1", "key2"]` |

## Execution Steps

1. Identify the action: built-in vs custom shell command vs plugin action.
2. For built-in actions, add to `[keys]` using a single string format: `action_name = "ctrl+shift+r"`. For duplicates, pass an array: `action_name = ["prefix+h", "ctrl+alt+h"]`.
3. For custom shell commands, add a `[[keys.command]]` entry:
   ```toml
   [[keys.command]]
   key = "ctrl+shift+r"
   type = "shell"
   command = "herdr server reload-config"
   description = "reload herdr config"
   ```
4. Run `herdr server reload-config` to apply without restart.
5. If warnings persist, run `herdr config reset-keys` to start from defaults.

## Output Contract

Return the corrected `config.toml` snippet and confirm no `ctrl`/`shift`/`alt` binding warnings remain. Reference the `references/herdr-default-keys.toml` for valid action names.

## References

- `references/herdr-default-keys.toml` — all built-in key action names for `[keys]`
- `config/herdr/config.toml` — live Tzemed Herdr config
