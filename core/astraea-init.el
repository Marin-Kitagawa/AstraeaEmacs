;;; astraea-init.el --- Astraea bootstrap: elpaca, core modules, user config -*- lexical-binding: t; -*-
;;
;; Load order:
;;   1. elpaca (async package manager — parallel clone/build, native-comp)
;;   2. core modules (lib, performance, defaults, layers, modal, keybinds, UI…)
;;   3. user config  ~/.astraea.d/init.el  (or seeded example on first run)
;;   4. (astraea/init) at the end of the user config enables layers and runs.

(require 'cl-lib)
(require 'map)

(defconst astraea-version "0.4.0"
  "Current Astraea Emacs version.")

(defvar astraea--ci nil
  "When non-nil (CI smoke tests), `astraea/init' skips package queue
processing and finalization — only module loading is validated.
Defined early so test drivers can set it before anything loads.")

;; ── Elpaca bootstrap (async, parallel-capable package manager) ───────────
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory)
  "Legacy elpaca checkout location (pre-rename).")
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory)
  "Elpaca's package-source directory.  Defined here so the value
survives loading elpaca.el (defvar won't override), and so the
bootstrap clones into the layout elpaca actually reads — newer
elpaca renamed repos/ to sources/.")
(defvar elpaca-order
  '(elpaca :repo "https://github.com/progfolio/elpaca.git"
           :ref nil :depth 1 :inherit ignore
           :files (:defaults "elpaca-test.el" (:exclude "extensions"))
           :build (:not elpaca-activate)))

