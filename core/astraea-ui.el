;;; astraea-ui.el --- Dashboard, modeline, themes, tree, notifications -*- lexical-binding: t; -*-
;;
;; AstroNvim-grade UI, translated to Emacs:
;;   alpha-nvim        → dashboard.el
;;   noice/notify      → via +posframe which-key & transient menus
;;   neo-tree          → treemacs (SPC e tree via dirvish/dired also)
;;   bufferline        → mood-line / doom-modeline + tab-bar workspaces
;;   indent guides     → indent-bars
;;   web-devicons      → nerd-icons
;;   UFO folding       → treesit-fold
;;   flash.nvim        → avy
;;   snacks smooth UI  → pixel-scroll-precision + ultra-scroll

;; ── Icons ─────────────────────────────────────────────────────────────────
(elpaca nerd-icons)
(elpaca nerd-icons-corfu)

;; ── Dashboard (alpha-nvim equivalent) ────────────────────────────────────
(elpaca dashboard
  (when astraea-dashboard-enabled
    (setq dashboard-items '((recents . 10) (projects . 8) (bookmarks . 5) (agenda . 5))
          dashboard-startup-banner 'logo
          dashboard-center-content t
          dashboard-vertically-center-content t
          dashboard-set-heading-icons t
          dashboard-set-file-icons t
          dashboard-display-icons-p #'icons-displayable-p
          initial-buffer-choice (lambda () (get-buffer dashboard-buffer-name)))
    (dashboard-setup-startup-hook)))

;; ── Modeline (bufferline.nvim equivalent lives in tab-bar) ───────────────
(elpaca doom-modeline
  (setq doom-modeline-height 32
        doom-modeline-bar-width 4
        doom-modeline-icon t
        doom-modeline-lsp t
        doom-modeline-modal-icon t
        doom-modeline-buffer-file-name-style 'relative-from-project)
  (doom-modeline-mode 1))

(when (display-graphic-p)
  (tab-bar-mode 1)
  (setq tab-bar-show 1
        tab-bar-close-button-show nil))

;; ── File tree (neo-tree equivalent) ──────────────────────────────────────
(elpaca treemacs
  (setq treemacs-follow-after-init t
        treemacs-width 34
        treemacs-is-never-other-window t))
(elpaca treemacs-evil)
(elpaca treemacs-projectile)
(elpaca treemacs-icons-dired
  (treemacs-icons-dired-mode))

;; ── Theme & syntax polish ────────────────────────────────────────────────
(elpaca doom-themes)
(elpaca catppuccin-theme)   ; matches your nvim catppuccin installs
(elpaca kanagawa-theme)     ; matches your nvim kanagawa
(elpaca indent-bars)
(elpaca treesit-fold)       ; UFO equivalent on Emacs 30+ treesit
(elpaca electric-operator)

(defun astraea/ui//finish ()
  "Final UI pass, after all packages are loaded."
  (ignore-errors (load-theme astraea-theme t))
  (when (fboundp 'astraea//bind-core-keys)
    (astraea//bind-core-keys)
    (astraea/layers--run-config)))

;; convenient tree toggle bound to leader(defun astraea/toggle-file-tree ()
  "Toggle treemacs; fall back to dired."
  (interactive)
  (if (fboundp 'treemacs)
      (treemacs-select-window)
    (dired default-directory)))

(provide 'astraea-ui)
;;; astraea-ui.el ends here
