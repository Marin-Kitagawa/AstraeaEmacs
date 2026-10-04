;;; astraea-fun.el --- the emoji & fun layer -*- lexical-binding: t; -*-
;;
;; Port of spacemacs +fun layer + emoji support.  Opt out with
;; (setq astraea-fun-enabled nil) in the user config.

(when astraea-fun-enabled
  ;; ── emoji ──────────────────────────────────────────────────────────
  (elpaca emojify
    (unless noninteractive
      (global-emojify-mode 1)))

  ;; built-in emoji picker (Emacs 31): C-x 8 e e / s / r
  (with-eval-after-load 'astraea-keybinds
    (astraea/leader-def
     "i e" #'emoji-insert
     "i s" #'emoji-search
     "i r" #'emoji-recent))

  ;; ── games (all built-in — zero startup cost) ───────────────────────
  (defun astraea/play-gomoku () (interactive) (gomoku))
  (defun astraea/play-life () (interactive) (life))
  (defun astraea/play-solitaire () (interactive) (solitaire))
  (defun astraea/play-dunnet () (interactive) (dunnet))
  (defun astraea/play-zone () (interactive) (zone))

  (transient-define-prefix astraea/games-transient ()
    "Astraea arcade."
    [["Classics"
      ("t" "Tetris" tetris)
      ("s" "Snake" snake)
      ("p" "Pong" pong)
      ("g" "Gomoku" astraea/play-gomoku)]
     ["Oddities"
      ("l" "Life" astraea/play-life)
      ("o" "Solitaire" astraea/play-solitaire)
      ("d" "Dunnet (text adventure)" astraea/play-dunnet)
      ("z" "Zone (screensaver)" astraea/play-zone)]])

  (with-eval-after-load 'astraea-keybinds
    (astraea/leader-def "x g" #'astraea/games-transient))

  ;; ── xkcd ───────────────────────────────────────────────────────────
  (elpaca xkcd
    (with-eval-after-load 'astraea-keybinds
      (astraea/leader-def "x k" #'xkcd))))

(provide 'astraea-fun)
;;; astraea-fun.el ends here
