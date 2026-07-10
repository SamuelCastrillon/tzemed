# Scoop Manifest Field Reference

Based on Scoop v0.5.3 Docs and the Tzemed bucket manifest (`bucket/tzemed.json`).

## Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `version` | string | App version. Must match the Git tag without `v` prefix. | `"1.0.1"` |
| `description` | string | One-line app description. | `"Tzemed — Windows native dev stack distro"` |
| `homepage` | string | Project homepage or repo URL. | `"https://github.com/SamuelCastrillon/tzemed"` |
| `license` | string | SPDX license identifier. | `"MIT"` |
| `url` | string | Download URL. Supports `$version` in autoupdate. | `"https://github.com/.../archive/refs/tags/v1.0.1.zip"` |
| `hash` | string | SHA-256 of the download. Prefix with `sha256:` optional. | `"c64e27fdca41db3b0d65ab60942b83c1..."` |

## Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `extract_dir` | string | Subdirectory inside the archive to extract. | `"tzemed-1.0.1"` |
| `bin` | array | Executables to shim. Array of `[path, alias]` pairs. | `[["scripts\\tzemed.ps1", "tzemed"]]` |
| `depends` | array | Scoop apps required. Installed automatically. | `["herdr", "neovim", "peri", "starship"]` |
| `notes` | array | Post-install messages shown to user. | `["Tzemed installed! Run 'tzemed' to init."]` |
| `persist` | array | Directories/files to persist across updates. | `["conf", "data"]` |

## Installer Scripts

| Field | Type | Description |
|-------|------|-------------|
| `installer.script` | string/array | PowerShell to run after extraction. `$dir` = version dir. |
| `pre_install` | string/array | Runs before extraction. `$dir` = version dir. |
| `post_install` | string/array | Runs after install. `$dir` = `current` symlink dir (NOT version dir). |
| `pre_uninstall` | string/array | Runs before uninstall. |
| `post_uninstall` | string/array | Runs after uninstall. |

**Available script variables**: `$dir`, `$persist_dir`, `$version`, `$fname`, `$manifest`, `$architecture`, `$scoopdir`, `$bucketsdir`, `$cachedir`, `$cfgpath`, `$globaldir`, `$original_dir`.

## Autoupdate

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `checkver` | string/object | Version source. `"github"` = auto from GitHub releases. | `"github"` or `{ "github": "https://github.com/owner/repo" }` |
| `autoupdate.url` | string | URL template with `$version`. | `"https://.../archive/refs/tags/v$version.zip"` |
| `autoupdate.extract_dir` | string | Extract dir template with `$version`. | `"tzemed-$version"` |
| `autoupdate.hash` | object | How to get new hash. `mode: "github"` uses GitHub metadata. | `{ "url": "$url", "mode": "github" }` |

### Hash Modes

- **`"github"`** — Scoop computes the hash from the GitHub archive URL automatically (recommended for GitHub archives).
- **`"extract"`** — hash from a URL content (default regex looks for SHA256 next to filename).
- **`"json"`** — extract hash from a JSON response using `jp` or `jsonpath`.
- **`"download"`** — download the file and compute hash locally.

## Tzemed-Specific Patterns

```json
{
  "version": "1.0.1",
  "depends": ["herdr", "neovim", "peri", "starship"],
  "installer": {
    "script": "& \"$dir\\scripts\\install.ps1\" -ConfigDir \"$dir\\config\" -TzemedDir \"$dir\""
  },
  "bin": [["scripts\\tzemed.ps1", "tzemed"]],
  "checkver": { "github": "https://github.com/SamuelCastrillon/tzemed" },
  "autoupdate": {
    "url": "https://github.com/SamuelCastrillon/tzemed/archive/refs/tags/v$version.zip",
    "extract_dir": "tzemed-$version",
    "hash": { "url": "$url", "mode": "github" }
  }
}
```

## References

- [Scoop App Manifests](https://github.com/scoopinstaller/scoop/wiki/App-Manifests)
- [Scoop Autoupdate](https://github.com/scoopinstaller/scoop/wiki/App-Manifest-Autoupdate)
- [Scoop Pre/Post Scripts](https://github.com/scoopinstaller/scoop/wiki/Pre-Post-(un)install-scripts)
- [Scoop Buckets](https://github.com/scoopinstaller/scoop/wiki/Buckets)
