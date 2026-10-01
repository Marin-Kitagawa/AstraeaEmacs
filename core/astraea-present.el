;;; astraea-present.el --- org-show style presentations -*- lexical-binding: t; -*-
;;
;; Port of scimax org-show on top of org-present: per-slide narrowing,
;; big text, inline images, PgDn/PgUp navigation, F5/F6 start/stop.

(defcustom astraea/present-scale 3
  "Text scale used during presentations."
  :type 'number)

(defun astraea/present--narrow-slide ()
  "Narrow to the current slide (heading) and refresh images."
  (org-narrow-to-subtree)
  (org-overview)
  (org-show-subtree)
  (when (fboundp 'org-display-inline-images)
    (org-display-inline-images nil t))
  (goto-char (point-min)))

(defun astraea/present--widen ()
  (widen)
  (org-overview))

(defun astraea/present-next ()
  "Go to the next slide."
  (interactive)
  (widen)
  (org-next-visible-heading 1)
  (astraea/present--narrow-slide))

(defun astraea/present-previous ()
  "Go to the previous slide."
  (interactive)
  (widen)
  (org-previous-visible-heading 1)
  (astraea/present--narrow-slide))

(defun astraea/present-start ()
  "Start a presentation: slides are org headings."
  (interactive)
  (org-present-mode)
  (text-scale-set astraea/present-scale)
  (org-overview)
  (goto-char (point-min))
  (org-next-visible-heading 1)
  (astraea/present--narrow-slide))

(defun astraea/present-stop ()
  "Stop the presentation and restore the buffer."
  (interactive)
  (widen)
  (text-scale-set 0)
  (when (fboundp 'org-present-quit)
    (org-present-quit)))

(defun astraea/present--setup-keys ()
  "Presentation navigation keys (PgDn/PgUp/q/F11)."
  (local-set-key [next] #'astraea/present-next)     ; PgDn
  (local-set-key [prior] #'astraea/present-previous) ; PgUp
  (local-set-key (kbd "q") #'astraea/present-stop)
  (local-set-key (kbd "f") #'org-present-toggle-big)
  (local-set-key (kbd "i") #'org-present-toggle-inline-images))

(add-hook 'org-present-mode-hook #'astraea/present--setup-keys)

(provide 'astraea-present)
;;; astraea-present.el ends here
