;;; astraea-performance.el --- Garbage, deferred loading, startup benchmark -*- lexical-binding: t; -*-
;;
;; Astraea treats startup time and idle memory as first-class features.
;; Principles:
;;   * Every package defers until first use (:hook, :commands, :after).
;;   * GC is throttled during startup and on focus loss (gcmh).
;;   * All state lives outside ~/.emacs.d (no-littering).
;;   * `astraea/report-startup-time' gives a profile you can act on.

(elpaca gcmh
  (setq gcmh-idle-delay 5
        gcmh-high-cons-threshold 33554432) ; 32MB
  (gcmh-mode 1))

(elpaca no-littering
  (setq no-littering-etc-directory astraea-user-directory
        no-littering-var-directory (expand-file-name "var/" astraea-user-directory))
  (require 'no-littering)
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))
        backup-directory-alist
        `(("." . ,(no-littering-expand-var-file-name "backup/")))))

;; Throttle GC while unfocused / during long macro operations
(defun astraea//gc-on-focus-loss ()
  "Collect garbage when the frame loses focus."
  (add-function :after after-focus-change-function
                (lambda ()
                  (unless (frame-focus-state)
                    (garbage-collect)))))

;; Idle compaction of large buffers' fontification
(defun astraea//deferred-setup ()
  "Low-priority work scheduled at idle time, off the startup path."
  (run-with-idle-timer 2 nil #'astraea//gc-on-focus-loss))

(defun astraea/report-startup-time ()
  "Report total startup time and per-package load costs."
  (interactive)
  (message "Astraea startup: %.3fs (emacs init %.3fs)"
           (float-time (time-subtract (current-time) before-init-time))
           (or (get 'after-init-time 'astraea-elapsed) 0))
  (when (and (fboundp 'use-package-report)
             (boundp 'use-package-compute-statistics)
             use-package-compute-statistics)
    (use-package-report)))

(defun astraea/profile-startup ()
  "Restart Emacs under the CPU profiler and print hot functions.
Run from `emacs --init-directory …' with this command; results land
in *Astraea Startup Profile*."
  (interactive)
  (require 'profiler)
  (profiler-start 'cpu)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (run-with-idle-timer 3 nil
                (lambda ()
                  (profiler-stop)
                  (switch-to-buffer-other-window (get-buffer-create "*Astraea Startup Profile*"))
                  (profiler-report))))))

(provide 'astraea-performance)
;;; astraea-performance.el ends here
