# Product

<!-- impeccable:product-schema 1 -->

## Platform

desktop

Adaptation: the impeccable schema names `web`, `ios`, `android`, or `adaptive`.
Astraea is a desktop Emacs distribution (Emacs 31+, GUI-first with graphic-free
fallbacks), so this record uses `desktop`.

## Users

The author as primary daily driver: a single power user who lives inside one
Emacs session for code, notes, writing, and reading. Secondary audience: Emacs
users who want AstroNvim/spacemacs-grade ergonomics out of the box — modal
editing, completion, LSP, org — without assembling a config themselves, and who
prefer a cute pastel aesthetic over the usual dark cyberpunk themes.

## Product Purpose

A batteries-included, high-performance Emacs framework: every advertised feature
present and working, with startup cost treated as a first-class product quality.
Success means the author daily-drives it and others can adopt it through
`~/.astraea.d/init.el` without ever touching framework internals.

## Positioning

AstroNvim-grade UX translated to Emacs (dashboard, bufferline tabs, which-key,
pixel scroll, mode-line pets) wrapped in a kawaii celestial identity — `✦ Astraea ✦`,
pastel pink, nyan cat, "no doom, ever" — a combination no mainstream Emacs
distribution offers. Performance is positioned as a measured feature, not a
claim: startup work is profiled and benchmarked at the elpaca-queue level.

## Operating Context

- User configuration lives at `~/.astraea.d/init.el`; the framework is never
  edited by users (spacemacs/astronvim philosophy) and upgrades must not clobber it.
- The repo itself is `~/.emacs.d` (junction into the project tree); packages are
  managed by elpaca with builds under `elpaca/builds/`.
- Layers: file layers in `layers/` plus inline `astraea-layer!` declarations.
- Modal editing is switchable at runtime (`evil` / `meow` / `hybrid`).
- Leader key `SPC`; everything discoverable through which-key and transients.
- The author tests changes with `SPC q r` and expects verified commits.
- Batch/noninteractive use is real: topgrade runs `emacs --batch` package
  upgrades on a schedule.

## Capabilities and Constraints

- Completion: vertico/consult/marginalia/embark + corfu/cape (or company).
- LSP: eglot (default) or lsp-mode; treesit; yasnippet.
- Org: org-modern, org-appear, valign, citar, jupyter notebooks, org-roam,
  ox-pandoc/ox-hugo.
- UI: dashboard (banner + items), mood-line modeline, tab-per-file tab bar,
  treemacs, nerd-icons everywhere, indent-bars, eye-candy effects (all
  individually toggleable, group switch `astraea-effects-enabled`).
- Constraints: keep every feature while optimizing startup; GUI-only code must
  stay behind `display-graphic-p`; batch sessions must never crash on display
  assumptions; no doom-themes; visual identity is pastel and pink.
- Terminology: "layers", "leader", "effects", "toggles", "transients" follow
  the Astraea vocabulary used in code and messages.

## Brand Commitments

- Name and motif: Astraea — Greek star goddess; `✦` glyphs, star/moon voice.
- Sakura pink accent `#ff8fc7`; pastel palettes only (catppuccin default,
  ef-summer fallback).
- Mode-line pets (nyan cat, Pikachu) and cute footer copy are deliberate
  identity, not jokes to be cleaned up.
- `FiraCode Nerd Font` as the default face.
- Tone in messages and footers: warm, playful, concise — never corporate.

## Evidence on Hand

- `etc/banner.png` — the real dashboard banner.
- `user/init.example.el` — the shipped configuration template.
- `tests/` — check-parens, ci-driver, hybrid-batch test drivers.
- `astraea-startup-benchmark` — built-in startup measurement.
- Existing theme list in `core/astraea-ui.el` (catppuccin, ef-themes, sakura,
  cherry-blossom, bubbleberry, lavender, kaolin…). No testimonials, user
  numbers, or benchmarks exist; future work must not fabricate them.

## Product Principles

1. Every feature present, but paid lazily — deferral and caching are design
   tools, not compromises.
2. Startup time is a feature; measure at the queue level before and after.
3. Cute is the brand; craft is the standard — pastel is a palette, not an
   excuse for sloppy spacing, contrast, or consistency.
4. The framework stays pristine; the user's `~/.astraea.d/init.el` is sacred.
5. Batch, CI, and tests are first-class citizens on par with the interactive UI.

## Accessibility & Inclusion

- Text contrast: pastel themes must keep body text at usable contrast against
  their backgrounds; dim foregrounds are for secondary text only, never for
  primary content.
- Motion: every animated effect (beacon, pulsar, nav-flash, smooth scroll,
  pets) has an individual toggle and a group kill switch (`astraea-effects-enabled`).
- Input: all features must remain reachable by keyboard; mouse affordances are
  additive.
