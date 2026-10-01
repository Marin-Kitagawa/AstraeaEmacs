;;; astraea-completion.el --- Vertico/Consult + Corfu completion stack -*- lexical-binding: t; -*-
;;
;; The blink.cmp / coq_nvim equivalent for Emacs: two complementary stacks.
;;   Minibuffer : vertico + orderless + marginalia + consult + embark
;;   In-buffer  : corfu + cape + kind-icon (default)  — or company
;; Both are chosen by `astraea-completion-backend'.  Everything defers to
;; the first completion attempt, so startup cost is ~zero.

;; ── Minibuffer completion ────────────────────────────────────────────────
(elpaca vertico
  (setq vertico-count 17
        vertico-resize t
        vertico-cycle t)
  (vertico-mode 1)
  (vertico-mouse-mode 1))

(elpaca orderless
  (setq completion-styles '(orderless basic)
        completion-category-overrides
        '((file (styles basic partial-completion)))))

(elpaca marginalia
  (marginalia-mode 1))

(elpaca consult)
(elpaca embark
  (setq prefix-help-command #'embark-prefix-help-command))
(elpaca embark-consult)
(elpaca consult-dir)
(elpaca nerd-icons-completion)

(with-eval-after-load 'vertico
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous))

;; ── In-buffer completion: corfu (blink.cmp equivalent) ──────────────────
(elpaca corfu
  (setq corfu-cycle t
        corfu-preview-current nil
        corfu-auto t
        corfu-auto-delay 0.15        ; blink.cmp-like latency
        corfu-auto-prefix 2
        corfu-quit-no-match 'separator
        corfu-popupinfo-delay '(0.5 . 0.2))
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(elpaca cape
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-history))

;; company alternative (select with `astraea-completion-backend')
(elpaca company)

;; ── snippets (LuaSnip equivalent) ────────────────────────────────────────
(elpaca yasnippet
  (yas-global-mode 1))
(elpaca yasnippet-snippets)         ; big snippet collection

;; ── terminal corfu fallback ─────────────────────────────────────────────
(elpaca corfu-terminal
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

(provide 'astraea-completion)
;;; astraea-completion.el ends here
