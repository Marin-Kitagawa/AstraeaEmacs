;;; check-parens.el --- reliable unbalanced-paren scan for framework files -*- lexical-binding: t; -*-
;; Repo root: $ASTRAEA_REPO, or the directory this script is invoked from
;; (works both locally and on CI runners — never hardcode absolute paths).
(let* ((root (file-name-as-directory
              (or (getenv "ASTRAEA_REPO")
                  (if (file-exists-p (expand-file-name "init.el" default-directory))
                      default-directory
                    (locate-dominating-file default-directory "init.el")))))
       (files (and root (directory-files-recursively
                         root "\\.el\\'"
                         nil (lambda (d) (not (string-match-p "elpaca\\|/elpa\\|\\.git" d))) t)))
       (failed 0))
  (dolist (f files)
    (with-temp-buffer
      (condition-case err
          (progn
            (insert-file-contents f)
            (emacs-lisp-mode)
            (check-parens)
            (goto-char (point-max)))
        (error (setq failed (1+ failed))
               (message "PAREN-FAIL %s (line %d): %s"
                        (file-name-nondirectory f)
                        (line-number-at-pos) (error-message-string err))))))
  (if files
      (message "check-parens: %d files, %d failed" (length files) failed)
    (message "PAREN-FAIL: no framework files found under %S" default-directory))
  (when (or (> failed 0) (not files))
    (kill-emacs 1)))
