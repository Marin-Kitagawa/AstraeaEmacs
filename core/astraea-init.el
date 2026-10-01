;;; astraea-init.el --- Astraea bootstrap: elpaca, core modules, user config -*- lexical-binding: t; -*-
;;
;; Load order:
;;   1. elpaca (async package manager — parallel clone/build, native-comp)
;;   2. core modules (lib, performance, defaults, layers, modal, keybinds, UI…)
;;   3. user config  ~/.astraea.d/init.el  (or seeded example on first run)
;;   4. (astraea/init) at the end of the user config enables layers and runs.

(require 'cl-lib)
(require 'map)

(defconst astraea-version "0.1.0"
  "Current Astraea Emacs version.")

;; ── Elpaca bootstrap (async, parallel-capable package manager) ───────────
(defvar elpaca-installer-version 0.8)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order
  '(elpaca :repo "https://github.com/progfolio/elpaca.git"
           :ref nil :depth 1 :wait t
           :files (:defaults "elpaca-test.el" (:exclude "extensions"))
           :build (:not elpaca--activate-package)))
(when-let* ((repo (expand-file-name "elpaca/" elpaca-repos-directory))
            (build (expand-file-name "elpaca/" elpaca-builds-directory))
            (order (cdr elpaca-order))
            ((add-to-list 'load-path (if (file-exists-p build) build repo))))
  (unless (file-exists-p build)
    (require 'url)
    (let ((buffer (url-retrieve-synchronously
                   (format "https://github.com/progfolio/elpaca/archive/refs/heads/%s.zip" (alist-get :ref order 'main))
                   nil nil 30)))
      (unwind-protect
          (let ((default-directory elpaca-repos-directory))
            (when buffer (with-current-buffer buffer (elpaca-unpack (alist-get :ref order 'main))))))
        (when buffer (kill-buffer buffer)))))
(when-let* ((buffer (find-buffer-visiting (expand-file-name "elpaca-test.el" repo))))
  (load buffer))
(require 'elpaca-autoloads nil t)
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; use-package integration — every use-package form becomes an elpaca order
(elpaca elpaca-use-package
  (elpaca-use-package-mode)
  (setq use-package-always-ensure t
        use-package-expand-minimally t))

;; ── Core modules ──────────────────────────────────────────────────────────
(require 'astraea-variables)
(require 'astraea-lib)
(require 'astraea-performance)
(require 'astraea-defaults)
(require 'astraea-layers)
(require 'astraea-modal)
(require 'astraea-keybinds)
(require 'astraea-ui)
(require 'astraea-completion)
(require 'astraea-ide)
(require 'astraea-org)
(require 'astraea-project)

;; ── User configuration ────────────────────────────────────────────────────
(defun astraea//seed-user-config ()
  "Seed ~/.astraea.d/init.el from the bundled example on first run."
  (let* ((dir astraea-user-directory)
         (init (expand-file-name "init.el" dir)))
    (unless (file-exists-p init)
      (make-directory dir t)
      (copy-file (expand-file-name "user/init.example.el" user-emacs-directory) init t)
      (message "Astraea: seeded user config at %s" init))
    init))

(defun astraea/load-user-config ()
  "Load the user's init file, seeding it first if necessary."
  (let ((user-file (or (getenv "ASTRAEA_USER_INIT")
                       (astraea//seed-user-config))))
    (load user-file nil 'nomessage)))

;; ── Finish bootstrap ──────────────────────────────────────────────────────
(defun astraea/init ()
  "Complete Astraea bootstrap. Call this at the END of your user init file."
  (interactive)
  (astraea/layers--enable-all)
  (astraea//install-leader)
  (run-hooks 'astraea-pre-init-hook)
  (elpaca-process-queues)
  (add-hook 'elpaca-after-init-hook #'astraea//finish-init))

(defun astraea//finish-init ()
  "Post-package-load finalization."
  (astraea/modal--activate astraea-modal-style)
  (astraea/ui//finish)
  (run-hooks 'astraea-after-init-hook)
  (when astraea-startup-benchmark
    (astraea/report-startup-time))
  (message "Astraea %s ready in %.2fs with %d layers (%s modal)"
           astraea-version
           (float-time (time-subtract (current-time) before-init-time))
           (length astraea--enabled-layers)
           astraea-modal-style))

(provide 'astraea-init)
;;; astraea-init.el ends here
