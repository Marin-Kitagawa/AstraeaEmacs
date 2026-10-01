;;; astraea-toggles.el --- spacemacs-style toggle system -*- lexical-binding: t; -*-
;;
;; Port of spacemacs `spacemacs|add-toggle': each toggle generates
;; `astraea/toggle-NAME', `-on', `-off' and `-status' functions, is bound
;; under `SPC t' (buffer-local) / `SPC T' (frame-global) and shows its state
;; in the minibuffer.

(defmacro astraea|add-toggle (name &rest props)
  "Define toggle NAME from a plist: :mode, :status, :on, :off,
:documentation, :key (SPC t binding), :global-key (SPC T binding).
When :mode is given, :status/:on/:off default to that minor mode."
  (let* ((mode (plist-get props :mode))
         (status (or (plist-get props :status)
                     (when mode `(bound-and-true-p ,mode))))
         (on (or (plist-get props :on) (when mode `(,mode 1))))
         (off (or (plist-get props :off) (when mode `(,mode -1))))
         (doc (or (plist-get props :documentation) ""))
         (key (plist-get props :key))
         (gkey (plist-get props :global-key))
         (fname (intern (format "astraea/toggle-%s" name)))
         (on-name (intern (format "astraea/toggle-%s-on" name)))
         (off-name (intern (format "astraea/toggle-%s-off" name)))
         (status-name (intern (format "astraea/toggle-%s-status" name))))
    `(progn
       (defun ,on-name () ,(format "Enable %s." name) (interactive) ,on)
       (defun ,off-name () ,(format "Disable %s." name) (interactive) ,off)
       (defun ,status-name () ,(format "Non-nil when %s is active." name) ,status)
       (defun ,fname ()
         ,(format "Toggle %s.\n\n%s" name doc)
         (interactive)
         (if ,status ,off-name ,on-name)
         ,(when (or key gkey)
            `(message "%s: %s" ,(capitalize (symbol-name name))
                      (if ,status "enabled" "disabled"))))
       ,@(when key
           `((astraea/after! astraea-keybinds
               (astraea/leader-def ,key #',fname))))
       ,@(when gkey
           `((astraea/after! astraea-keybinds
               (astraea/leader-def ,gkey #',fname)))))))

;;; ── buffer-local toggles (SPC t) ──────────────────────────────────────

(astraea|add-toggle truncate-lines
  :status truncate-lines
  :on (setq truncate-lines t)
  :off (setq truncate-lines nil)
  :documentation "Wrap vs. truncate long lines.")

(astraea|add-toggle auto-fill
  :mode auto-fill-function
  :documentation "Break lines automatically at `fill-column'.")

(astraea|add-toggle fill-column-indicator
  :mode display-fill-column-indicator-mode
  :documentation "Vertical line at `fill-column'.")

(astraea|add-toggle highlight-line
  :mode hl-line-mode
  :documentation "Highlight the current line.")

(astraea|add-toggle highlight-parentheses
  :mode show-paren-mode
  :documentation "Highlight matching parentheses.")

(astraea|add-toggle rainbow-delimiters
  :mode rainbow-delimiters-mode
  :documentation "Color-nest parentheses by depth.")

(astraea|add-toggle highlight-todos
  :mode hl-todo-mode
  :documentation "Highlight TODO/FIXME/XXX keywords.")

(astraea|add-toggle volatile-highlights
  :mode volatile-highlights-mode
  :documentation "Highlight yanked/undo regions.")

(astraea|add-toggle golden-ratio
  :mode golden-ratio-mode
  :documentation "Automatically resize the focused window.")

(astraea|add-toggle centered-point
  :mode centered-cursor-mode
  :documentation "Keep the cursor vertically centered.")

(astraea|add-toggle flyspell
  :mode flyspell-mode
  :documentation "On-the-fly spell checking.")

(astraea|add-toggle debug-on-error
  :status debug-on-error
  :on (setq debug-on-error t)
  :off (setq debug-on-error nil)
  :documentation "Enter the debugger when an error is signaled.")

(astraea|add-toggle font-lock
  :mode font-lock-mode
  :documentation "Syntax highlighting.")

;;; ── commands (not toggles) under SPC t ───────────────────────────────

(defun astraea/whitespace-cleanup ()
  "Delete all trailing whitespace and reindent (S-TAB style)."
  (interactive)
  (whitespace-cleanup)
  (message "Whitespace cleaned."))

(defun astraea/toggle-line-numbers-style (style)
  "Set `display-line-numbers-type' to STYLE and refresh."
  (interactive
   (list (intern (completing-read "Line numbers: " '(relative absolute visual nil)))))
  (setq display-line-numbers-type style)
  (if (bound-and-true-p display-line-numbers-mode)
      (setq-local display-line-numbers style)
    (display-line-numbers-mode 1))
  (message "Line numbers: %s" (or style "off")))

;;; ── frame/global toggles (SPC T) ─────────────────────────────────────

;; packages backing the toggles above
(elpaca rainbow-delimiters)
(elpaca hl-todo)
(elpaca volatile-highlights)
(elpaca golden-ratio
  (setq golden-ratio-auto-scale t))
(elpaca centered-cursor-mode)
(elpaca restart-emacs)

(astraea|add-toggle menu-bar
  :global-key "T m"
  :status menu-bar-mode
  :on (menu-bar-mode 1)
  :off (menu-bar-mode -1)
  :documentation "Toggle the menu bar.")

(astraea|add-toggle tool-bar
  :global-key "T t"
  :status (and (boundp 'tool-bar-mode) tool-bar-mode)
  :on (tool-bar-mode 1)
  :off (tool-bar-mode -1)
  :documentation "Toggle the tool bar.")

(provide 'astraea-toggles)
;;; astraea-toggles.el ends here
