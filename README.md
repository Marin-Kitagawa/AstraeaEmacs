# Astraea Emacs

**The most feature-rich, most performant Emacs framework.**

Astraea fuses the three best ideas in modern editor frameworks:

| Source | What it contributes |
|---|---|
| **Spacemacs** | Layer system, SPC-leader keymaps, transient discoverable menus, which-key |
| **scimax** | Scientific org stack: jupyter notebooks, citar citations, CDLaTeX, org-roam, publishing |
| **AstroNvim** | Polished dashboard/modeline/tree UI, LSP+formatter+debugger toolchain, lazy-first performance |

…plus a **runtime-switchable modal engine** (zetta-style): evil and meow both
installed, one keymap, switch with a single command.

---

## Install

Requirements: **Emacs 30+ (31 recommended, ships treesit + eglot)**, Git, a
Nerd Font (recommended), `pwsh` on Windows, `ripgrep` for `SPC s g`.

```powershell
git clone https://github.com/astraea-emacs/astraea ~/projects/astraea-emacs
emacs --init-directory ~/projects/astraea-emacs
```

First launch installs all packages in parallel via **elpaca** (async package
manager with native-comp integration). Your configuration is seeded to
`~/.astraea.d/init.el` — the framework directory stays pristine, so updates
never clobber user config.

## Performance

- `early-init.el` defers GC, strips file-name handlers, kills frame flicker
- **Every** package defers until first use (`:commands`, `:hook`, `:after`)
- elpaca installs + AOT native-compiles packages **in parallel**
- `gcmh` throttles GC at idle; extra collection on frame focus loss
- All state outside `user-emacs-directory` via `no-littering`
- `M-x astraea/report-startup-time` and `M-x astraea/profile-startup`

## Modal editing (zetta-style switching)

```elisp
M-x astraea/set-modal-style RET meow RET   ; live switch, no restart
M-x astraea/toggle-modal-style             ; or bind it
```

The **same** `SPC` leader map works under both engines. Supported styles:

- `evil` — full Vim (spacemacs muscle memory), evil-collection everywhere
- `meow` — modern native modal, keypad + selection-first editing
- `hybrid` — evil with native Emacs insert-state bindings

## Leader keymap (SPC)

Mirrors AstroNvim conventions: `SPC f f` find file, `SPC b b` buffers,
`SPC s g` ripgrep, `SPC c a` code action, `SPC e` diagnostics, `SPC g g`
magit, `SPC j j` avy-jump (flash.nvim), `SPC u` toggles, `SPC SPC` M-x.
Transient menus: `SPC g` → git menu, buffers, workspaces — all
which-key-discoverable.

## Feature ↔ Neovim translation table

| Your AstroNvim plugin | Astraea equivalent |
|---|---|
| blink.cmp / coq_nvim | corfu + cape (+ vertico/consult minibuffer) |
| telescope | consult + vertico + embark |
| neo-tree | treemacs (+ dirvish for dired) |
| conform.nvim | apheleia (async formatting, never blocks) |
| mason/LSP | eglot (built-in) or lsp-mode |
| none-ls diagnostics | flymake + flymake-collection |
| nvim-dap | dape |
| noice/notify | transient menus + eldoc-box popups |
| flash.nvim | avy |
| grapple.nvim | tab-bar workspaces + `SPC T` transient |
| yazi.nvim | dirvish |
| undotree | vundo + undo-fu |
| grug-far.nvim | consult-ripgrep + wgrep |
| neoclip | consult-yank + savehist |
| img-clip | org-download |
| markview/markdown-preview | markdown-mode + grip (WebKit live preview) |
| treesitter | built-in treesit (Emacs 30+), max font-lock level |
| UFO folding | treesit-fold |
| alpha-nvim dashboard | dashboard.el |
| bufferline | tab-bar + doom-modeline |
| better-escape | `jk` escape via evil-escape |
| wakatime | `wakatime-mode` (one-line enable) |

## Layers

Declared inline or as files in `layers/`:

```elisp
(astraea-layer! +lang/rust
  :packages (rustic)
  :init  (elpaca rustic)
  :config (setq rustic-format-on-save t)
  :keybinds (astraea/leader-def "m r" #'rustic-cargo-run))
```

Inspect everything with `SPC h L` (`M-x astraea/list-layers`).

## scimax-grade org

`core/astraea-org.el` ships: org-modern visuals, jupyter async notebooks,
citar bibliography, CDLaTeX/AUCTeX, org-roam zettelkasten, pandoc export,
org-download image pasting, org-hugo publishing.

## Documentation

- `docs/architecture.md` — module map and design decisions

## License

GPL-3.0-or-later (required: Astraea embeds and configures GPL Emacs code).
