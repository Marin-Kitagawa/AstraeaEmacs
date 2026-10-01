# Astraea Architecture

## Load pipeline

```
early-init.el      GC deferral, native-comp flags, file-handler stripping,
                   frame chrome suppression
init.el            load-path setup, requires astraea-init
astraea-init.el    elpaca bootstrap → core modules → user config
  └─ user config   ~/.astraea.d/init.el  (seeded from user/init.example.el)
      └─ (astraea/init)
          ├─ astraea/layers--enable-all    run :init forms of enabled layers
          ├─ elpaca-process-queues         parallel install/build/compile
          └─ astraea//finish-init
              ├─ astraea/modal--activate   evil/meow engine on
              ├─ astraea/ui//finish        theme, leader keys, layer :config
              └─ startup report
```

## Core modules (`core/`)

| Module | Responsibility |
|---|---|
| `astraea-variables` | defcustoms: modal style, backends, theme, keys |
| `astraea-lib` | `astraea/after!`, `astraea/add-hook!`, `astraea/setq!`, buffer utils |
| `astraea-performance` | gcmh, no-littering, focus GC, startup profiler |
| `astraea-defaults` | encoding, pwsh shell (Windows), editing QoL, undo stack |
| `astraea-layers` | `astraea-layer!` registry; file layers; enable/run protocol |
| `astraea-modal` | evil + meow install; runtime `astraea/set-modal-style` |
| `astraea-keybinds` | shared `astraea-leader-map`; transient menus; which-key |
| `astraea-ui` | dashboard, doom-modeline, treemacs, themes, folding, icons |
| `astraea-completion` | vertico/orderless/marginalia/consult/embark + corfu/cape/yasnippet |
| `astraea-ide` | eglot/lsp-mode, apheleia, dape, flymake, treesit remapping |
| `astraea-org` | scimax stack: jupyter, citar, cdlatex/auctex, org-roam, export |
| `astraea-project` | project.el, tab-bar workspaces, dirvish, org-download, grip, eshell |

## Design decisions

1. **One leader map, two engines.** `astraea-leader-map` is a plain keymap
   bound to SPC in evil's normal/visual/motion states *and* meow's normal
   state. Switching engines rebinds nothing — users keep muscle memory.
2. **Layers are data, not includes.** A layer is a plist on a symbol
   (`:packages :init :config :keybinds`). This keeps enabling order
   independent of load order and lets inline layers live in user config.
3. **elpaca over straight/package.** Async parallel installs, native-comp
   integration, transactional queues. `use-package` is transparently
   redirected to elpaca via `elpaca-use-package-mode`.
4. **Everything defers.** Core modules only *declare* packages inside
   `elpaca` blocks; activation happens in `:init`-deferred hooks so startup
   cost is bounded regardless of feature count.
5. **Backends are defcustoms.** `astraea-lsp-backend`, `astraea-completion-
   backend`, `astraea-modal-style` swap entire subsystems without editing
   framework code.
6. **Windows first-class.** pwsh + UTF-8 shell defaults mirror a real
   AstroNvim `polish.lua`; w32 optimizations in `astraea-defaults`.

## Extending

- New file layer: create `layers/astraea-layer-+category-name.el`, declare
  with `astraea-layer!`, enable with `(astraea/enable-layer '+category/name)`.
- New keybinds: `astraea/leader-def` (idempotent, which-key-aware).
- New backend option: add a defcustom choice + a conditional setup block.
