;;; test-init.el --- batch driver for Astraea bootstrap testing -*- lexical-binding: t; -*-
(setq user-emacs-directory "C:/Users/Ahri/projects/astraea-emacs/")
(message "TEST: loading init.el ...")
(condition-case err
    (load (expand-file-name "init.el" user-emacs-directory) nil t)
  (error (message "TEST-ERROR: %S" err)
         (kill-emacs 1)))
(message "TEST: init.el loaded without error")
;; Report every registered order's status
(when (boundp 'elpaca--orders)
  (let ((counts (make-hash-table :test 'eq)))
    (maphash (lambda (_ order)
               (let ((st (elpaca--status order)))
                 (puthash st (1+ (gethash st counts 0)) counts)))
             elpaca--orders)
    (maphash (lambda (st n) (message "TEST-STATUS %s: %d" st n)) counts)))
(when (get-buffer "*elpaca-log*")
  (with-current-buffer "*elpaca-log*"
    (goto-char (point-max))
    (forward-line -60)
    (message "TEST-LOG:\n%s" (buffer-substring (point) (point-max)))))
