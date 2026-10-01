;;; early-init.el --- Astraea Emacs: early performance bootstrap -*- lexical-binding: t; -*-
;;
;; Astraea Emacs — the most feature-rich, most performant Emacs framework.
;; This file runs before the GUI and package system initialize. Everything
;; here is ordered for startup speed.

;; ── Defer GC until after startup ──────────────────────────────────────────
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defun astraea//restore-gc ()
  "Restore sane GC values once startup is finished."
  (run-with-idle-timer 5 nil
                       (lambda ()
                         (setq gc-cons-threshold 33554432 ; 32 MB
                               gc-cons-percentage 0.1)
                         (garbage-collect))))
(add-hook 'emacs-startup-hook #'astraea//restore-gc)

;; ── Native compilation ────────────────────────────────────────────────────
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-deferred-compilation t
        package-native-compile t))

;; ── Stop Emacs from touching the file system needlessly ───────────────────
(setq package-enable-at-startup nil      ; elpaca owns package init
      package-quickstart nil             ; elpaca builds its own cache
      load-prefer-newer t
      frame-inhibit-implied-resize t
      inhibit-default-init t)

;; File-name-handler tricks (big win on Windows / network shares)
(defvar astraea--default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(defun astraea//restore-file-name-handlers ()
  (setq file-name-handler-alist astraea--default-file-name-handler-alist))
(add-hook 'emacs-startup-hook #'astraea//restore-file-name-handlers)

;; ── Frame chrome: start clean, no flicker ─────────────────────────────────
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-buffer-menu t
      initial-scratch-message nil
      tool-bar-mode nil
      menu-bar-mode nil
      scroll-bar-mode nil
      default-frame-alist
      '((tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (background-color . "#1a1b26")
        (foreground-color . "#c0caf5")
        (alpha . 97)))

(provide 'early-init)
;;; early-init.el ends here
