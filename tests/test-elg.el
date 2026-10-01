;;; test-elg.el --- standalone elpaca-git/elpaca-log require test
(setq load-prefer-newer t)
(add-to-list 'load-path "C:/Users/Ahri/projects/astraea-emacs/elpaca/repos/elpaca")
(condition-case e
    (progn (require 'elpaca) (message "require elpaca: OK"))
  (error (message "require elpaca FAILED: %S" e)))
(condition-case e
    (progn (require 'elpaca-git) (message "require elpaca-git: OK"))
  (error (message "require elpaca-git FAILED: %S" e)))
(condition-case e
    (progn (require 'elpaca-log) (message "require elpaca-log: OK"))
  (error (message "require elpaca-log FAILED: %S" e)))
(condition-case e
    (progn (require 'elpaca-ui) (message "require elpaca-ui: OK"))
  (error (message "require elpaca-ui FAILED: %S" e)))
