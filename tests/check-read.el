;;; check-read.el --- batch syntax check for Astraea files
(let ((files (directory-files-recursively
              "C:/Users/Ahri/projects/astraea-emacs" "\\.el\\'"
              nil (lambda (d) (not (string-match-p "elpaca" d))) t)))
  (dolist (f files)
    (with-temp-buffer
      (condition-case err
          (progn
            (insert-file-contents f)
            (goto-char (point-min))
            (while t (read (current-buffer))))
        (end-of-file
         (message "READ-FAIL %s: truncated (end-of-file during parsing)"
                  (file-name-nondirectory f)))
        (error (message "READ-FAIL %s (line %d): %S"
                        (file-name-nondirectory f)
                        (line-number-at-pos (point)) err)))))
  (message "check complete"))
