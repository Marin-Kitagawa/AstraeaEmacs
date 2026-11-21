;;; test-raku-regex.el --- tests for astraea-raku-regex -*- lexical-binding: t; -*-
;;
;; Run with:
;;   emacs --batch -l tests/test-raku-regex.el
;;
;; The native translator is cross-checked against the real Raku
;; interpreter: every pattern in `astraea-rakure-test-cases' must produce
;; the same match spans natively and under `raku'.

(setq user-emacs-directory
      (file-name-as-directory (expand-file-name ".." (file-name-directory
                                                      (or load-file-name buffer-file-name)))))
(add-to-list 'load-path (expand-file-name "core" user-emacs-directory))
(require 'astraea-raku-regex)

(defvar astraea-rakure-test-failures 0)
(defvar astraea-rakure-test-count 0)

(defun astraea-rakure-test--check (name ok &optional detail)
  (setq astraea-rakure-test-count (1+ astraea-rakure-test-count))
  (unless ok
    (setq astraea-rakure-test-failures (1+ astraea-rakure-test-failures))
    (message "FAIL %-40s %s" name (or detail ""))))

(defun astraea-rakure-test--emacs-spans (regex text)
  "Return match spans of REGEX in TEXT, Raku :g style."
  (let ((start 0) (len (length text)) (out nil) (guard 0))
    (while (and (< start (1+ len)) (< guard 1000)
                (string-match regex text start))
      (setq guard (1+ guard))
      (push (cons (match-beginning 0) (match-end 0)) out)
      (setq start (if (= (match-end 0) (match-beginning 0))
                      (1+ (match-end 0))
                    (match-end 0))))
    (nreverse out)))

(defconst astraea-rakure-test-cases
  '(("simple"            "abc"                "xxabcxx")
    ("dot-newline"       "a.b"                "a\nb")
    ("digit-plus"        "\\d+"               "a1b22c333")
    ("word"              "\\w+"               "foo-bar baz")
    ("space-class"       "\\s+"               "a \t b")
    ("group-literal"     "[abc]"              "xabcx")
    ("group-alt"         "[foo|bar]"          "a foo b")
    ("nested-group"      "[x|z][y|w]"         "xy zw ab")
    ("charclass-range"   "<[a..z]>+"          "abc 123 def")
    ("charclass-neg"     "<-[0..9]>+"          "ab12cd")
    ("charclass-diff"    "<[a..z] - [aeiou]>" "aeiouxyz")
    ("named-class"       "<alpha>+"           "ab12cd")
    ("quant-star"        "ab*c"               "ac abbc abbbc")
    ("quant-lazy"        "a+?"                "aaa")
    ("quant-exact"       "a**3"               "aa aaa aaaa")
    ("quant-range"       "a**2..3"            "a aa aaa aaaa")
    ("quant-open"        "a**2..*"            "a aa aaa")
    ("alt-longest"       "a|ab|abc"           "abc")
    ("alt-first"         "a||ab"              "ab")
    ("anchor-start"      "^b"                 "a\nb")
    ("anchor-line"       "^^b"                "a\nb")
    ("anchor-end"        "b$"                 "ab\ncd")
    ("anchor-dollarline" "ab$$"               "ab\ncd")
    ("word-boundary"     "<<bar>>"            "foo bar barfoo")
    ("sigspace"          ":s a b"             "ab a b  c")
    ("ignorecase"        ":i abc"             "ABC abc AbC")
    ("escaped-paren"     "\\( a \\)"          "x(a)y")
    ("quoted-literal"    "'a.b'"              "a.b axb")
    ("hex-escape"        "\\x41+"             "xAAAy")
    ("capture-two"       "(a)(b)"             "ab")
    ("named-capture"     "$<x>=(a)(b)"        "ab")
    ("backref-named"     "$<x>=(ab)$<x>"      "abab abcd")
    ("backref-positional" "(ab)$0"            "abab abcd")))

(defun astraea-rakure-test--native-vs-raku ()
  "Compare native translation spans with the real Raku engine."
  (unless (astraea/raku-regex-available-p)
    (message "SKIP native-vs-raku: no raku executable")
    (ignore astraea-rakure-test-cases)
    (setq astraea-rakure-test-cases nil))
  (dolist (case astraea-rakure-test-cases)
    (let* ((name (nth 0 case))
           (pattern (nth 1 case))
           (text (nth 2 case))
           (info (astraea/raku-regex-translate pattern t))
           (native (astraea-rakure-test--emacs-spans
                    (plist-get info :regex) text))
           (real (condition-case err
                     (astraea/raku-regex-spans text pattern)
                   (error (list (error-message-string err))))))
      (if (and real (stringp (car real)))
          (astraea-rakure-test--check name nil
                                      (format "raku error: %s" (car real)))
        (astraea-rakure-test--check
         name (equal native real)
         (format "native=%S raku=%S regex=%S" native real
                 (plist-get info :regex)))))))

(defun astraea-rakure-test--translation-shapes ()
  "Check capture numbering and replacement translation."
  ;; (a)(b): $0 -> group 1, $1 -> group 2
  (let* ((info (astraea/raku-regex-translate "(a)(b)"))
         (repl (astraea/raku-regex-translate-replacement "$0-$1" info)))
    (astraea-rakure-test--check "repl-positional" (equal repl "\\1-\\2")
                                (format "%S" repl)))
  ;; named captures do not consume positional slots (Raku: $m[0] is (b))
  (let* ((info (astraea/raku-regex-translate "$<x>=(a)(b)"))
         (repl (astraea/raku-regex-translate-replacement
                "$<x>|$0|$1" info)))
    (astraea-rakure-test--check "repl-named" (equal repl "\\1|\\2|")
                                (format "%S" repl))
    (astraea-rakure-test--check "named-map"
                                (equal (assoc "x" (plist-get info :names))
                                       '("x" . 1))
                                (format "%S" (plist-get info :names))))
  ;; whole-match and marker
  (let* ((info (astraea/raku-regex-translate "a <( b )> c"))
         (repl (astraea/raku-regex-translate-replacement "$/" info)))
    (astraea-rakure-test--check "repl-marker" (equal repl "\\1")
                                (format "%S" repl)))
  ;; $$ and escapes
  (let* ((info (astraea/raku-regex-translate "x"))
         (repl (astraea/raku-regex-translate-replacement "$$ \\1" info)))
    (astraea-rakure-test--check "repl-dollar-escape" (equal repl "$ \\1")
                                (format "%S" repl))))

(defun astraea-rakure-test--raw-prefix ()
  (let ((info (astraea/raku-regex-translate "emacs:\\(foo\\)")))
    (astraea-rakure-test--check "raw-prefix" (equal (plist-get info :regex) "\\(foo\\)")
                                (format "%S" (plist-get info :regex)))))

(defun astraea-rakure-test--unsupported ()
  (let ((info (astraea/raku-regex-translate "a <?before b>")))
    (astraea-rakure-test--check "lookaround-flagged"
                                (and (plist-get info :unsupported) t)
                                (format "%S" (plist-get info :unsupported)))))

(defun astraea-rakure-test--subprocess-substitute ()
  (when (astraea/raku-regex-available-p)
    (astraea-rakure-test--check
     "subprocess-subst"
     (equal (astraea/raku-regex-substitute "abc123" "(\\d+)" "<$0>") "abc<123>"))
    (astraea-rakure-test--check
     "subprocess-subst-global"
     (equal (astraea/raku-regex-substitute "a-a-a" "a" "b" t) "b-b-b"))
    (astraea-rakure-test--check
     "subprocess-subst-code"
     (equal (astraea/raku-regex-substitute "abc" "(a)" "{$0.uc}") "Abc"))))

(defun astraea-rakure-test--integration ()
  "Exercise the mode plumbing and the buffer commands."
  (astraea-raku-regex-mode 1)
  (astraea-rakure-test--check "mode-on" astraea-raku-regex-mode)
  ;; isearch translation
  (let ((fun (astraea/raku-regex--isearch-fun)))
    (astraea-rakure-test--check "isearch-fun" (functionp fun))
    (with-temp-buffer
      (insert "foo 123 bar")
      (goto-char (point-min))
      (let ((isearch-regexp t)
            (isearch-forward t))
        (astraea-rakure-test--check
         "isearch-match" (and (funcall fun "\\d+" nil t) t)))))
  ;; buffer commands with the real engine
  (when (astraea/raku-regex-available-p)
    (with-temp-buffer
      (insert "one 1\ntwo 2\nthree 3\n")
      (let ((inhibit-message t))
        (astraea/raku-regex-occur "\\d"))
      (astraea-rakure-test--check
       "occur-buffer"
       (with-current-buffer "*Astraea Raku Occur*"
         (string-match-p "three 3" (buffer-string)))
       (with-current-buffer "*Astraea Raku Occur*" (buffer-string)))
      (kill-buffer "*Astraea Raku Occur*"))
    (with-temp-buffer
      (insert "abc123")
      (astraea/raku-regex-replace-region "(\\d+)" "N" (point-min) (point-max) t)
      (astraea-rakure-test--check "region-replace" (equal (buffer-string) "abcN")
                                  (buffer-string))))
  ;; interactive advice paths: pattern + replacement translation
  (cl-letf (((symbol-function 'called-interactively-p) (lambda (&rest _) t)))
    (astraea-rakure-test--check
     "advice-query-replace"
     (equal (astraea/raku-regex--replace-advice
             (lambda (from to &rest _) (list from to))
             "(\\d+)" "<$0>")
            '("\\([0-9]+\\)" "<\\1>"))
     (format "%S" (astraea/raku-regex--replace-advice
                   (lambda (from to &rest _) (list from to))
                   "(\\d+)" "<$0>")))
    (astraea-rakure-test--check
     "advice-occur"
     (equal (funcall (astraea/raku-regex--arg-advice 0)
                     (lambda (re &rest _) re) "\\d+")
            "[0-9]+")))
  ;; :s plumbing through evil, when it can be loaded
  (let ((evil-dir (expand-file-name "elpaca/builds/evil" user-emacs-directory)))
    (when (file-directory-p evil-dir)
      (add-to-list 'load-path evil-dir)
      (condition-case err
          (progn
            (let ((inhibit-message t))
              (require 'evil)
              (astraea-raku-regex--enable-evil))
            (let* ((info (evil-ex-get-substitute-info "/(\\d+)/<$0>/"))
                   (pattern (nth 0 info))
                   (replacement (nth 1 info)))
              (astraea-rakure-test--check
               "evil-pattern"
               (equal (evil-ex-pattern-regex pattern) "\\([0-9]+\\)")
               (format "%S" (and pattern (evil-ex-pattern-regex pattern))))
              (astraea-rakure-test--check
               "evil-replacement"
               (equal (cdr replacement) "<\\1>")
               (format "%S" replacement))))
        (error
         (astraea-rakure-test--check "evil-integration" nil
                                     (error-message-string err))))))
  (astraea-raku-regex-mode -1))

(defun astraea-raku-regex-test-run ()
  "Run all Raku regex tests."
  (astraea-rakure-test--native-vs-raku)
  (astraea-rakure-test--translation-shapes)
  (astraea-rakure-test--raw-prefix)
  (astraea-rakure-test--unsupported)
  (astraea-rakure-test--subprocess-substitute)
  (astraea-rakure-test--integration)
  (message "Raku regex tests: %d checks, %d failures"
           astraea-rakure-test-count astraea-rakure-test-failures)
  (kill-emacs (if (zerop astraea-rakure-test-failures) 0 1)))

(astraea-raku-regex-test-run)
;;; test-raku-regex.el ends here
