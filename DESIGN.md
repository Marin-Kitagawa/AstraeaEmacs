---
name: Astraea Emacs
description: Pastel-cute Emacs framework — AstroNvim-grade UX with a celestial, kawaii identity
colors:
  # Canonical instance: catppuccin mocha, the shipping default. All structural
  # values (surface-lift, guide, divider) are derived at runtime by blending
  # base-bg toward base-fg; the hex values below are the mocha equivalents.
  base-bg: "#1e1e2e"
  base-fg: "#cdd6f4"
  dim-fg: "#7f849c"
  surface-lift: "#2a2b3c"
  guide: "#3e3f52"
  divider: "#535569"
  popup-border: "#45465a"
  accent-sakura: "#ff8fc7"
typography:
  body:
    fontFamily: "FiraCode Nerd Font"
    fontSize: "12pt"
  tab-bar:
    fontSize: "0.95em"
    fontWeight: "bold (active) / regular (inactive)"
  document-title:
    fontSize: "1.3x body"
    fontWeight: "bold"
  org-heading-1:
    fontSize: "1.2x body"
    fontWeight: "bold"
  org-heading-2:
    fontSize: "1.12x body"
    fontWeight: "bold"
  org-heading-3:
    fontSize: "1.05x body"

spacing:
  tab-padding: "3px box all sides, matching each tab's own background"
  fill-column: "100 columns"
  treemacs-width: "34 columns"
  dashboard: "content centered on both axes, banner above title"
components:
  dashboard:
    backgroundColor: "{colors.base-bg}"
    textColor: "{colors.base-fg}"
    rounded: "none (no radii in text UI)"
    padding: "centered"
  tab-active:
    backgroundColor: "{colors.surface-lift}"
    textColor: "{colors.base-fg}"
    rounded: "pill via box padding"
  tab-inactive:
    backgroundColor: "{colors.base-bg}"
    textColor: "{colors.dim-fg}"
    rounded: "pill via box padding"
  modeline:
    backgroundColor: "{colors.base-bg}"
    textColor: "{colors.base-fg}"
  corfu-menu:
    backgroundColor: "theme popup faces"
    rounded: "none (no radii in text UI)"
---

## Overview

Astraea dresses a serious, full-featured Emacs in a pastel night sky: catppuccin
pastels, a sakura-pink accent, star glyphs, and mode-line pets. The metaphor is a
**celestial parlor** — warm, cute, and calm on the surface, with an
AstroNvim-grade engine underneath. The design system is deliberately flat and
tonal: depth comes from subtle background lifts blended from the active theme,
never from shadows or hard borders. The system must adapt to whichever theme the
user selects (13+ pastel themes ship); every structural value is derived from
the `default` face at theme-load time, never hardcoded to one palette — except
the identity accent `#ff8fc7`, which is Astraea's own color and stays constant.

Because Emacs chrome is text and faces, the "tokens" in this file map to face
attributes: colors to face foreground/background, typography sizes to face
`:height` ratios, and spacing to box padding, fill-column, and window widths.

## Colors

- **base-bg / base-fg**: the active theme's `default` face. Everything derives
  from these two; restylers re-read them after every `load-theme`.
- **dim-fg**: the active theme's comment color, used only for secondary
  information (inactive tabs, minor text), never primary content.
- **surface-lift**: base-bg blended ~7% toward base-fg — marks the active tab
  and other "selected" chrome without breaking the flat pastel look.
- **guide**: ~18% blend — fill-column indicator and softly visible rules.
- **divider**: ~30% blend — window dividers and borders, visible but quiet.
- **popup-border**: ~22% blend — corfu popup edge definition.
- **accent-sakura `#ff8fc7`**: beacon beam, identifier of the brand; used for
  moments of focus and delight, never for large fills.
- Semantic mapping: pink = identity/moments; theme pastels = state (errors,
  success, warnings) — never restate what the theme already colors.

## Typography

