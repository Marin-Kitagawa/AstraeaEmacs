;;; -*- lexical-binding: t; -*-
;;; test-cl-loaddefs.el --- isolate the cl-loaddefs load failure
(message "load-path head: %s" (mapconcat #'identity (seq-take load-path 5) " | "))
(condition-case e
    (progn (load "cl-loaddefs") (message "cl-loaddefs load: OK"))
  (error (message "cl-loaddefs load FAILED: %S" e)))
(condition-case e
    (progn (require 'cl-lib) (message "require cl-lib: OK"))
  (error (message "require cl-lib FAILED: %S" e)))
(condition-case e
    (progn (require 'elpaca-autoloads) (message "require elpaca-autoloads: OK"))
  (error (message "require elpaca-autoloads FAILED: %S" e)))
