# Tzemed — PRD (Product Requirements Document)

> צמד — "yunta/team" en hebreo.
> Una distro curada, instalable y nativa de Windows para desarrollo con IA.

## 1. Problema

**Gentleman.Dots** existe y es excelente, pero es Unix-first. Windows requiere WSL, lo que agrega complejidad, overhead y rompe la experiencia nativa.

No hay una alternativa que:
- Sea **100% nativa de Windows** (sin WSL)
- Sea un **producto instalable**, no un conjunto de configs separadas
- Integre **Herdr + Nvim + Peri + SDD** como un stack único y coherente

## 2. Visión

Tzemed es una **herramienta de instalar y usar**. No es un conjunto de configuraciones para que el usuario elija su combo — es una **distro opinionada** donde:

1. Instalás Tzemed
2. Tenés el stack completo funcionando
3. Todo está preintegrado

## 3. Stack (fijo, opinionado)

| Capa | Herramienta | Justificación |
|---|---|---|
| Multiplexor / Agent Workspace | **Herdr** | Rust nativo, agent-aware, sidebar con estados, persistencia de sesiones, plugins |
| Editor | **Neovim** (Nvim) | Sobre **LazyVim** como base (LSP, autocompletado, file tree, themes), tomando la estructura de Gentleman.Dots como referencia |
| Agente IA | **Peri** | Rust (~13MB, ~50MB RAM), multi-LLM, compatible con Claude Code skills/configs |
| Workflow | **Gentle-ai SDD** | Spec-Driven Development con sub-agentes orquestados |
| Shell | **PowerShell** / **Nushell** | Nativo de Windows + opción moderna |
| Prompt | **Starship** | Cross-platform, rápido, minimalista |

### Stack NO incluido (diferencia con Gentleman.Dots)

- ❌ Múltiples terminales (Alacritty, Kitty, Ghostty, WezTerm) — el usuario usa el que quiera
- ❌ Múltiples shells (Fish, Zsh, Bash) — PowerShell + Nushell es suficiente
- ❌ Múltiples multiplexores (Tmux, Zellij) — solo Herdr
- ❌ Múltiples agentes IA — solo Peri
- ❌ WSL — todo es nativo

## 4. Instalación

### Package Managers (primarios)

1. **Scoop** — bucket propio (`scoop bucket add tzemed`)
2. **winget** — manifiesto en el repo de Microsoft Community

### Lo que instala Tzemed

- [ ] Herdr (desde GitHub releases, binario nativo Windows)
- [ ] Neovim (última versión estable)
- [ ] Peri (desde GitHub releases)
- [ ] LazyVim + configuración Tzemed (estructura de archivos)
- [ ] Starship prompt
- [ ] Nushell (opcional)
- [ ] Nerd Font (recomendada, instalación opcional)

### Post-instalación

El instalador debe:
1. Descargar/extrer los binarios necesarios
2. Colocar la configuración de Nvim en `%LOCALAPPDATA%\nvim\`
3. Colocar la configuración de Herdr en `%APPDATA%\herdr\`
4. Colocar la configuración de Peri en `%APPDATA%\peri\`
5. Agregar binarios al PATH (o informar cómo hacerlo)
6. Ejecutar `herdr` para primera inicialización

## 5. Arquitectura de Archivos

```
tzemed/
├── docs/                          # Documentación
│   ├── PRD.md                     # Este documento
│   ├── architecture.md            # Arquitectura detallada
│   ├── nvim-keymaps.md            # Keymaps de Neovim
│   ├── herdr-setup.md             # Configuración de Herdr
│   └── peri-setup.md              # Configuración de Peri
├── config/                        # Configuraciones oficiales
│   ├── nvim/                      # Configuración de Neovim (LazyVim-based)
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── config/
│   │       │   ├── options.lua
│   │       │   ├── keymaps.lua
│   │       │   ├── autocmds.lua
│   │       │   └── lazy.lua
│   │       └── plugins/
│   │           ├── editor.lua     # Plugins de editor
│   │           ├── ui.lua         # Plugins de UI
│   │           ├── lsp.lua        # LSP config
│   │           ├── ai.lua         # Integración con Peri
│   │           └── tzemed.lua     # Plugins específicos de Tzemed
│   ├── herdr/                     # Config de Herdr
│   │   └── config.toml
│   ├── peri/                      # Config de Peri
│   │   └── peri.toml
│   └── starship.toml              # Starship prompt
├── scripts/                       # Scripts de instalación
│   ├── install.ps1                # Instalador principal (PowerShell)
│   ├── update.ps1                 # Script de actualización
│   └── tzemed.ps1                 # Entry point "tzemed"
├── scoop-bucket/                  # Manifiestos para Scoop
│   └── tzemed.json
├── winget/                        # Manifiesto para winget
│   └── tzemed.yaml
├── skills/                        # Skills SDD para el proyecto
│   └── tzemed-dev.md              # Skill de desarrollo Tzemed
├── tests/                         # Tests
│   ├── e2e/                       # Tests end-to-end de instalación
│   └── unit/                      # Tests unitarios de scripts
├── AGENTS.md                      # Documentación para agentes IA
└── README.md
```

## 6. Estrategia de Integración

### Flujo del usuario

```
1. scoop install tzemed
2. tzemed                          # Instala/configura todo
3. herdr                           # Abre el multiplexor
   ├── Pane 1: nvim                # Editor con Peri integrado
   ├── Pane 2: terminal            # Shell con Starship
   └── Pane 3: peri                # Agente IA (opcional)
