;;; astraea-keybinds.el --- Leader map, transient menus, which-key -*- lexical-binding: t; -*-
;;
;; One shared leader map bound to SPC in BOTH evil and meow states, so
;; switching engines never changes your muscle memory.  Layout mirrors
;; AstroNvim/spacemacs conventions:
;;
;;   SPC SPC  M-x        SPC b b  switch buffer    SPC f f  find file
;;   SPC w m  maximize   SPC g g  magit status     SPC e    diagnostics

(require 'transient)

(defvar astraea-leader-map (make-sparse-keymap)
  "Astraea's shared leader keymap, bound to SPC in every modal state.")

(defvar astraea-localleader-map (make-sparse-keymap)
  "Per-mode local leader keymap template.")

(defun astraea//install-leader ()
  "Bind `astraea-leader-map' to SPC in all active modal states."
  (astraea/after! evil
    (evil-global-set-key 'normal (kbd "SPC") astraea-leader-map)
    (evil-global-set-key 'visual (kbd "SPC") astraea-leader-map)
    (evil-global-set-key 'motion (kbd "SPC") astraea-leader-map))
  (astraea/after! meow
    (define-key meow-normal-state-keymap (kbd "SPC") astraea-leader-map)
    (define-key meow-motion-state-keymap (kbd "SPC") 'other-window)))

(defun astraea/leader-def (key def &rest bindings)
  "Define KEY→DEF in `astraea-leader-map', then BINDINGS pairs.
KEY is passed through `kbd'.  A single invalid binding logs a
message instead of aborting bootstrap."
  (while key
    (condition-case err
        (define-key astraea-leader-map (kbd key) def)
      (error (message "Astraea: leader binding %s failed: %s" key (error-message-string err))))
    (setq key (pop bindings) def (pop bindings))))

(defun astraea//bind-core-keys ()
  "Populate the leader map with framework-wide bindings."
  (astraea/leader-def
   ;; universal
   "SPC" #'execute-extended-command          ; astronvim: SPC SPC = M-x
   "u"   #'universal-argument
   "!"   #'shell-command
   "&"   #'async-shell-command
   ;; buffers (astronvim SPC b)
   "b b" #'consult-buffer
   "b B" #'consult-buffer-other-window
   "b d" #'kill-current-buffer
   "b D" #'kill-buffer
   "b i" #'ibuffer
   "b n" #'next-buffer
   "b p" #'previous-buffer
   "b R" #'revert-buffer
   "b s" #'save-buffer
   "b S" #'save-some-buffers
   "b u" #'vundo                      ; undotree.nvim equivalent
   "b [" #'previous-buffer
   "b ]" #'next-buffer
   ;; files (astronvim SPC f)
   "f f" #'find-file
   "f F" #'find-file-other-window
   "f r" #'consult-recent-file
   "f s" #'save-buffer
   "f S" #'write-file
   "f R" #'astraea/rename-file-and-buffer
   "f d" #'dired
   "f y" #'(lambda () (interactive) (kill-new (buffer-file-name)))
   "f e" #'(lambda () (interactive) (find-file astraea-user-directory))
   ;; search (flash.nvim / telescope live-grep equivalents)
   "s b" #'consult-line
   "s B" #'consult-line-multi
   "s g" #'consult-ripgrep
   "s f" #'consult-find
   "s i" #'consult-imenu
   "s I" #'consult-imenu-multi
   "s m" #'consult-mark
   "s o" #'consult-outline
   "s h" #'consult-history
   "s /" #'consult-ripgrep
   ;; jump (flash.nvim equivalent)
   "j j" #'avy-goto-char-timer
   "j l" #'avy-goto-line
   "j w" #'avy-goto-word-1
   ;; code (astronvim SPC c / SPC e)
   "c a" #'eglot-code-actions
   "c r" #'eglot-rename
   "c f" #'apheleia-format-buffer       ; conform.nvim equivalent
   "c d" #'eldoc
   "c i" #'eglot-find-implementation
   "e"   #'flymake-show-buffer-diagnostics
   "E"   #'flymake-show-project-diagnostics
   "x"   #'consult-flymake              ; quickfix equivalent
   ;; windows (astronvim SPC w)
   "w c" #'evil-window-delete
   "w v" #'evil-window-vsplit
   "w s" #'evil-window-split
   "w h" #'evil-window-left
   "w j" #'evil-window-down
   "w k" #'evil-window-up
   "w l" #'evil-window-right
   "w m" #'delete-other-windows
   "w =" #'balance-windows
   "w o" #'other-frame
   ;; tree & workspaces (neo-tree toggle / grapple menus)
   "f t" #'astraea/toggle-file-tree
   "T T" #'astraea/transient-workspace
   "T a" #'astraea/workspace-add
   "T s" #'astraea/workspace-switch
   "T m" #'menu-bar-mode
   "T t" #'tool-bar-mode
   "T F" #'astraea/cycle-fullscreen
   ;; toggles (spacemacs-style SPC t prefix)
   "t l" #'display-line-numbers-mode
   "t r" #'read-only-mode
   "t w" #'whitespace-mode
   "t v" #'visual-line-mode
   "t m" #'astraea/toggle-modal-style
   "t f" #'display-fill-column-indicator-mode
   "t h" #'hl-line-mode
   "t p" #'show-paren-mode
   "t C" #'rainbow-delimiters-mode
   "t o" #'hl-todo-mode
   "t s" #'flyspell-mode
   "t D" #'astraea/toggle-debug-on-error
   "t W" #'astraea/whitespace-cleanup
   "t g" #'golden-ratio-mode
   "t -" #'centered-cursor-mode
   "t V" #'volatile-highlights-mode
   "t n" #'astraea/toggle-line-numbers-style
   "t F" #'auto-fill-mode
   "t ." #'astraea/toggle-transient
   "t f" #'astraea/cycle-fullscreen
;; help (helpful-enhanced)
   "h f" #'helpful-function
   "h v" #'helpful-variable
   "h k" #'helpful-key
   "h c" #'helpful-command
   "h m" #'describe-mode
   "h h" #'(lambda () (interactive) (info-emacs-manual))
   "h L" #'(lambda () (interactive) (astraea/list-layers))
   ;; quit / restart (spacemacs SPC q)
   "q q" #'save-buffers-kill-terminal
   "q Q" #'kill-emacs
   "q s" #'save-buffers-kill-emacs
   "q f" #'delete-frame
   "q r" #'restart-emacs
   ;; text utilities (spacemacs SPC x)
   "x a" #'align-regexp
   "x d" #'astraea/duplicate-line-or-region
   "x l" #'sort-lines
   "x u" #'astraea/deduplicate-lines
   "x c" #'count-words
   "x e" #'er/expand-region
   "x i" #'iedit-mode
   "x m e" #'mc/edit-lines
   "x m n" #'mc/mark-next-like-this
   "x m a" #'mc/mark-all-like-this
   "x r" #'astraea/rotate-windows
   ;; windows extras
   "w u" #'winner-undo
   "w U" #'winner-redo
   "w a" #'ace-window
   "w r" #'astraea/rotate-windows
   ;; notes & research extras
   "n j" #'org-journal-new-entry
   "n P" #'org-present
   "n w" #'astraea/research-menu))

;; ── Transient menus (spacemacs-style popups with discoverability) ────────
(transient-define-prefix astraea/transient-git ()
  "Astraea git menu."
  [["Status"
    ("s" "Status" magit-status)
    ("b" "Branches" magit-branch-list)
    ("l" "Log" magit-log-current)
    ("c" "Commit" magit-commit-create)]
   ["Diff"
    ("d" "Diff" magit-diff-unstaged)
    ("D" "Diff staged" magit-diff-staged)
    ("t" "Timemachine" git-timemachine)]])

(transient-define-prefix astraea/transient-buffer ()
  "Astraea buffer menu."
  [["Buffers"
    ("b" "Switch" consult-buffer)
    ("k" "Kill" kill-current-buffer)
    ("r" "Revert" revert-buffer)
    ("s" "Save" save-buffer)]
   ["Windows"
    ("v" "Vsplit" evil-window-vsplit)
    ("s" "Split" evil-window-split)
    ("m" "Maximize" delete-other-windows)]])

(transient-define-prefix astraea/transient-workspace ()
  "Astraea workspace menu (grapple.nvim equivalent)."
  [["Workspaces"
    ("a" "Add" tab-bar-tab-add)
    ("c" "Close" tab-bar-close-tab)
    ("n" "Next" tab-next)
    ("p" "Previous" tab-previous)
    ("j" "Jump" tab-bar-switch-to-tab)]])

;; which-key: every prefix in the leader map gets a discoverable menu
(elpaca which-key
  (which-key-mode 1)
  (setq which-key-use-C-h-commands t
        which-key-show-remaining-keys t))

(provide 'astraea-keybinds)
;;; astraea-keybinds.el ends here
