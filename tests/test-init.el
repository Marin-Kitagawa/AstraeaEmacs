;;; test-init.el --- trace every code-conversion load to find the EOF file -*- lexical-binding: t; -*-
(setq user-emacs-directory "C:/Users/Ahri/projects/astraea-emacs/")
(defvar astraea--load-log nil)
(advice-add 'load-with-code-conversion :before
            (lambda (file &rest _)
              (setq astraea--load-log (cons file astraea--load-log))))
(condition-case err
    (load (expand-file-name "init.el" user-emacs-directory) nil t)
  (error
   (message "TEST-ERROR: %S" err)
   (message "=== last 8 files entering load-with-code-conversion ===")
   (mapc (lambda (f) (message "  %s" f)) (seq-take astraea--load-log 8))
   (kill-emacs 1)))
(message "TEST: init.el loaded without error")
