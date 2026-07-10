---
name: scoop-bucket
description: "Trigger: scoop, manifest, bucket, tzemed.json, install.ps1, autoupdate. Guide for Scoop v0.5.3 bucket manifests and Tzemed distribution."
license: Apache-2.0
metadata:
  author: "SamuelCastrillon"
  version: "1.0"
---

## Activation Contract

Load this skill when editing `bucket/tzemed.json`, `scripts/install.ps1`, or any Scoop manifest JSON. Also activate when the user asks about bucket structure, `checkver`/`autoupdate` config, or Scoop manifest format questions.

## Hard Rules

1. **Manifest `version` MUST match the Git tag** (with or without `v` prefix — Scoop strips it). Use `"version": "1.0.1"` NOT `"version": "v1.0.1"`.
2. **`installer.script` runs inside the app version dir** (`$dir`). Always use `$dir` when referencing files in the extracted package — NOT relative paths.
3. **`post_install` runs in the `current` symlink dir**, NOT the version dir. Use `installer.script` instead when you need the actual version directory.
4. **`checkver` with `github` ignores pre-releases** by default. If the release tag doesn't match `\/releases\/tag\/(?:v|V)?([\d.]+)`, set `regex` explicitly.
5. **`persist` paths MUST use forward slashes** in the manifest JSON regardless of platform.

## Decision Gates

| Need | Action |
|------|--------|
| Auto-detect latest version from GitHub releases | `"checkver": "github"` (uses homepage repo) or `"checkver": { "github": "https://github.com/owner/repo" }` |
| Update URL/extract_dir on new version | `"autoupdate"` block with `$version` placeholder |
| Auto-update hash from source | `"autoupdate": { "hash": { "url": "$url.sha256" } }` or `"hash": { "mode": "github" }` for GitHub archives |
| Run PowerShell on install (post-extract) | `"installer": { "script": "..." }` — use `$dir` for version path |
| Register a CLI entry point | `"bin": [["scripts\\foo.ps1", "fooname"]]` — first is relative path, second is shim name |

## Execution Steps

1. Identify the change: version bump, dependency update, script change, or new app.
2. For version bumps: update `version`, `url` (tag), `hash`, and `extract_dir` — or let `autoupdate` handle them and run `.\bin\checkver.ps1 <app> -u`.
3. For install script changes: edit `installer.script` in the manifest AND the standalone `scripts/install.ps1`. The manifest script calls the standalone script — keep them in sync.
4. Validate: `scoop install <manifest>` from the bucket root. Check `scoop list` and `scoop status` after.
5. For bucket maintenance: `.\bin\checkver.ps1 * -u` from the bucket repo root updates all outdated manifests.

## Output Contract

Return the updated manifest snippet (or full file for new apps) and confirm validation with `scoop install`. Reference `references/manifest-reference.md` for field documentation.

## References

- `references/manifest-reference.md` — complete field reference with Tzemed examples
- `bucket/tzemed.json` — live Tzemed manifest
- `scripts/install.ps1` — Tzemed installer pipeline (called by `installer.script`)
