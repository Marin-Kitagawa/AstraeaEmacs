;;; probe-dashboard.el --- inspect live GUI state, write result to file
(condition-case err
    (let ((failed nil)
          (lang nil)
          (msgs (with-current-buffer "*Messages*"
                  (buffer-substring-no-properties
                   (max (point-min) (- (point-max) 3000)) (point-max)))))
      (dolist (pair (elpaca--queued))
        (when (eq (elpaca<-status (cdr pair)) 'failed)
          (push (elpaca<-id (cdr pair)) failed)))
      (with-temp-file "C:/Users/Ahri/projects/astraea-emacs/tests/probe-result.txt"
        (insert (prin1-to-string
                 (list :ok :failed failed :messages msgs)))))
  (error (with-temp-file "C:/Users/Ahri/projects/astraea-emacs/tests/probe-result.txt"
           (insert (format "PROBE-ERROR: %S" err)))))
