;;; astraea-layer-emacs-lisp.el --- Astraea layer: +lang/emacs-lisp -*- lexical-binding: t; -*-

(astraea-layer! +lang/emacs-lisp
  :packages (elisp-demos suggest macrostep)
  :init
  (progn
    (elpaca elisp-demos)
    (elpaca suggest)
    (elpaca macrostep))
  :config
  (progn
    (add-hook 'emacs-lisp-mode-hook
              (lambda ()
                (setq-local tab-width 2)
                (corfu-mode 1)
                (eglot-ensure)))          ; elisp has a built-in LSP in 30+
    (add-hook 'help-mode-hook #'elisp-demos-advice-describe-function-1))
  :keybinds
  (astraea/leader-def
   "m e" #'macrostep-expand
   "m b" #'eval-buffer
   "m f" #'eval-defun
   "m r" #'eval-region))

(provide 'astraea-layer-emacs-lisp)
;;; astraea-layer-emacs-lisp.el ends here
