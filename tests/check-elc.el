;;; check-elc.el --- load .elc files listed in a manifest; report EOF errors -*- lexical-binding: t; -*-
(let* ((manifest-file (car command-line-args-left))
       (files (with-temp-buffer
                (insert-file-contents manifest-file)
                (split-string (buffer-string) "\n" t))))
  (setq command-line-args-left nil)
  (dolist (f files)
    (condition-case err
        (load f nil t)
      (end-of-file
       (message "BROKEN-ELC %s" f))
      (error nil)))
  (message "chunk done (%d files)" (length files)))
