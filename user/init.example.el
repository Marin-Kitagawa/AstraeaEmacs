;;; init.example.el --- Astraea user configuration template -*- lexical-binding: t; -*-
;;
;; This file was seeded to ~/.astraea.d/init.el.  Everything Astraea offers
;; is configured from here — the framework itself stays untouched, so
;; upgrades never clobber your setup (spacemacs/astronvim philosophy).

;; ── 1. Modal style ───────────────────────────────────────────────────────
;; 'evil (vim), 'meow, or 'hybrid.  Switch any time with M-x astraea/set-modal-style
(setq astraea-modal-style 'evil)

;; ── 2. Backends ──────────────────────────────────────────────────────────
(setq astraea-lsp-backend 'eglot          ; or 'lsp-mode
      astraea-completion-backend 'corfu   ; or 'company
      astraea-theme 'catppuccin           ; catppuccin, kanagawa, doom-one…
      astraea-dashboard-enabled t
      astraea-startup-benchmark t)        ; print startup time when ready

;; ── 3. Leader key ────────────────────────────────────────────────────────
(setq astraea-leader-key "SPC"
      astraea-localleader-key ",")

;; ── 4. Enable layers ────────────────────────────────────────────────────
;; File layers ship in layers/:
(astraea/enable-layer '+tools/git)
(astraea/enable-layer '+lang/emacs-lisp)
(astraea/enable-layer '+lang/python)

;; Inline layers are declared right here:
(astraea-layer! +personal/writeroom
  :packages (writeroom-mode)
  :init (elpaca writeroom-mode)
  :config
  (progn
    (setq writeroom-width 100)
    (define-key global-map [?\s-\d] #'writeroom-mode)))

;; ── 5. Personal keybinds ────────────────────────────────────────────────
(astraea/leader-def
 "f p" #'(lambda () (interactive) (find-file "~/.astraea.d/init.el")))

;; ── 6. Anything else — plain Emacs Lisp ─────────────────────────────────
;; (setq org-cite-global-bibliography '("~/my-real-zotero.bib"))

;;; Bootstrap finishes here — keep this line LAST:
(astraea/init)
;;; init.example.el ends here
