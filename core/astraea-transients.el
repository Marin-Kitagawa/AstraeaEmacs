;;; astraea-transients.el --- spacemacs-style transient states -*- lexical-binding: t; -*-
;;
;; Port of spacemacs transient states on top of the built-in `transient':
;; persistent popups where single keys repeat (resize, scale, toggles,
;; buffer ops).  Blue-ish keys exit, the rest keep the state open.

(require 'transient)

;; ── window transient state (SPC w .) ──────────────────────────────────

(defun astraea/w--left () (interactive) (windmove-left))
(defun astraea/w--right () (interactive) (windmove-right))
(defun astraea/w--up () (interactive) (windmove-up))
(defun astraea/w--down () (interactive) (windmove-down))
(defun astraea/w--shrink-h () (interactive) (shrink-window-horizontally 4))
(defun astraea/w--enlarge-h () (interactive) (enlarge-window-horizontally 4))
(defun astraea/w--shrink-v () (interactive) (shrink-window 4))
(defun astraea/w--enlarge-v () (interactive) (enlarge-window 4))
(defun astraea/w--rotate () (interactive)
  (if-let* ((frames (frame-list)))
      (rotate-windows-if-available)))

(transient-define-prefix astraea/window-transient ()
  "Window transient state (spacemacs `w.')."
  [["Move"
    ("h" "←" astraea/w--left :transient t)
    ("j" "↓" astraea/w--down :transient t)
    ("k" "↑" astraea/w--up :transient t)
    ("l" "→" astraea/w--right :transient t)]
   ["Resize"
    ("H" "wider" astraea/w--enlarge-h :transient t)
    ("L" "narrower" astraea/w--shrink-h :transient t)
    ("J" "taller" astraea/w--enlarge-v :transient t)
    ("K" "shorter" astraea/w--shrink-v :transient t)
    ("=" "balance" balance-windows :transient t)]
   ["Split / close"
    ("v" "vsplit" split-window-right :transient t)
    ("s" "split" split-window-below :transient t)
    ("d" "delete" delete-window :transient t)
    ("m" "maximize" delete-other-windows :transient t)]
   ["Layout"
    ("u" "winner-undo" winner-undo :transient t)
    ("C-r" "winner-redo" winner-redo :transient t)
    ("a" "ace-window" ace-window :transient t)
    ("q" "quit" transient-quit-one)]])

;; ── text scale transient state (SPC z x) ─────────────────────────────

(transient-define-prefix astraea/scale-transient ()
  "Font scale transient state (spacemacs `z x')."
  [["Scale"
    ("+" "bigger" (lambda () (interactive) (text-scale-increase 1)) :transient t)
    ("-" "smaller" (lambda () (interactive) (text-scale-decrease 1)) :transient t)
    ("0" "reset" (lambda () (interactive) (text-scale-set 0)) :transient t)
    ("q" "quit" transient-quit-one)]])

;; ── toggle transient state (SPC t t) ─────────────────────────────────

(transient-define-prefix astraea/toggle-transient ()
  "Quick toggles, staying open."
  [["Buffer"
    ("l" "line numbers" display-line-numbers-mode :transient t)
    ("w" "whitespace" whitespace-mode :transient t)
    ("v" "visual line" visual-line-mode :transient t)
    ("f" "fill column" display-fill-column-indicator-mode :transient t)
    ("h" "highlight line" hl-line-mode :transient t)]
   ["Global"
    ("m" "modal style" astraea/toggle-modal-style :transient t)
    ("D" "debug on error" astraea/toggle-debug-on-error :transient t)
    ("d" "dashboard" astraea/toggle-dashboard :transient t)
    ("q" "quit" transient-quit-one)]])

(defun astraea/toggle-dashboard ()
  "Show or refresh the dashboard buffer."
  (interactive)
  (if (get-buffer dashboard-buffer-name)
      (switch-to-buffer dashboard-buffer-name)
    (dashboard-open)))

;; ── restart (spacemacs SPC q group) — restart-emacs queued in toggles ─
(with-eval-after-load 'astraea-keybinds
  (astraea/leader-def
   "q q" #'save-buffers-kill-terminal
   "q Q" #'kill-emacs
   "q s" #'save-buffers-kill-emacs
   "q f" #'delete-frame
   "q r" #'restart-emacs))

;; ── binding entry points ─────────────────────────────────────────────
(with-eval-after-load 'astraea-keybinds
  (astraea/leader-def
   "w ." #'astraea/window-transient
   "z x" #'astraea/scale-transient
   "t t" #'astraea/toggle-transient))

(provide 'astraea-transients)
;;; astraea-transients.el ends here
