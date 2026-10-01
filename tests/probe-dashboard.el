;;; probe-dashboard.el --- inspect live GUI state, write result to file
(let ((failed nil))
  (dolist (pair (elpaca--queued))
    (when (eq (elpaca<-status (cdr pair)) 'failed)
      (push (elpaca<-id (cdr pair)) failed)))
  (with-temp-file "C:/Users/Ahri/projects/astraea-emacs/tests/probe-result.txt"
    (insert (prin1-to-string
             (list :win-buf (buffer-name (window-buffer (frame-first-window (car (frame-list)))))
                   :dash-buf (and (get-buffer dashboard-buffer-name) t)
                   :banner dashboard-startup-banner
                   :banner-exists (file-exists-p
                                   (if (and astraea-dashboard-banner
                                            (not (file-name-absolute-p astraea-dashboard-banner)))
                                       (expand-file-name astraea-dashboard-banner user-emacs-directory)
                                     astraea-dashboard-banner))
                   :theme (car custom-enabled-themes)
                   :init-finished astraea--init-finished
                   :failed failed)))))
