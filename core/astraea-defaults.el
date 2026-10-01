;;; astraea-defaults.el --- Sane, portable defaults -*- lexical-binding: t; -*-
;;
;; Mirrors the spirit of the user's AstroNvim `polish.lua` — including a
;; UTF-8 PowerShell shell on Windows — plus editor quality-of-life defaults.

;; ── Encoding ──────────────────────────────────────────────────────────────
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8-unix)
(when (eq system-type 'windows-nt)
  (setq w32-get-true-file-attributes nil)) ; faster file ops on Windows

;; ── Windows shell: pwsh with UTF-8 (mirrors nvim polish.lua) ─────────────
(when (eq system-type 'windows-nt)
  (setq shell-file-name "pwsh"
        explicit-shell-file-name "pwsh"
        shell-command-switch "-c"
        explicit-pwsh-args '("-NoLogo" "-NoProfile" "-ExecutionPolicy" "RemoteSigned"
                             "-Command" "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;")
        shell-file-name-warning nil))

;; ── Editing ───────────────────────────────────────────────────────────────
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 100
              truncate-lines nil)
(setq kill-whole-line t
      confirm-kill-processes nil
      create-lockfiles nil              ; perf; no-littering handles state
      delete-selection-mode t
      recentf-mode 1
      save-place-mode 1
      savehist-mode 1
      history-length 1000
      pixel-scroll-precision-mode t     ; buttery scrolling (nvim smooth scroll)
      scroll-conservatively 101
      scroll-margin 8                   ; scrolloff equivalent
      hscroll-margin 8
      next-screen-context-lines 8
      display-line-numbers-type 'relative ; hybrid relative numbers
      show-paren-delay 0
      which-key-idle-delay 0.3          ; snappy which-key
      use-short-answers t
      ring-bell-function 'ignore
      auto-revert-use-notify t
      global-auto-revert-mode t
      completion-cycle-threshold 3
      vc-follow-symlinks t)

(setq uniquify-buffer-name-style 'forward)

;; Undo: persistent, granular, with vundo tree visualization
(elpaca undo-fu
  (global-set-key [remap undo] #'undo-fu-only-undo)
  (global-set-key [remap undo-redo] #'undo-fu-only-redo))
(elpaca undo-fu-session                ; undo history survives restarts
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-take\\'"))
  (undo-fu-session-global-mode 1))
(elpaca vundo)  ; SPC b u — undo tree (undotree.nvim equivalent)

;; Server: emacsclient support (skip in batch/non-GUI sessions)
(require 'server)
(unless (or noninteractive (server-running-p)) (server-start))

(provide 'astraea-defaults)
;;; astraea-defaults.el ends here
