;;; astraea-variables.el --- Global Astraea customization definitions -*- lexical-binding: t; -*-

(defgroup astraea nil
  "Astraea Emacs — the most feature-rich, most performant Emacs framework."
  :group 'emacs
  :prefix "astraea-"
  :link '(url-link :tag "Repository" "https://github.com/astraea-emacs/astraea"))

(defcustom astraea-user-directory (expand-file-name "~/.astraea.d/")
  "Directory holding user configuration and cached data."
  :type 'directory)

(defcustom astraea-modal-style 'evil
  "Which modal editing engine to activate.
Symbol `evil' (Vim, spacemacs-style), `meow' (modern modal), or
`hybrid' (evil + native Emacs insert-state bindings).  Switchable
at runtime with \\[astraea/set-modal-style]."
  :type '(radio (const :tag "Vim (evil)" evil)
                (const :tag "Meow" meow)
                (const :tag "Evil hybrid" hybrid)))

(defcustom astraea-modal-switchable t
  "When non-nil, install both evil and meow so styles can be
switched at runtime.  When nil, only `astraea-modal-style' is
installed (smaller footprint, faster startup)."
  :type 'boolean)

(defcustom astraea-leader-key "SPC"
  "Leader key, spacemacs/astronvim style."
  :type 'key)

(defcustom astraea-localleader-key ","
  "Local leader key for mode-specific keybinds."
  :type 'key)

(defcustom astraea-theme 'ef-summer
  "Default theme.  Cute/feminine picks: ef-summer (pastel pink),
ef-rosa, sakura, cherry-blossom, pink-bliss-uwu, pastelmac,
bubbleberry, lavender, moe-light, catppuccin.  Set to a symbol
loaded by `load-theme'.  Browse all with `ef-themes-select' or
`load-theme' + TAB."
  :type 'symbol)

(defcustom astraea-dashboard-enabled t
  "Show an astronvim-style dashboard on startup."
  :type 'boolean)

(defcustom astraea-dashboard-banner "etc/banner.png"
  "Image file shown on the dashboard (spacemacs-style image banner).
Relative paths resolve against `user-emacs-directory'.  Set to any
PNG/JPG you like, or nil for the built-in ASCII logo."
  :type '(choice file (const nil)))

(defcustom astraea-startup-benchmark nil
  "Report startup time and slowest packages after init."
  :type 'boolean)

(defcustom astraea-lsp-backend 'eglot
  "LSP backend: `eglot' (built-in, light) or `lsp-mode' (heavier,
more features)."
  :type '(radio (const eglot) (const lsp-mode)))

(defcustom astraea-completion-backend 'corfu
  "In-buffer completion backend: `corfu' (fast, modern) or
`company'."
  :type '(radio (const corfu) (const company)))

(defcustom astraea-wakatime-enabled nil
  "Enable WakaTime tracking (requires the `wakatime-cli' binary)."
  :type 'boolean)

(defcustom astraea-discord-presence-enabled nil
  "Enable Discord rich presence via elcord (presence.nvim equivalent)."
  :type 'boolean)

(defcustom astraea-copilot-enabled nil
  "Enable GitHub Copilot in programming buffers (requires
`copilot-language-server' from npm)."
  :type 'boolean)

(defcustom astraea-font nil
  "Default font, e.g. \"JetBrainsMono Nerd Font\" or \"Cascadia Code\".
When nil, the system default is kept.  See `astraea-font-size'."
  :type '(choice string (const nil)))

(defcustom astraea-font-size 12
  "Default font size in points (used with `astraea-font')."
  :type 'number)

(defcustom astraea-pre-init-hook nil
  "Run just before elpaca processes queues."
  :type 'hook)

(defcustom astraea-after-init-hook nil
  "Run after all packages are loaded and modal engine activated."
  :type 'hook)

(provide 'astraea-variables)
;;; astraea-variables.el ends here
