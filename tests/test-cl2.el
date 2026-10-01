;;; test-cl2.el --- test cl-loaddefs under load-prefer-newer
(setq load-prefer-newer t)
(condition-case e
    (progn (load "cl-loaddefs") (message "cl-loaddefs (prefer-newer): OK"))
  (error (message "cl-loaddefs (prefer-newer) FAILED: %S" e)))
(condition-case e
    (progn (load "cl-loaddefs.elc") (message "cl-loaddefs.elc: OK"))
  (error (message "cl-loaddefs.elc FAILED: %S" e)))
(condition-case e
    (with-temp-buffer
      (insert-file-contents "C:/Users/Ahri/Software/emacs-31.1/share/emacs/31.1/lisp/emacs-lisp/cl-loaddefs.el")
      (goto-char (point-min))
      (while t (read (current-buffer)))
      (message "cl-loaddefs.el parse: OK"))
  (end-of-file (message "cl-loaddefs.el parse reached EOF: %s" (error-message-string e)))
  (error (message "cl-loaddefs.el parse ERROR: %S" e)))
