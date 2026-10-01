;;; astraea-project.el --- Projects, workspaces, file manager, editing ops -*- lexical-binding: t; -*-
;;
;; AstroNvim tools translated:
;;   project.nvim         → project.el (built-in) + projectile option
;;   grapple.nvim         → tab-bar workspaces + transient menu (SPC T)
;;   yazi.nvim            → dirvish (dired overhaul, Emacs-native yazi feel)
;;   neoclip.nvim         → consult-yank + kill-ring persistence
;;   img-clip.nvim        → org download images into buffer-local dirs
;;   markdown-preview     → markdown-mode + grip/eww live preview

;; ── Projects (built-in project.el) ──────────────────────────────────────
(require 'project)
(setq project-switch-commands
      '((project-find-file "Find file" ?f)
        (project-find-regexp "Find regexp" ?g)
        (project-dired "Dired" ?d)
        (project-eshell "Eshell" ?e)
        (magit-project-status "Magit" ?m))
      project-list-file (expand-file-name "var/projects" astraea-user-directory))

(elpaca projectile)                   ; optional heavier alternative

(defun astraea/toggle-project ()
  "Switch project via project.el."
  (interactive)
  (project-switch-project (completing-read "Project: " (project-known-project-roots))))

;; ── Workspaces (grapple.nvim equivalent, via tab-bar) ──────────────────
(defun astraea/workspace-add ()
  "Add a named workspace for the current project."
  (interactive)
  (let ((name (if-let* ((proj (project-current))
                        (root (project-name proj)))
                  (format "%s" root)
                (read-string "Workspace name: "))))
    (tab-bar-rename-tab name)
    (message "Workspace: %s" name)))

(defun astraea/workspace-switch ()
  "Jump between named workspaces."
  (interactive)
  (call-interactively #'tab-bar-switch-to-tab))

;; ── Dirvish: modern dired (yazi.nvim equivalent) ───────────────────────
(elpaca dirvish
  (dirvish-override-dired-mode 1)
  (setq dirvish-attributes '(nerd-icons file-size git))
  (setq dirvish-quick-access-entries
        '(("h" "~/" "Home")
          ("p" "~/projects/" "Projects")
          ("d" "~/Downloads/" "Downloads"))))

;; ── Clipboard history (neoclip.nvim equivalent) ────────────────────────
;; consult provides `consult-yank-pop' — no separate package needed
(savehist-mode 1)                     ; persists kill-ring across sessions

;; ── Image paste (img-clip.nvim equivalent) ─────────────────────────────
(elpaca org-download
  (setq org-download-method 'directory
        org-download-image-dir "./assets"
        org-download-screenshot-method "powershell"))

(defun astraea/org-paste-image ()
  "Paste clipboard image at point into ./assets/."
  (interactive)
  (org-download-clipboard))

;; ── Markdown (markview + markdown-preview.nvim equivalents) ────────────
(elpaca markdown-mode
  (setq markdown-command "pandoc"))
(elpaca grip-mode
  (setq grip-preview-use-webkit t))    ; live GitHub-style preview

;; ── Eshell: integrated terminal (snacks terminal equivalent) ───────────
(defun astraea/terminal ()
  "Open an eshell in the current project root."
  (interactive)
  (let ((default-directory (if-let* ((proj (project-current)))
                               (project-root proj)
                             default-directory)))
    (eshell t)))

(provide 'astraea-project)
;;; astraea-project.el ends here
