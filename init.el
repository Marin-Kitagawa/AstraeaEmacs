;;; init.el --- Astraea Emacs entry point -*- lexical-binding: t; -*-
;;
;; Astraea Emacs — layers + evil/meow switchable modal editing + scimax-grade
;; org tooling, built for raw startup speed and deep configurability.
;;
;; Launch with:
;;   emacs --init-directory ~/projects/astraea-emacs
;;
;; All user configuration lives in ~/.astraea.d/init.el (seeded on first run
;; from user/init.example.el in this repository).

(setq load-prefer-newer t)

(let ((dir user-emacs-directory))
  (add-to-list 'load-path (expand-file-name "core" dir))
  (add-to-list 'load-path (expand-file-name "layers" dir)))

(require 'astraea-init)

;;; init.el ends here
