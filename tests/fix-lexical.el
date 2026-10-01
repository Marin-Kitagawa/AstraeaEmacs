;;; -*- lexical-binding: t; -*-
;;; fix-lexical.el --- add lexical-binding cookie where missing
(let ((files (directory-files-recursively
              "C:/Users/Ahri/projects/astraea-emacs" "\\.el\\'"
              nil (lambda (d) (not (string-match-p "elpaca" d))) t))
      (fixed 0) (ok 0))
  (dolist (f files)
    (with-current-buffer (find-file-noselect f)
      (goto-char (point-min))
      (if (and (re-search-forward "-\\*-.*-\\*-" (line-end-position) t)
               (save-excursion
                 (goto-char (match-beginning 0))
                 (looking-at ".*lexical-binding")))
          (setq ok (1+ ok))
        ;; add/extend the cookie on the first line
        (goto-char (point-min))
        (cond
         ;; header line already has a -*- block: extend it
         ((re-search-forward "-\\*-" (line-end-position) t)
          (goto-char (match-beginning 0))
          (insert "lexical-binding: t; ")
          (setq fixed (1+ fixed)))
         ;; no block at all: insert a fresh first line
         (t
          (insert ";;; -*- lexical-binding: t; -*-\n")
          (setq fixed (1+ fixed))))
        (basic-save-buffer))))
  (message "lexical-binding: %d already ok, %d fixed" ok fixed))
