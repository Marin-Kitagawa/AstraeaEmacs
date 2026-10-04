;;; -*- lexical-binding: t; -*-
;;; ci-driver.el --- CI smoke test: load framework without package processing
;; Repo root: $ASTRAEA_REPO, or the directory this script is invoked from.
(setq user-emacs-directory
      (file-name-as-directory
       (or (getenv "ASTRAEA_REPO")
           (if (file-exists-p (expand-file-name "init.el" default-directory))
               default-directory
             (locate-dominating-file default-directory "init.el")))))
(setq astraea--ci t)
(condition-case err
    (progn
      (load (expand-file-name "init.el" user-emacs-directory) nil t)
      (unless (featurep 'astraea-scimax) (error "astraea-scimax not loaded"))
      (unless (featurep 'astraea-transients) (error "astraea-transients not loaded"))
      (unless (featurep 'astraea-toggles) (error "astraea-toggles not loaded"))
      (message "CI: framework modules loaded OK"))
  (error (message "CI-ERROR: %S" err) (kill-emacs 1)))