- One family everywhere: `FiraCode Nerd Font` (Nerd Font glyphs are a hard
  requirement for the icon system). Size 12pt default, user-overridable.
- Hierarchy is expressed with modest `:height` ratios, never big jumps:
  document title 1.3, org level 1 1.2, level 2 1.12, level 3 1.05, body 1.0.
  Bold marks structure (headings, active tab, buffer name); nothing else.
- The dashboard title `✦  A S T R A E A  ✦` is letter-spaced with U+2009
  thin spaces — a deliberate logotype, keep the spacing exact.

## Layout

- Windows are the grid. Treemacs at 34 columns; fill-column guidance at 100 for
  code and prose; dashboard content centered on both axes.
- Grouping: related chrome stays tight (tab padding 3px pills), distinct zones
  get space (mode-line segments separated by two spaces, pets in their own
  segment).
- The tab bar is the bufferline: one tab per file, inline nerd icon + name.
  Tabs always stop at the window edge; no overflow arrows unless necessary.

## Elevation & Depth

Flat by design — a text UI has no shadows, and Astraea refuses fake ones. Depth
is tonal: `surface-lift` for the selected tab, `divider` for separations,
`guide` for measure. The only "depth" effects are momentary and motion-based:
beacon's soft beam, pulsar pulses, and nav-flash — all individually
toggleable. Never introduce hard box-shadow equivalents (heavy box colors,
high-contrast 2px+ filled borders) on chrome.

## Shapes

There are no corner radii in a text UI; the pill look comes from box padding
with the background color matching each tab's own fill (no visible frame
around pills). Underlines are reserved for links and the cursor line only.
Glyphs follow one family: nerd-icons (codicon set) for UI chrome and file
types, consistently scaled (`:height 1.0–1.2`). Emoji never appear as UI
icons — they may appear only inside human copy (dashboard footer voice).

## Components

- **Dashboard**: image banner, then `✦  A S T R A E A  ✦` title, then icon-led
  sections (recents/projects/bookmarks/agenda) with nerd-icons, and a three-line
  footer in the warm house voice with a pink sparkle icon. Centered both ways.
- **Tab bar**: active tab = `surface-lift` pill, base-fg, bold; inactive =
  base-bg, dim-fg. Height 0.95. Close buttons hidden; click-to-select works.
- **Modeline (mood-line, text-packed)**: buffer name bold; eol and indent style
  shown; nyan cat and Pokémon segments appear only while their modes are on,
  separated from the main left block by two spaces.
- **Minibuffer**: prompt bold (theme colors); vertico list with marginalia
  annotations and nerd-icons-completion icons.
- **Completion popup (corfu)**: theme-provided faces plus a `popup-border`
  edge; nerd-icons margin formatter for kind icons; popupinfo delayed 0.5s.
- **Tree (treemacs)**: root node bold; icons via nerd-icons; width 34.
- **Org**: org-modern glyph styling over theme faces; `org-ellipsis " ▾"`;
  emphasis markers hidden until cursor (org-appear); valign for tables.

## Do's and Don'ts

**Do**

- Derive every structural color from the active theme via the blend helpers;
  re-apply after every `load-theme`.
- Keep the sakura accent for moments (beacon, sparkles), not surfaces.
- Keep contrast: body text from the theme's foreground; dim only for
  secondary text; verify new faces against at least catppuccin and ef-summer.
- Keep copy in the house voice: warm, short, one idea per line.
- Keep every effect toggleable and batch-safe (`display-graphic-p` guards).

**Don't**

- Don't hardcode palette colors for structure (only `#ff8fc7` is ours).
- Don't add gray text on colored surfaces, pure black/white fills, or heavy
  borders that fight the pastel tone.
- Don't add shadows, gradients, or glow beyond the beacon/pulsar moments.
- Don't mix icon families: nerd-icons for chrome; emoji only in copy.
- Don't restate what themes already own (hl-line, region, error faces).
- Don't let pets or effects leak into daemon/batch sessions.
