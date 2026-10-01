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

(defcustom astraea-theme 'doom-one
  "Default theme.  Set to a symbol loaded by `load-theme'."
  :type 'symbol)

(defcustom astraea-dashboard-enabled t
  "Show an astronvim-style dashboard on startup."
  :type 'boolean)

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

(defcustom astraea-pre-init-hook nil
  "Run just before elpaca processes queues."
  :type 'hook)

(defcustom astraea-after-init-hook nil
  "Run after all packages are loaded and modal engine activated."
  :type 'hook)

(provide 'astraea-variables)
;;; astraea-variables.el ends here
