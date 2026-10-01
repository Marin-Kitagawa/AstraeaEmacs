;;; init.example.el --- Astraea user configuration template -*- lexical-binding: t; -*-
;;
;; This file was seeded to ~/.astraea.d/init.el.  Everything Astraea offers
;; is configured from here â€” the framework itself stays untouched, so
;; upgrades never clobber your setup (spacemacs/astronvim philosophy).

;; â”€â”€ 1. Modal style â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
;; 'evil (vim), 'meow, or 'hybrid.  Switch any time with M-x astraea/set-modal-style
(setq astraea-modal-style 'evil)

;; â”€â”€ 2. Backends â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
(setq astraea-lsp-backend 'eglot          ; or 'lsp-mode
      astraea-completion-backend 'corfu   ; or 'company
      astraea-theme 'ef-summer            ; pastel pink â€” also: sakura,
                                          ; pink-bliss-uwu, moe-light,
                                          ; cherry-blossom, catppuccinâ€¦
      astraea-dashboard-enabled t
      astraea-startup-benchmark t)        ; print startup time when ready

;; â”€â”€ 3. Leader key â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
(setq astraea-leader-key "SPC"
      astraea-localleader-key ",")

;; â”€â”€ 4. Enable layers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
;; File layers ship in layers/:
(astraea/enable-layer '+tools/git)
(astraea/enable-layer '+lang/emacs-lisp)
(astraea/enable-layer '+lang/python)
(astraea/enable-layer '+tools/docker)
(astraea/enable-layer '+readers/rss-epub)

;; Inline layers are declared right here:
(astraea-layer! +personal/writeroom
  :packages (writeroom-mode)
  :init (elpaca writeroom-mode)
  :config
  (progn
    (setq writeroom-width 100)
    (define-key global-map [?\s-\d] #'writeroom-mode)))

;; â”€â”€ 5. Personal keybinds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
(astraea/leader-def
 "f p" #'(lambda () (interactive) (find-file "~/.astraea.d/init.el")))

;; â”€â”€ 6. Opt-in integrations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
;; (setq astraea-copilot-enabled t)            ; needs copilot-language-server (npm)
;; (setq astraea-discord-presence-enabled t)   ; Discord rich presence (elcord)
;; (setq astraea-wakatime-enabled t)           ; needs wakatime-cli on PATH

;; â”€â”€ 7. Anything else â€” plain Emacs Lisp â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
;; (setq org-cite-global-bibliography '("~/my-real-zotero.bib"))

;;; Bootstrap finishes here â€” keep this line LAST:
(astraea/init)
;;; init.example.el ends here
