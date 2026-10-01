;;; check-elpaca.el --- find truncated elisp files under elpaca/ -*- lexical-binding: t; -*-
(let ((broken nil)
      (files (append
              (directory-files "C:/Users/Ahri/projects/astraea-emacs/elpaca" t "\\.eld\\'")
              (directory-files-recursively
               "C:/Users/Ahri/projects/astraea-emacs/elpaca/builds"
               "\\(?:-autoloads\\.el\\|-pkg\\.el\\)\\'"))))
  (dolist (f files)
    (if (zerop (nth 7 (file-attributes f)))
        (push (list f :empty) broken)
      (with-temp-buffer
        (condition-case err
            (progn
              (insert-file-contents f)
              (goto-char (point-min))
              (while t (read (current-buffer))))
          (end-of-file
           ;; "End of file" = clean EOF; "End of file during parsing" = truncated
           (unless (equal (error-message-string err) "End of file")
             (push (list f :truncated (error-message-string err)) broken)))
          (error nil)))))
  (if broken
      (dolist (b (nreverse broken)) (message "BROKEN %s %S" (car b) (cadr b)))
    (message "all elpaca elisp files parse cleanly"))
  (message "checked %d files" (length files)))
