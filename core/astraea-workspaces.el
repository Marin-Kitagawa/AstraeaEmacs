;;; astraea-workspaces.el --- persistent workspaces & session state -*- lexical-binding: t; -*-
;;
;; Port of spacemacs layouts/persistance:
;;   * tab-bar workspaces named per project, window layouts preserved per tab
;;   * per-tab window-config history (winner-like, per workspace)
;;   * desktop persistence — buffers, frames and tabs survive restarts

;; ── per-tab window-config history (winner, scoped per workspace) ─────
(with-eval-after-load 'tab-bar
  (setq tab-bar-select-restore-always t          ; consistent tab restore
        tab-bar-history-mode nil))
(when (fboundp 'tab-bar-history-mode)
  (tab-bar-history-mode 1))

;; ── session persistence (desktop) ────────────────────────────────────
(when (fboundp 'desktop-save-mode)
  (setq desktop-save 'always              ; never prompt, always save
        desktop-restore-frames t
        desktop-restore-in-current-display t
        desktop-load-locked-desktop nil
        desktop-auto-save-timeout 30)
  (desktop-save-mode 1))

(defun astraea/workspace-save ()
  "Save the current session: tabs, window layouts, buffers."
  (interactive)
  (when (fboundp 'desktop-save-in-desktop-dir)
    (desktop-save-in-desktop-dir))
  (message "Workspace saved."))

(defun astraea/workspace-reset ()
  "Delete the saved session (fresh start next launch)."
  (interactive)
  (when-let* ((dir (bound-and-true-p desktop-dirname))
              (file (expand-file-name ".emacs.desktop" dir))
              ((file-exists-p file)))
    (delete-file file)
    (message "Saved session deleted — next launch starts fresh.")))

(provide 'astraea-workspaces)
;;; astraea-workspaces.el ends here
