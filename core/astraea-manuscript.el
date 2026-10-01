;;; astraea-manuscript.el --- ox-manuscript LaTeX build pipeline -*- lexical-binding: t; -*-
;;
;; Vendors scimax's ox-manuscript (GPL) for journal-class LaTeX builds
;; and wires it for MiKTeX + pandoc environments.

(add-to-list 'load-path (expand-file-name "modules/ox-manuscript" user-emacs-directory))

(with-eval-after-load 'ox
  (require 'ox-manuscript nil t)
  (with-eval-after-load 'ox-manuscript
    ;; MiKTeX
    (setq ox-manuscript-latex-command "pdflatex"
          ox-manuscript-bibtex-command "bibtex"
          ox-manuscript-interactive-build nil
          ox-manuscript-user-template-dir
          (expand-file-name "org/manuscript-templates/" astraea-user-directory))
    (make-directory ox-manuscript-user-template-dir t)))

(defun astraea/manuscript-build ()
  "Export the current org manuscript and run the LaTeX build."
  (interactive)
  (require 'ox-manuscript)
  (call-interactively #'ox-manuscript-export-and-build))

(defun astraea/manuscript-build-and-open ()
  "Export, build, and open the resulting PDF."
  (interactive)
  (require 'ox-manuscript)
  (call-interactively #'ox-manuscript-export-and-build-and-open))

(defun astraea/manuscript-new ()
  "Create a new manuscript from a template (journal classes incl. ACS, APS, Springer, Elsevier)."
  (interactive)
  (require 'ox-manuscript)
  (call-interactively #'ox-manuscript-new-ivy))

(defun astraea/manuscript-word-count ()
  "Run texcount on the current manuscript's LaTeX output (MiKTeX)."
  (interactive)
  (require 'ox-manuscript)
  (call-interactively #'ox-manuscript-word-count))

(with-eval-after-load 'astraea-keybinds
  (astraea/leader-def
   "n m b" #'astraea/manuscript-build
   "n m o" #'astraea/manuscript-build-and-open
   "n m n" #'astraea/manuscript-new
   "n m w" #'astraea/manuscript-word-count))

(provide 'astraea-manuscript)
;;; astraea-manuscript.el ends here
