;;; test-elpaca-load.el --- minimal elpaca.el load test
(add-to-list 'load-path "C:/Users/Ahri/projects/astraea-emacs/elpaca/repos/elpaca")
(message "lexical-binding of elpaca.el buffer-local test...")
(condition-case e
    (progn (load "elpaca") (message "elpaca load: OK"))
  (error (message "elpaca load FAILED: %S" e)))
(condition-case e
    (progn (require 'custom) (message "custom loaded"))
  (error (message "custom: %S" e)))
(message "emacs-version: %s" emacs-version)
