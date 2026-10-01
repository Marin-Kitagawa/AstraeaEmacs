;;; astraea-ui.el --- Dashboard, modeline, themes, tree, notifications -*- lexical-binding: t; -*-
;;
;; AstroNvim-grade UI, translated to Emacs:
;;   alpha-nvim        → dashboard.el
;;   noice/notify      → via +posframe which-key & transient menus
;;   neo-tree          → treemacs (SPC e tree via dirvish/dired also)
;;   bufferline        → mood-line + tab-bar workspaces
;;   indent guides     → indent-bars
;;   web-devicons      → nerd-icons
;;   UFO folding       → treesit-fold
;;   flash.nvim        → avy
;;   snacks smooth UI  → pixel-scroll-precision + ultra-scroll

;; ── Icons ─────────────────────────────────────────────────────────────────
(elpaca nerd-icons)
(elpaca nerd-icons-corfu)

;; ── Dashboard (alpha-nvim equivalent) ────────────────────────────────────
(elpaca dashboard
  (when astraea-dashboard-enabled
    (let ((banner (if (and astraea-dashboard-banner
                           (not (file-name-absolute-p astraea-dashboard-banner)))
                      (expand-file-name astraea-dashboard-banner user-emacs-directory)
                    astraea-dashboard-banner)))
      (setq dashboard-items '((recents . 10) (projects . 8) (bookmarks . 5) (agenda . 5))
            dashboard-startup-banner (if (and banner (file-exists-p banner)) banner 'logo)
            dashboard-banner-logo-title "✦  A S T R A E A  ✦"
            dashboard-center-content t
            dashboard-vertically-center-content t
            dashboard-set-heading-icons t
            dashboard-set-file-icons t
            dashboard-display-icons-p #'icons-displayable-p
            dashboard-footer-messages
            '("✨ balanced parens, serene mind ✨"
              "🌙 SPC to explore — which-key shows the way"
              "🌟 M-x astraea/set-modal-style to switch evil ⇄ meow anytime"))
      (when (fboundp 'nerd-icons-codicon)
        (setq dashboard-footer-icon
              (nerd-icons-codicon "nf-cod-sparkle" :height 1.2 :face 'nerd-icons-pink))))
    ;; show the dashboard on launch (scratch fallback keeps batch sessions safe)
    (setq initial-buffer-choice
          (lambda ()
            (or (get-buffer dashboard-buffer-name)
                (get-buffer "*scratch*"))))
    (dashboard-setup-startup-hook)))

;; ── Modeline: mood-line (light, cute, zero doom) ──────────────────────
(elpaca mood-line
  (setq mood-line-show-eol-style t
        mood-line-show-indent-style t)
  (when (fboundp 'mood-line-format-text-packed)
    (setq mood-line-format (mood-line-format-text-packed)))
  (mood-line-mode 1))

(when (display-graphic-p)
  (tab-bar-mode 1)
  (setq tab-bar-show 1
        tab-bar-close-button-show nil))

;; ── File tree (neo-tree equivalent) ──────────────────────────────────────
(elpaca treemacs
  (setq treemacs-follow-after-init t
        treemacs-width 34
        treemacs-is-never-other-window t))
(elpaca treemacs-evil)
(elpaca treemacs-projectile)
(elpaca treemacs-icons-dired
  (treemacs-icons-dired-mode))

;; ── Themes: beautiful, feminine, cute — no doom, ever ────────────────
(elpaca catppuccin-theme)             ; pastel mocha/frappé (theme: catppuccin)
(elpaca kanagawa-themes)              ; wave-art fallback (theme: kanagawa)
(elpaca ef-themes)                    ; Protesilaos collection — ef-summer,
                                      ; ef-rosa, ef-cyprus, ef-elea… (GNU ELPA)
(elpaca moe-theme)                    ; cheerful, bubbly
(elpaca sakura-theme)                 ; soft cherry blossom
(elpaca cherry-blossom-theme)         ; sakura pink
(elpaca pink-bliss-uwu-theme)         ; unapologetically pink uwu
(elpaca pastelmac-theme)              ; pastel macOS
(elpaca bubbleberry-theme)            ; juicy purple
(elpaca lavender-theme)               ; gentle lavender
(elpaca kaolin-themes)                ; soft pastel set (kaolin-* variants)
(elpaca indent-bars)
(elpaca treesit-fold)       ; UFO equivalent on Emacs 30+ treesit
(elpaca electric-operator)

;; ── tab-bar theming: match the active dark theme ────────────────────────
(defun astraea/ui//apply-tab-bar-faces ()
  "Style the tab-bar to match the active theme.
Derives colors from the `default' face so any theme stays consistent."
  (let* ((bg (face-attribute 'default :background nil 'default))
         (fg (face-attribute 'default :foreground nil 'default))
         (dim (face-attribute 'font-lock-comment-face :foreground nil 'default)))
    (set-face-attribute 'tab-bar nil :background bg :foreground fg :height 0.95)
    (set-face-attribute 'tab-bar-tab nil
                        :background bg :foreground fg
                        :weight 'bold
                        :box `(:line-width 3 :color ,bg :style nil))
    (set-face-attribute 'tab-bar-tab-inactive nil
                        :background bg :foreground dim
                        :box `(:line-width 3 :color ,bg :style nil))
    (set-face-attribute 'tab-line nil :background bg :foreground fg)))

;; restyle automatically whenever a theme is (re)loaded
(advice-add 'load-theme :after
            (lambda (&rest _) (astraea/ui//apply-tab-bar-faces)))

(defun astraea/ui//finish ()
  "Final UI pass, after all packages are loaded."
  (ignore-errors (load-theme astraea-theme t))
  (when (fboundp 'astraea//bind-core-keys)
    (astraea//bind-core-keys)
    (astraea/layers--run-config))
  (astraea/ui//apply-tab-bar-faces))

;; convenient tree toggle bound to leader
(defun astraea/toggle-file-tree ()
  "Toggle treemacs; fall back to dired."
  (interactive)
  (if (fboundp 'treemacs)
      (treemacs-select-window)
    (dired default-directory)))

;; ── Fullscreen cycling: normal → maximized → fullboth → normal ────────
(defun astraea/cycle-fullscreen ()
  "Cycle the frame state: normal → maximized → fullscreen → normal."
  (interactive)
  (pcase (frame-parameter nil 'fullscreen)
    ('fullboth (set-frame-parameter nil 'fullscreen nil))
    ((or 'maximized 'fullwidth) (set-frame-parameter nil 'fullscreen 'fullboth))
    (_ (set-frame-parameter nil 'fullscreen 'maximized))))
(global-set-key (kbd "<f11>") #'astraea/cycle-fullscreen)

(provide 'astraea-ui)
;;; astraea-ui.el ends here
