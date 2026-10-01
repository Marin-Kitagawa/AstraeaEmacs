;;; test-read.el --- empirical read/EOF behavior + melpa.eld check
;; 1) clean EOF on a complete file
(condition-case err
    (with-temp-buffer
      (insert-file-contents "C:/Users/Ahri/projects/astraea-emacs/core/astraea-lib.el")
      (goto-char (point-min))
      (while t (read (current-buffer))))
  (end-of-file (message "complete-file EOF msg: %S | %s" err (error-message-string err))))
;; 2) EOF on truly truncated content
(condition-case err
    (with-temp-buffer (insert "(defun foo (bar)\n  (message \"half") (goto-char (point-min)) (while t (read (current-buffer))))
  (end-of-file (message "truncated EOF msg: %S | %s" err (error-message-string err))))
;; 3) melpa.eld explicit check
(condition-case err
    (with-temp-buffer
      (insert-file-contents "C:/Users/Ahri/projects/astraea-emacs/elpaca/cache/melpa.eld")
      (goto-char (point-min))
      (read (current-buffer))
      (message "melpa.eld reads OK"))
  (error (message "melpa.eld ERROR: %S" err)))
