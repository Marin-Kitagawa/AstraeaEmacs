;;; check-parens.el --- reliable unbalanced-paren scan for framework files -*- lexical-binding: t; -*-
(let ((files (directory-files-recursively
              "C:/Users/Ahri/projects/astraea-emacs" "\\.el\\'"
              nil (lambda (d) (not (string-match-p "elpaca" d))) t))
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
  (message "check-parens: %d files, %d failed" (length files) failed))