(defun astraea//bootstrap-elpaca ()
  "Clone elpaca via git if absent and put it on `load-path'."
  (let* ((repo (expand-file-name "elpaca/" elpaca-sources-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (legacy (expand-file-name "elpaca/" elpaca-repos-directory))
         (source (cond
                  ;; prefer a complete build (has autoloads or the library)
                  ((or (file-exists-p (expand-file-name "elpaca-autoloads.el" build))
                       (file-exists-p (expand-file-name "elpaca.el" build)))
                   build)
                  ((file-exists-p (expand-file-name "elpaca.el" repo)) repo)
                  ((file-exists-p (expand-file-name "elpaca.el" legacy)) legacy)
                  (t repo))))
    (unless (or (file-exists-p repo) (file-exists-p legacy))
      (make-directory elpaca-sources-directory t)
      (let ((log (get-buffer-create "*elpaca-bootstrap*")))
        (unless (zerop (call-process "git" nil log t
                                     "clone" "--filter=blob:none"
                                     "https://github.com/progfolio/elpaca.git"
                                     repo))
          (with-current-buffer log
            (user-error "Astraea: failed to clone elpaca; see *elpaca-bootstrap*: %s"
                        (buffer-string))))))
    (add-to-list 'load-path source)
    ;; Windows cannot create symlinks without Developer Mode/admin: the
    ;; source repo does not ship generated autoloads, so load every
    ;; library explicitly in dependency order.  After elpaca builds
    ;; itself, builds/elpaca has autoloads and we use those instead.
    (if (file-exists-p (expand-file-name "elpaca-autoloads.el" source))
        (require 'elpaca-autoloads)
      (require 'elpaca)                 ; pulls elpaca-process
      (dolist (lib '(elpaca-ui elpaca-file elpaca-git elpaca-info elpaca-log
                     elpaca-manager elpaca-menu-elpa elpaca-menu-melpa
                     elpaca-menu-org elpaca-tar))
        (require lib)))))

;; ── Elpaca bootstrap (async, parallel-capable package manager) ───────────
(astraea//bootstrap-elpaca)
;; Windows cannot create symlinks without Developer Mode/admin: copy instead.
;; Also cap concurrent git clones — Git for Windows can crash with an
;; access violation under heavy parallel load.
(when (eq system-type 'windows-nt)
  (elpaca-no-symlink-mode 1)
  (setq elpaca-queue-limit 4))
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
;; Register the file layers shipped in layers/ so the user config can
;; enable them by symbol.  Must run before the user config is loaded.
(astraea/layers--discover-file-layers)
(require 'astraea-modal)
(require 'astraea-keybinds)
(require 'astraea-ui)
(require 'astraea-appearance)
(require 'astraea-completion)
(require 'astraea-ide)
(require 'astraea-org)
(require 'astraea-project)
(require 'astraea-integrations)
(require 'astraea-toggles)
(require 'astraea-transients)
(require 'astraea-editing)
(require 'astraea-scimax)
(require 'astraea-workspaces)
(require 'astraea-present)
(require 'astraea-manuscript)
(require 'astraea-fun)
(require 'astraea-lang-registry)

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
(defvar astraea--init-finished nil
  "Non-nil once `astraea//finish-init' has run (it runs exactly once).")

(defun astraea//all-orders-terminal-p ()
  "Return non-nil if every elpaca order is finished or failed."
  (and (boundp 'elpaca--queues)
       (cl-loop for q in (reverse elpaca--queues)
                always (cl-loop for (_ . e) in (elpaca-q<-elpacas q)
                                always (memq (elpaca<-status e)
                                             '(finished failed))))))

(defun astraea/init ()
  "Complete Astraea bootstrap. Call this at the END of your user init file."
  (interactive)
  (astraea/layers--enable-all)
  (if astraea--ci
      (message "CI: astraea/init registered (package processing skipped)")
    (astraea//install-leader)
    (run-hooks 'astraea-pre-init-hook)
    (elpaca-process-queues)
    ;; Finish when elpaca's post-init hook fires (async first install)…
    (add-hook 'elpaca-after-init-hook #'astraea//finish-init)
    (add-hook 'elpaca--post-queues-hook #'astraea//finish-init)
    ;; …or immediately when every order was already built (warm start).
    (if (astraea//all-orders-terminal-p)
        (astraea//finish-init)
      ;; Fallback: idle timer in case elpaca's hook conditions never align.
      (run-with-idle-timer 30 nil #'astraea//finish-init))))

(defun astraea//finish-init ()
  "Finalize Astraea: theme, leader keys, layer configs.  Runs once."
  (unless astraea--init-finished
    (setq astraea--init-finished t)
    ;; font: apply and persist across frames (batch sessions have no real frame)
    (when (and astraea-font (display-graphic-p))
      (let ((spec (format "%s-%s" astraea-font astraea-font-size)))
        (set-frame-font spec nil t)
        (add-to-list 'default-frame-alist (cons 'font spec))))
    ;; modal and UI are independent: one failing must not break the other
    (condition-case err
        (astraea/modal--activate astraea-modal-style)
      (error (message "Astraea: modal setup failed: %s"
                      (error-message-string err))))
    (condition-case err
        (astraea/ui//finish)
      (error (message "Astraea: UI setup failed: %s"
                      (error-message-string err))))
    (run-hooks 'astraea-after-init-hook)
    (when astraea-startup-benchmark
      (astraea/report-startup-time))
    (message "Astraea %s ready in %.2fs with %d layers (%s modal)"
             astraea-version
             (float-time (time-subtract (current-time) before-init-time))
             (length astraea--enabled-layers)
             astraea-modal-style)))

;; ── Package upgrades (topgrade-friendly) ─────────────────────────────────
;; package.el doesn't own Astraea's packages — elpaca does.  Route
;; `package-upgrade-all' (what topgrade calls) through elpaca instead of
;; letting it churn on an unrelated package.el database.  package.el is
;; loaded eagerly so topgrade's (featurep 'package) check succeeds.
(defun astraea//elpaca-done-count ()
  "Number of elpaca orders which have finished or failed."
  (cl-loop for (_ . e) in (elpaca--queued)
           count (memq (elpaca<-status e) '(finished failed))))

(defun astraea//elpaca-wait (label)
  "Wait for elpaca to finish, reporting progress for LABEL every 5s."
  (let* ((total (length (elpaca--queued)))
         (timer (run-with-timer
                 5 5
                 (lambda ()
                   (message "Astraea: %s - %d of %d packages done"
                            label (astraea//elpaca-done-count) total)))))
    (unwind-protect (elpaca-wait)
      (cancel-timer timer)
      (message "Astraea: %s - finished (%d of %d packages)"
               label (astraea//elpaca-done-count) total))))

(defun astraea//git-behind-p (dir)
  "Non-nil when DIR's git worktree is behind its upstream."
  (let ((default-directory (file-name-as-directory dir)))
    (with-temp-buffer
      (and (zerop (or (ignore-errors
                        (process-file "git" nil t nil
                                      "rev-list" "--count" "HEAD..@{upstream}"))
                      1))
           (> (string-to-number (buffer-string)) 0)))))

(defun astraea//elpaca-outdated-ids ()
  "Ids of queued elpaca packages with upstream commits to merge."
  (cl-loop for (id . e) in (elpaca--queued)
           for dir = (elpaca<-source-dir e)
           when (and dir
                     (not (elpaca-pinned-p e))
                     (file-exists-p dir)
                     (astraea//git-behind-p dir))
           collect id))

(defun astraea/upgrade-packages ()
  "Update every elpaca-managed package.

Interactively this queues elpaca's full asynchronous update.  In batch
sessions (topgrade) all remotes are fetched first and only packages with
upstream commits are merged and rebuilt, so unchanged packages are not
recompiled on every unattended upgrade."
  (interactive)
  (require 'elpaca)
  (if (not noninteractive)
      (elpaca-update-all t)
    (message "Astraea: fetching package updates via elpaca")
    (elpaca-fetch-all t)
    (astraea//elpaca-wait "fetch")
    (let ((outdated (astraea//elpaca-outdated-ids)))
      (if (null outdated)
          (message "Astraea: every package is up to date")
        (message "Astraea: %d package(s) have updates - merging and rebuilding"
                 (length outdated))
        (dolist (id outdated) (elpaca-merge id))
        (elpaca-process-queues)
        (astraea//elpaca-wait "update")
        (let ((failed (cl-loop for (_ . e) in (elpaca--queued)
                               count (eq (elpaca<-status e) 'failed))))
          (when (> failed 0)
            (message "Astraea: %d package(s) failed to update - see *elpaca-log*"
                     failed)))))))

(require 'package nil t)
(defun astraea//package-upgrade-all-advice (&optional _no-query)
  "Replacement for `package-upgrade-all' — elpaca owns the packages.

In batch sessions Emacs exits with status 0 once the upgrade finished,
so unattended callers (topgrade) see success as soon as the upgrade
itself completed instead of relying on the shutdown path."
  (astraea/upgrade-packages)
  (when noninteractive (kill-emacs 0)))
(when (fboundp 'package-upgrade-all)
  (advice-add 'package-upgrade-all :override
              #'astraea//package-upgrade-all-advice))

(defun astraea/reload-user-config ()
  "Re-evaluate ~/.astraea.d/init.el and re-apply UI, theme and modal style."
  (interactive)
  (setq astraea--enabled-layers nil
        astraea--layers-initialized nil
        astraea--init-finished nil)
  (load (expand-file-name "init.el" astraea-user-directory) nil 'nomessage)
  (astraea//finish-init)
  (message "Astraea: user config reloaded"))

(provide 'astraea-init)
;;; astraea-init.el ends here
