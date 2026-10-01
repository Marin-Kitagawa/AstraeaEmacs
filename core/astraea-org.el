;;; astraea-org.el --- scimax-grade org: notes, citations, LaTeX, notebooks -*- lexical-binding: t; -*-
;;
;; The scimax layer: everything needed for scientific computing and
;; publishing inside org-mode.
;;   scimax notebooks / ob-ipython → jupyter + org-babel
;;   scimax citations             → citar + biblio (org-cite native)
;;   scimax LaTeX                 → cdlatex + auctex + org-latex preview
;;   scimax org enhancements      → org-modern, org-appear, valign, ox-pandoc
;;   roam-style zettelkasten      → org-roam (optional, heavy: defers)

;; ── Org base ─────────────────────────────────────────────────────────────
(elpaca org
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t        ; with org-appear, they come back on cursor
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-confirm-babel-evaluate nil     ; trust your own notebooks
        org-agenda-files (list (expand-file-name "org/agenda/" astraea-user-directory))
        org-latex-compiler "xelatex"
        org-preview-latex-default-process 'dvisvgm))

;; ── Modern looks ────────────────────────────────────────────────────────
(elpaca org-modern
  (add-hook 'org-mode-hook #'org-modern-mode))
(elpaca org-appear
  (add-hook 'org-mode-hook #'org-appear-mode))
(elpaca valign
  (add-hook 'org-mode-hook #'valign-mode))

;; ── Literate notebooks (ob-ipython / scimax equivalent) ────────────────
(elpaca jupyter
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t) (jupyter . t) (emacs-lisp . t) (shell . t) (sql . t)))
  (setq org-babel-default-header-args:jupyter-python
        '((:session . "py") (:kernel . "python3") (:async . "yes"))))

;; ── Citations: citar (scimax bibliography stack) ───────────────────────
(elpaca citar
  (setq citar-bibliography '("~/Zotero/library.bib")
        citar-library-paths '("~/Zotero/storage/")
        citar-notes-paths '("~/org/notes/")
        org-cite-global-bibliography (list "~/Zotero/library.bib")
        citar-at-point-function 'citar-dwim))
(elpaca citar-org-roam)
(elpaca biblio)                       ; crossref/arxiv/pubmed search

;; ── LaTeX editing (scimax/CDLaTeX) ─────────────────────────────────────
(elpaca cdlatex
  (add-hook 'org-mode-hook #'turn-on-org-cdlatex))
(elpaca auctex
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-save-query nil))

;; ── Org roam (optional zettelkasten) ───────────────────────────────────
(elpaca org-roam
  (setq org-roam-directory (expand-file-name "org/roam/" astraea-user-directory)
        org-roam-completion-everywhere t
        org-roam-capture-templates
        '(("d" "default" plain
           "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
           :unnarrowed t)))
  (org-roam-db-autosync-mode 1))

;; ── Export & publishing ────────────────────────────────────────────────
(elpaca ox-pandoc)                    ; every output format pandoc supports
(elpaca htmlize)                      ; syntax-colored code in exports
(elpaca ox-hugo)                      ; static-site publishing

;; ── Org keybinds (leader) ──────────────────────────────────────────────
(defun astraea//org-keybinds ()
  (astraea/leader-def
   "n r" #'org-roam-node-find          ; notes
   "n R" #'org-roam-buffer-toggle
   "n c" #'citar-open                  ; citations
   "n a" #'org-agenda
   "n t" #'org-todo-list
   "n n" #'org-capture
   "n p" #'org-jupyter-start           ; notebook session
   "n x" #'org-export-dispatch))

(defun astraea/org-jupyter-start ()
  "Start a jupyter-python babel session for the current org file."
  (interactive)
  (require 'jupyter)
  (jupyter-run-repl "python3")
  (jupyter-connect-repl (jupyter-get-repl-buffer-name "python3" "py")))

(provide 'astraea-org)
;;; astraea-org.el ends here
