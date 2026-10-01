;;; astraea-editing.el --- spacemacs editing-visual layer equivalents -*- lexical-binding: t; -*-
;;
;; expand-region, multiple-cursors, move-text, iedit, ace-window,
;; winner-mode, duplicate line, align/sort — the everyday editing power
;; tools from spacemacs's editing-visual and window-management layers.

;; ── expand-region (v in spacemacs) ──────────────────────────────────
(elpaca expand-region
  (global-set-key (kbd "C-=") #'er/expand-region)
  (global-set-key (kbd "C--") #'er/contract-region))

;; ── multiple-cursors ────────────────────────────────────────────────
(elpaca multiple-cursors
  (global-set-key (kbd "C->") #'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") #'mc/unmark-next-like-this)
  (global-set-key (kbd "C-c C->") #'mc/mark-all-like-this)
  (global-set-key (kbd "C-c C-<") #'mc/mark-all-dwim))

;; ── move-text (M-up / M-down) ───────────────────────────────────────
(elpaca move-text
  (global-set-key [M-up] #'move-text-up)
  (global-set-key [M-down] #'move-text-down))

;; ── iedit — edit all occurrences of the symbol at point ─────────────
(elpaca iedit
  (global-set-key (kbd "C-;") #'iedit-mode))

;; ── ace-window — quick window selection (winum equivalent) ─────────
(elpaca ace-window
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
        aw-background t)
  (global-set-key [remap other-window] #'ace-window))

;; ── winner-mode — window layout undo/redo ───────────────────────────
(winner-mode 1)

;; ── duplicate line or region ────────────────────────────────────────
(defun astraea/duplicate-line-or-region ()
  "Duplicate the current line (or the active region) below."
  (interactive)
  (if (use-region-p)
      (let ((beg (region-beginning)) (end (region-end)))
        (copy-region-as-kill beg end)
        (goto-char end)
        (yank)
        (setq deactivate-mark nil))
    (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
      (goto-char (line-end-position))
      (insert (concat "\n" line)))))

;; ── rotate windows (swap layout clockwise) ──────────────────────────
(defun astraea/rotate-windows ()
  "Rotate the windows of the current frame clockwise."
  (interactive)
  (let ((buffers (mapcar #'window-buffer (window-list))))
    (dolist (win (window-list))
      (set-window-buffer win (or (cadr (memq (window-buffer win) buffers))
                                 (car buffers))))))

;; ── text utilities (SPC x group) ────────────────────────────────────
(defun astraea/deduplicate-lines ()
  "Delete duplicate lines in the active region (or whole buffer)."
  (interactive)
  (if (use-region-p)
      (delete-duplicate-lines (region-beginning) (region-end))
    (delete-duplicate-lines (point-min) (point-max))))

(defun astraea/whole-buffer-command (cmd)
  "Run region-or-buffer CMD (`sort-lines' style) over the whole buffer."
  (let (( deactivate-mark nil))
    (if (use-region-p)
        (call-interactively cmd)
      (save-excursion
        (push-mark (point-min) t t)
        (call-interactively cmd)))))

(provide 'astraea-editing)
;;; astraea-editing.el ends here