```

### Integración Nvim ↔ Peri

Peri debe poder:
- Abrir archivos en Nvim
- Leer el buffer activo
- Ejecutar comandos de Nvim

Esto se logra via MCP o integración directa Peri-Nvim.

### Integración Herdr ↔ Nvim

Herdr ya soporta Nvim como editor. La config debe:
- Abrir Nvim automáticamente al crear un pane de edición
- Mostrar el estado de Peri en la sidebar de Herdr
- Soportar atajos de teclado consistentes

## 7. Modelo de IA (Peri)

- **Modelo por defecto**: DeepSeek (o el que elija el usuario)
- **Soporte multi-LLM**: Peri permite cambiar de modelo sin reiniciar
- **API OpenCode**: Si Peri no lo soporta aún, evaluar contribuir o wrapper
- **Skills SDD**: heredar skills de gentle-ai donde apliquen

## 8. Actualizaciones

### Mecanismo

- **Actualización manual** vía `scoop update tzemed`
- **Notificación**: al abrir Herdr/Nvim, check de versión y aviso si hay nueva
- **Auto-update opcional**: script que ejecuta `scoop update tzemed` dentro de la herramienta

## 9. MVP (Versión 1)

El MVP es que la instalación funcione. No features avanzadas todavía.

### Criterios de éxito del MVP

- [ ] `scoop install tzemed` instala Herdr, Nvim, Peri y configs
- [ ] `tzemed` (entry point) configura todo y deja el stack listo
- [ ] Al abrir `herdr`, se ve el layout con Nvim listo
- [ ] Nvim tiene LazyVim funcionando con LSP básico
- [ ] Peri está configurado y accesible desde Nvim
- [ ] Starship prompt funcional
- [ ] Documentación básica para el usuario

## 10. No Metas (para futuras versiones)

- [ ] Temas/colorschemes configurables por el usuario
- [ ] Vim Mastery Trainer (como Gentleman.Dots)
- [ ] Soporte para Linux/macOS
- [ ] Plugin system para Tzemed
- [ ] TUI installer interactivo

## 11. Estrategia de Desarrollo

### SDD

Usaremos Spec-Driven Development con:
- Engram como artifact store
- Skills SDD para fases (explore, propose, spec, design, tasks, apply, verify, archive)
- Modelos asignados por fase

### Testing

- **Unitarios**: scripts PowerShell/lua
- **E2E**: instalación completa en entorno limpio (Docker + Wine o GitHub Actions Windows)
- **Validación**: verificar que Herdr, Nvim y Peri arrancan después de instalar

### Skills

Skills necesarias para el proyecto:
- `tzemed-installer` — patrón de instalación scoop/winget
- `tzemd-nvim` — configuración LazyVim adaptada
- `tzemed-dev` — workflow de desarrollo del proyecto

## 12. Portabilidad Cross-Platform

### Filosofía

El PRD y MVP se centran en **Windows nativo**, pero la arquitectura de configs se diseña portable desde el día 1 para que agregar Linux después sea barato.

### Estrategia

- **Todas las configs** viven en `~/.config/<tool>/` (compatible con Windows vía `$XDG_CONFIG_HOME`)
- El instalador de Windows setea `$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"` en el profile de PowerShell 7+
- Los binarios y package managers cambian por plataforma; las configs **no**
- El repo refleja exactamente la estructura que termina en disco del usuario

### Estructura portable

```
~/.config/
├── nvim/
│   ├── init.lua
│   └── lua/
│       ├── config/...
│       └── plugins/...
├── herdr/
│   └── config.toml
├── peri/
│   └── config.toml
└── starship.toml
```

### Roadmap

| Fase | Plataforma |
|------|-----------|
| MVP | Windows (Scoop + winget) |
| Post-MVP | Linux (Homebrew + direct download) |

## 13. Licencia

MIT — igual que Gentleman.Dots y gentle-ai.

---

*Documento vivo — actualizado: 2026-07-09*
