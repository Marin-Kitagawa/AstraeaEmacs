;;; astraea-modal.el --- Switchable modal editing: evil + meow (zetta-style) -*- lexical-binding: t; -*-
;;
;; Astraea installs BOTH evil and meow when `astraea-modal-switchable' is
;; non-nil, and activates whichever `astraea-modal-style' selects.  Switch
;; at runtime with:
;;
;;   M-x astraea/set-modal-style RET evil RET
;;   M-x astraea/set-modal-style RET meow RET
;;
;; Both engines share the SAME leader map (`astraea-leader-map', bound to
;; SPC), so spacemacs/astronvim muscle memory works identically either way.

;; ── evil ──────────────────────────────────────────────────────────────────
(elpaca evil
  (setq evil-want-integration t
        evil-want-keybinding nil          ; we bind leaders ourselves
        evil-want-C-u-scroll t
        evil-want-C-i-jump t
        evil-respect-visual-line-mode t
        evil-undo-system 'undo-fu
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-v$-exwise-newline t
        evil-search-module 'evil-search
        evil-ex-search-persistent-highlight nil)
  (require 'evil)
  (when (fboundp 'evil-escape-mode)
    (evil-escape-mode 1)))

(elpaca evil-collection
  (evil-collection-init))

(elpaca evil-surround
  (global-evil-surround-mode 1))

(elpaca evil-numbers)   ; g C-a increments (flash.nvim-style numbering)

;; better-escape.nvim equivalent: "jk" exits insert state
(elpaca evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.15
        evil-escape-excluded-modes '(dired-mode)
        evil-escape-unordered-key-sequence t)
  (evil-escape-mode 1))

;; comment.nvim equivalent: gcc/gc operators
(elpaca evil-commentary
  (evil-commentary-mode 1))

;; ── meow ──────────────────────────────────────────────────────────────────
(elpaca meow
  (setq meow-keypad-leader-dispatch-leading t
        meow-use-clipboard t
        meow-selection-command-fallback
        '((meow-change . meow-change-char)
          (meow-save . meow-save-empty))))
;; meow works out of the box; craft a custom `meow-setup' in your user
;; config if you want a custom normal-state layout.

;; ── Engine selection ──────────────────────────────────────────────────────
(defvar astraea--evil-insert-map-backup nil
  "Pristine copy of `evil-insert-state-map', captured before hybrid
mode wipes it, so switching back to plain evil restores vim bindings.")

(defun astraea/modal--hybrid-insert (emacs-style)
  "Make evil insert state use native Emacs bindings when EMACS-STYLE
is non-nil; restore the default vim insert bindings otherwise.
ESC and evil-escape (jk) always return to normal state."
  (when (and (boundp 'evil-insert-state-map) (keymapp evil-insert-state-map))
    (unless astraea--evil-insert-map-backup
      (setq astraea--evil-insert-map-backup (copy-keymap evil-insert-state-map)))
    (if emacs-style
        (progn
          ;; wipe the vim insert bindings: unbound keys fall through to the
          ;; global Emacs map, which is exactly what hybrid wants
          (setcdr evil-insert-state-map nil)
          (define-key evil-insert-state-map [escape] #'evil-normal-state)
          (define-key evil-insert-state-map (kbd "C-[") #'evil-normal-state))
      (setcdr evil-insert-state-map (cdr astraea--evil-insert-map-backup)))))

(defun astraea/modal--activate (style)
  "Turn on modal engine STYLE, turning the other off."
  (interactive
   (list (intern (completing-read "Modal style: " '(evil meow hybrid)))))
  (cl-case style
    (meow
     (when (bound-and-true-p evil-mode)
       (evil-mode -1))
     (when (fboundp 'meow-global-mode)
       (meow-global-mode 1))
     (message "Astraea: meow mode"))
    ((evil hybrid)
     (when (bound-and-true-p meow-global-mode)
       (meow-global-mode -1))
     (when (fboundp 'evil-mode)
       (evil-mode 1))
     (astraea/modal--hybrid-insert (eq style 'hybrid))
     (message "Astraea: %s mode" style))
    (t (user-error "Unknown modal style: %s" style)))
  (setq astraea-modal-style style)
  (astraea//install-leader)
  style)

(defalias 'astraea/set-modal-style #'astraea/modal--activate)

(defun astraea/toggle-modal-style ()
  "Flip between evil and meow."
  (interactive)
  (astraea/modal--activate (if (eq astraea-modal-style 'meow) 'evil 'meow)))

(provide 'astraea-modal)
;;; astraea-modal.el ends here
