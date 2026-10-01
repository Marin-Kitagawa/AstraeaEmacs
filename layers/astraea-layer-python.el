;;; astraea-layer-python.el --- Astraea layer: +lang/python -*- lexical-binding: t; -*-
;;
;; Covers python + jupyter notebooks + formatting (ruff), matching a
;; scimax / data-science workflow.

(astraea-layer! +lang/python
  :packages (pyvenv)  ; jupyter is queued by the scimax org stack (core)
  :init
  (progn
    (elpaca pyvenv)
    ;; LSP: pyright or pylsp via eglot; formatter: ruff; checker: ruff
    (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
    (add-hook 'python-mode-hook #'eglot-ensure)
    (add-hook 'python-mode-hook
              (lambda ()
                (setq-local tab-width 4
                            python-indent-offset 4
                            fill-column 88))))
  :keybinds
  (astraea/leader-def
   "m v" #'pyvenv-activate
   "m s" #'run-python
   "m j" #'astraea/org-jupyter-start))

(provide 'astraea-layer-python)
;;; astraea-layer-python.el ends here
