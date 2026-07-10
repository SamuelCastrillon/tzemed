---
name: starship-config
description: "Trigger: starship, prompt, starship.toml, format string, module. Guide for Starship v1.26.0 prompt configuration and Tzemed palette."
license: Apache-2.0
metadata:
  author: "SamuelCastrillon"
  version: "1.0"
---

## Activation Contract

Load this skill when editing `config/starship.toml`, `~/.config/starship.toml`, or files under `config/theme/`. Also activate when the user asks about Starship modules, format strings, palette colors, style syntax, or prompt customization.

## Hard Rules

1. **TOML format MUST be valid.** All module configs are `[section]` keys; format strings use `$variable`, `[text group](style)`, and `(conditional)` syntax.
2. **Style strings** are space-separated words: `bold`, `italic`, `underline`, `dimmed`, `fg:<color>`, `bg:<color>`, or bare `<color>` for foreground. Last color wins. `none` resets.
3. **Tzemed palette** is the authority: violet-800 (`#5b21b6`) for brand, violet-600 (`#7c3aed`) for accent/success. Prefer hex codes from `config/theme/tzemed-palette.json`.
4. **Do NOT reference non-existent modules.** The module list is frozen at the Tzemed `format` string — only those 90+ modules are available. No `$fill`, `$typescript`, `$fortran`, `$mojo` etc. unless confirmed.
5. **Custom modules** go under `[custom.<name>]` with `command`, `when`, `detect_files`, `detect_folders`, or `detect_extensions`. The `shell` option takes `["shell.exe", "-c"]`.

## Decision Gates

| Need | Action |
|------|--------|
| Change prompt order | Top-level `format` string with `$module` names |
| Style a module | `style = "bold <color>"` in its `[module]` block |
| Right-align content | `right_format = "$module"` at top level |
| Add env var display | `[env_var]` with `variable = "NAME"` and `format` |
| Run a custom command | `[custom.<name>]` with `command`, optional `when`/`detect_*` |
| Use Tzemed colors | Reference hex from `config/theme/tzemed-palette.json` |
| Change prompt character | `[character] success_symbol / error_symbol / vicmd_symbol` |

## Execution Steps

1. Identify which module(s) need change.
2. Edit the matching `[module]` block in `config/starship.toml` (source of truth).
3. Use hex color codes from Tzemed palette: violet-800 `#5b21b6`, violet-600 `#7c3aed`, fg `#c0caf5`, fg_dim `#565f89`.
4. For new modules, add the `$module` name to the top-level `format` string.
5. Run `starship timings` to verify there are no errors. Run `starship module <name>` to debug a single module.
6. Validate by opening a new terminal or running `starship prompt --status 0` / `starship prompt --status 1`.

## Output Contract

Return the relevant `starship.toml` snippet, the module(s) changed, and confirmation that `starship timings` reports no errors. Reference `references/modules-reference.md` for module options.

## References

- `config/starship.toml` — live Tzemed Starship config (source of truth)
- `config/theme/tzemed-palette.json` — unified Tzemed color palette
- `references/modules-reference.md` — all available modules with key options
- Starship docs: <https://starship.rs/config/>
