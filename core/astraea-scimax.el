;;; astraea-scimax.el --- scimax feature ports for org & writing -*- lexical-binding: t; -*-
;;
;; Ports of the most valuable self-contained scimax behaviors:
;;   scimax-ob.el                  → notebook-style src block execution
;;   scimax-org-radio-checkbox.el  → radio button lists (#+attr_org: :radio)
;;   scimax-org-images.el          → inline images auto-refresh after babel
;;   scimax-autoformat-abbrev.el   → fractions, ordinals, auto-capitalize
;;   scimax-lob.el                 → library of babel auto-ingest
;;   scimax-journal.el             → org-journal integration
;;   scimax-org (presentation)     → org-present
;;   scimax-statistics/words       → wc-mode + research menu
;; Features requiring external services (mu4e email, twitter, ldap, mogrify)
;; are intentionally not ported.

;; ── Notebook-style src blocks (scimax-ob) ───────────────────────────
(defun astraea/org-display-inline-images ()
  "Refresh inline images after babel execution (scimax behavior)."
  (when (and (boundp 'org-babel-after-execute-hook)
             (fboundp 'org-display-inline-images))
    (org-display-inline-images nil t)))

(defun astraea/org-babel-after-execute-hook ()
  (when (bound-and-true-p org-confirm-babel-evaluate) nil)
  (astraea/org-display-inline-images))

(defun astraea/ob-execute-and-next-block ()
  "Execute the current src block, then jump to the next block of the
same language (creating one if none exists) — jupyter cell flow."
  (interactive)
  (let ((lang (nth 0 (org-babel-get-src-block-info t))))
    (org-babel-execute-src-block)
    (let ((next (save-excursion
                  (forward-line)
                  (re-search-forward (format "#\\+begin_src +\\(%s\\)" lang) nil t))))
      (if next
          (goto-char next)
        (goto-char (org-babel-end-of-block))
        (insert (format "\n#+begin_src %s\n\n#+end_src\n" lang))
        (forward-line -2)))))

(defun astraea/ob-execute-to-point ()
  "Execute all src blocks above point."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((end (point)))
      (while (re-search-forward "#\\+begin_src " end t)
        (org-babel-execute-src-block)))))

(defun astraea/ob-insert-cell ()
  "Insert a new empty src block (cell) below the current one."
  (interactive)
  (let* ((info (org-babel-get-src-block-info t))
         (lang (or (nth 0 info) "python")))
    (goto-char (org-babel-end-of-block))
    (insert (format "\n#+begin_src %s\n\n#+end_src\n" lang))
    (forward-line -2)))

;; ── Radio checkbox lists (scimax-org-radio-checkbox) ────────────────
(defun astraea/org-radio-checkbox ()
  "When point is on a checkbox in a list marked `#+attr_org: :radio',
set this item to [X] and clear every other checkbox in the same list.
Installed in `org-ctrl-c-ctrl-c-final-hook'; return t when handled."
  (interactive)
  (when (org-at-item-checkbox-p)
    (let* ((el (org-element-context))
           (plain (org-element-lineage el '(plain-list) t))
           (radio (and plain
                       (cl-some (lambda (kw)
                                  (and (stringp kw)
                                       (string-match-p ":radio" kw)))
                                (org-element-property :attr_org plain)))))
      (when radio
        (let ((beg (org-element-property :begin plain))
              (end (org-element-property :end plain)))
          (save-excursion
            (goto-char beg)
            (while (re-search-forward "\\[\\(?: \\|X\\)\\]" end t)
              (replace-match "[ ]" t t)))
          (beginning-of-line)
          (when (re-search-forward "\\[\\( \\|X\\)\\]" (line-end-position) t)
            (replace-match "[X]" t t))
          t)))))

(add-hook 'org-ctrl-c-ctrl-c-final-hook #'astraea/org-radio-checkbox)

;; ── Library of babel auto-ingest (scimax-lob) ───────────────────────
(defun astraea/lob-ingest-directory ()
  "Ingest every .org file in ~/.astraea.d/org/lob/ as callable blocks."
  (let ((dir (expand-file-name "org/lob/" astraea-user-directory)))
    (when (file-directory-p dir)
      (dolist (f (directory-files dir t "\\.org\\'"))
        (org-babel-lob-ingest f)))))
(with-eval-after-load 'org
  (run-with-idle-timer 5 nil #'astraea/lob-ingest-directory))

;; ── Autoformat: fractions + sentence auto-capitalize ────────────────
(defcustom astraea-autoformat-excluded-modes
  '(prog-mode special-mode org-agenda-mode dired-mode)
  "Modes where autoformatting stays off (src blocks are always skipped)."
  :type 'hook)

(defvar astraea-autoformat--sentence-boundary nil
  "Internal: capitalize the next typed letter.")

(defconst astraea-autoformat-fractions
  '(("1/2" . "½") ("1/4" . "¼") ("3/4" . "¾") ("1/3" . "⅓")
    ("2/3" . "⅔") ("1/8" . "⅛") ("3/8" . "⅜") ("5/8" . "⅝") ("7/8" . "⅞"))
  "ASCII fractions replaced with unicode on the fly.")

(defun astraea/autoformat--in-excluded-context ()
  (or (derived-mode-p 'prog-mode 'special-mode)
      (and (derived-mode-p 'org-mode)
           (fboundp 'org-in-src-block-p)
           (org-in-src-block-p t))))

(defun astraea/autoformat-post-self-insert ()
  (when (not (astraea/autoformat--in-excluded-context))
    ;; fractions
    (let* ((end (point))
           (beg (max (point-min) (- end 3)))
           (text (buffer-substring-no-properties beg end)))
      (when-let* ((frac (cdr (assoc text astraea-autoformat-fractions))))
        (delete-region beg end)
        (insert frac)))
    ;; sentence auto-capitalize
    (when (and astraea-autoformat--sentence-boundary
               (not (eq last-command this-command)))
      (save-excursion
        (backward-char 1)
        (when (looking-at "[a-z]")
          (capitalize-word 1))))
    (setq astraea-autoformat--sentence-boundary
          (and (looking-back "[.!?] " 3)
               (looking-at-p " ")
               t))))

;;;###autoload
(define-minor-mode astraea-autoformat-mode
  "Typing aids: unicode fractions, sentence auto-capitalize (scimax port)."
  :global t
  :group 'astraea
  (if astraea-autoformat-mode
      (add-hook 'post-self-insert-hook #'astraea/autoformat-post-self-insert)
    (remove-hook 'post-self-insert-hook #'astraea/autoformat-post-self-insert)))

(astraea-autoformat-mode 1)

;; ── word count (scimax-statistics-lite) ─────────────────────────────
(elpaca wc-mode
  (add-hook 'org-mode-hook #'wc-mode)
  (add-hook 'markdown-mode-hook #'wc-mode)
  (add-hook 'adoc-mode-hook #'wc-mode))

;; ── journal (scimax-journal) ────────────────────────────────────────
(elpaca org-journal
  (setq org-journal-dir (expand-file-name "org/journal/" astraea-user-directory)
        org-journal-date-prefix "#+title: "
        org-journal-time-prefix "* "
        org-journal-file-format "%Y-%m-%d.org"
        org-journal-date-format "%A, %Y-%m-%d")
  (make-directory org-journal-dir t))

;; ── presentations (org-show equivalent, lighter) ────────────────────
(elpaca org-present
  (add-hook 'org-present-mode-hook
            (lambda ()
              (setq visual-line-fill-column 100)
              (org-display-inline-images)
              (text-scale-set 2)))
  (add-hook 'org-present-mode-quit-hook
            (lambda ()
              (text-scale-set 0))))

;; ── spell checking (scimax-spellcheck equivalent) ───────────────────
(elpaca flyspell-correct
  (with-eval-after-load 'flyspell
    (define-key flyspell-mode-map (kbd "C-;") #'flyspell-correct-wrapper)))

;; ── research menu (scimax words.el lightweight port) ────────────────
(defun astraea/research-word ()
  "Word at point, or prompt."
  (or (thing-at-point 'word t) (read-string "Word: ")))

(defun astraea/define-word-inline ()
  "Look up the word at point with dictionaryapi.dev and show
pronunciations + definitions in a help buffer (no API key needed)."
  (interactive)
  (let* ((word (astraea/research-word))
         (url (format "https://api.dictionaryapi.dev/api/v2/entries/en/%s" word))
         (buf (url-retrieve-synchronously url nil nil 10)))
    (if (not buf)
        (user-error "Could not reach dictionaryapi.dev")
      (with-current-buffer buf
        (goto-char (point-min))
        (when (re-search-forward "No Definitions Found" nil t)
          (kill-buffer)
          (user-error "No definitions for %s" word))
        (goto-char (point-min))
        (re-search-forward "^\\[")
        (let* ((json (json-parse-buffer :array-type list :object-type alist))
               (entry (aref (vconcat json) 0))
               (phon (cdr (assoc "phonetic" entry)))
               (meanings (cdr (assoc "meanings" entry))))
          (with-current-buffer (get-buffer-create "*Define Word*")
            (erase-buffer)
            (insert (format "✦ %s%s\n\n" word (if phon (format "  /%s/" phon) "")))
            (dolist (m meanings)
              (insert (format "■ %s\n" (cdr (assoc "partOfSpeech" m))))
              (let ((i 1))
                (dolist (d (cdr (assoc "definitions" m)))
                  (insert (format "  %d. %s\n" i (cdr (assoc "definition" d))))
                  (when-let ((ex (cdr (assoc "example" d))))
                    (insert (format "     example: %s\n" ex)))
                  (setq i (1+ i)))
                (insert "\n")))
            (goto-char (point-min))
            (special-mode)
            (pop-to-buffer (current-buffer))))
        (kill-buffer buf)))))

(defun astraea/research (engine)
  "Look up the word at point (or read one) with ENGINE's URL template."
  (let* ((word (astraea/research-word))
         (url (pcase engine
                ('google  (format "https://google.com/search?q=%s" word))
                ('scholar (format "https://scholar.google.com/scholar?q=%s" word))
                ('arxiv   (format "https://arxiv.org/abs/%s" word))
                ('pubmed  (format "https://pubmed.ncbi.nlm.nih.gov/?term=%s" word))
                ('dict    (format "https://www.merriam-webster.com/dictionary/%s" word))
                ('thes    (format "https://www.thesaurus.com/browse/%s" word))
                ('wiktionary (format "https://en.wiktionary.org/wiki/%s" word))
                ('urban   (format "https://www.urbandictionary.com/define.php?term=%s" word)))))
    (browse-url url)))

(transient-define-prefix astraea/research-menu ()
  "Word at point research menu (scimax words.el port)."
  ["Research word at point"
   [("g" "Google"    (lambda () (interactive) (astraea/research 'google)) :transient nil)
    ("s" "Scholar"   (lambda () (interactive) (astraea/research 'scholar)) :transient nil)
    ("a" "arXiv"     (lambda () (interactive) (astraea/research 'arxiv)) :transient nil)
    ("p" "PubMed"    (lambda () (interactive) (astraea/research 'pubmed)) :transient nil)]
   [("d" "Dictionary" (lambda () (interactive) (astraea/research 'dict)) :transient nil)
    ("t" "Thesaurus"  (lambda () (interactive) (astraea/research 'thes)) :transient nil)
    ("w" "Wiktionary" (lambda () (interactive) (astraea/research 'wiktionary)) :transient nil)
    ("u" "Urban"      (lambda () (interactive) (astraea/research 'urban)) :transient nil)]
   [("D" "Definitions (inline)" astraea/define-word-inline :transient nil)]])

(provide 'astraea-scimax)
;;; astraea-scimax.el ends here
