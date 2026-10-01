;;; astraea-layer-git.el --- Astraea layer: +tools/git -*- lexical-binding: t; -*-
;;
;; Layer file naming: layers/astraea-layer-NAME.el where NAME uses `+'
;; for categories.  Enable with (astraea/enable-layer '+tools/git).

(astraea-layer! +tools/git
  :packages (magit git-timemachine diff-hl magit-todos)
  :init
  (progn
    (elpaca magit)
    (elpaca git-timemachine)
    (elpaca diff-hl)
    (elpaca magit-todos))
  :config
  (progn
    (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
          magit-save-repository-buffers 'dontask)
    (global-diff-hl-mode 1)
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
    (magit-todos-mode 1))
  :keybinds
  (progn
    (astraea/leader-def
     "g g" #'magit-status
     "g s" #'magit-stage-file
     "g c" #'magit-commit-create
     "g p" #'magit-push
     "g l" #'magit-log-current
     "g d" #'magit-diff-unstaged
     "g t" #'git-timemachine)
    (transient-append-suffix 'astraea/transient-git "t"
      '("T" "Todos" magit-todos-list))))

(provide 'astraea-layer-git)
;;; astraea-layer-git.el ends here
