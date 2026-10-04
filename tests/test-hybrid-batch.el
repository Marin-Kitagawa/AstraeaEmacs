;;; test-hybrid-batch.el --- verify hybrid modal + theme + upgrade routing -*- lexical-binding: t; -*-
(setq user-emacs-directory "C:/Users/Ahri/projects/astraea-emacs/")
(condition-case err
    (progn
      (load (expand-file-name "init.el" user-emacs-directory) nil t)
      (unless (featurep 'astraea-init) (error "astraea-init not loaded"))
      ;; real config uses hybrid: finalization must have run to the end
      (unless astraea--init-finished (error "astraea//finish-init did not run"))
      (unless (eq astraea-modal-style 'hybrid)
        (error "modal style is %S, expected hybrid" astraea-modal-style))
      (unless (memq 'catppuccin custom-enabled-themes)
        (error "catppuccin not enabled (themes: %S)" custom-enabled-themes))
      (unless (and (boundp 'evil-mode) evil-mode)
        (error "evil not active in hybrid mode"))
      ;; insert state must be wiped down to emacs-native + escape exit
      (unless (lookup-key evil-insert-state-map [escape])
        (error "ESC no longer exits insert state"))
      (when (lookup-key evil-insert-state-map (kbd "C-n"))
        (error "insert state still has vim bindings (not hybrid)"))
      ;; package-upgrade-all must be routed through elpaca (topgrade)
      (unless (featurep 'package) (error "package.el not loaded"))
      (unless (advice-member-p #'astraea//package-upgrade-all-advice
                               'package-upgrade-all)
        (error "package-upgrade-all is not advised through elpaca"))
      (unless (fboundp 'astraea/set-theme) (error "astraea/set-theme missing"))
      (unless (fboundp 'astraea/catppuccin-flavor) (error "astraea/catppuccin-flavor missing"))
      (unless (fboundp 'astraea/cycle-frame-alpha) (error "astraea/cycle-frame-alpha missing"))
      (unless (fboundp 'astraea/reload-user-config) (error "astraea/reload-user-config missing"))
      (unless (fboundp 'astraea/upgrade-packages) (error "astraea/upgrade-packages missing"))
      ;; toggles T m / T t must not signal void-variable
      (menu-bar-mode -1)
      (astraea/toggle-menu-bar)
      (astraea/toggle-tool-bar)
      (message "HYBRID-BATCH-OK: %s layers, theme %S, style %S"
               (length astraea--enabled-layers) astraea-theme astraea-modal-style))
  (error (message "HYBRID-FAIL: %S" err) (kill-emacs 1)))
