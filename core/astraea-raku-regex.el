;;; astraea-raku-regex.el --- Raku regex search, replace and occur -*- lexical-binding: t; -*-
;;
;; Raku (Perl 6) regex syntax for every search and replace surface in
;; Astraea: incremental search, evil `/` and `:s`, query-replace-regexp,
;; replace-regexp, occur, keep/flush-lines, align-regexp, highlight-regexp
;; and friends.
;;
;; Two engines are provided:
;;
;;   1. Native translation (`astraea/raku-regex-translate') turns a Raku
;;      pattern into an equivalent Emacs regexp so the normal, fast Emacs
;;      machinery (isearch, query-replace, occur…) drives the search.
;;      It covers the everyday language: literals, character classes,
;;      alternation, quantifiers, `**' ranges, captures, named captures,
;;      `<(...)>' match markers, anchors, word boundaries and adverbs.
;;
;;   2. A subprocess engine runs the real `raku' interpreter (Raku++ on
;;      Windows) for constructs Emacs regexps cannot express: lookaround,
;;      set operations on character classes, arbitrary Raku code in a
;;      replacement, etc.  It powers `astraea/raku-regex-search',
;;      `astraea/raku-regex-occur', `astraea/raku-regex-replace-region'
;;      and `astraea/raku-regex-test'.
;;
;; Enable with (astraea-raku-regex-mode 1), or load the
;; `+tools/raku-regex' layer.  Inspect any pattern with
;; `astraea/raku-regex-describe'.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

;; ── Customization ─────────────────────────────────────────────────────────

(defgroup astraea-raku-regex nil
  "Raku regular expressions for Emacs search and replace."
  :group 'astraea
  :prefix "astraea-raku-regex-")

(defcustom astraea-raku-program
  (or (executable-find "raku")
      (executable-find "rakupp")
      (executable-find "raku++")
      "raku")
  "Raku interpreter used by the subprocess engine.
Raku++ installs `raku.exe' and `rakupp.exe'; either works."
  :type 'string)

(defcustom astraea-raku-regex-whitespace 'ignore
  "How whitespace in a Raku pattern is interpreted.
`ignore'    whitespace separates tokens and is not matched (Raku `regex').
`sigspace'  whitespace matches one or more whitespace characters (Raku `rule').
`literal'   whitespace matches exactly one space."
  :type '(choice (const :tag "Ignore (Raku regex)" ignore)
                 (const :tag "Significant (Raku rule)" sigspace)
                 (const :tag "Literal space" literal)))

(defcustom astraea-raku-regex-raw-prefix "emacs:"
  "Prefix that marks a pattern as a plain Emacs regexp.
With this prefix the rest of the pattern is passed through untouched."
  :type 'string)

(defcustom astraea-raku-regex-timeout 5
  "Seconds to wait for the Raku subprocess before giving up."
  :type 'number)

(defcustom astraea-raku-regex-warn-approximations t
  "Warn when a pattern uses constructs the native engine approximates."
  :type 'boolean)

;; ── Translation state ─────────────────────────────────────────────────────

(defvar astraea-raku-regex-mode nil
  "Non-nil when Raku regex syntax is active for search and replace.
Defined by `define-minor-mode' at the end of this file.")

(declare-function evil-delimited-arguments "evil-common" (string number))

(cl-defstruct (astraea-rakure (:constructor astraea-rakure--make)
                              (:copier nil))
  (groups 0)        ; number of Emacs capture groups emitted
  (positional nil)  ; Emacs group numbers in Raku $0, $1 … order
  (names nil)       ; (NAME . GROUP) in Raku $<name> order
  (marker nil)      ; Emacs group number of <( … )>, or nil
  (sigspace nil)    ; whitespace policy for this pattern
  (ignorecase nil)  ; :i seen
  (global nil)      ; :g seen
  (approximations nil)
  (unsupported nil))

(defun astraea/raku-regex--warn (st kind message)
  "Record MESSAGE of KIND (`approx' or `unsupported') in ST."
  (if (eq kind 'unsupported)
      (cl-pushnew message (astraea-rakure-unsupported st) :test #'equal)
    (cl-pushnew message (astraea-rakure-approximations st) :test #'equal)))

(defun astraea/raku-regex--new-group (st &optional name kind)
  "Allocate an Emacs capture group in ST.
NAME registers a named capture; KIND `marker' records the <( )> region.
Returns the 1-based Emacs group number."
  (let ((n (1+ (astraea-rakure-groups st))))
    (setf (astraea-rakure-groups st) n)
    (pcase kind
      ('marker (setf (astraea-rakure-marker st) n))
      ('named  (push (cons name n) (astraea-rakure-names st)))
      (_       (setf (astraea-rakure-positional st)
                     (append (astraea-rakure-positional st) (list n)))))
    n))

;; ── Scanning helpers ──────────────────────────────────────────────────────

(defun astraea/raku-regex--skip-quote (s i)
  "Return index just past the quoted literal starting at I in S."
  (let ((q (aref s i)) (len (length s)) (j (1+ i)))
    (while (and (< j len) (not (eq (aref s j) q)))
      (setq j (if (eq (aref s j) ?\\) (+ j 2) (1+ j))))
    (min len (1+ j))))

(defun astraea/raku-regex--skip-angle (s i)
  "Return index just past the angle construct starting at I in S."
  (let ((len (length s)) (j (1+ i)) (depth 1) (done nil))
    (while (and (< j len) (not done))
      (let ((c (aref s j)))
        (cond
         ((eq c ?\\) (setq j (+ j 2)))
         ((eq c ?<) (setq depth (1+ depth) j (1+ j)))
         ((eq c ?>)
          (setq depth (1- depth) j (1+ j))
          (when (zerop depth) (setq done t)))
         ((memq c '(?' ?\")) (setq j (astraea/raku-regex--skip-quote s j)))
         (t (setq j (1+ j))))))
    j))

(defun astraea/raku-regex--find-close (s i open close)
  "Return the index in S of CLOSE matching the OPEN at I, or nil."
  (let ((len (length s)) (j i) (depth 0) (result nil))
    (while (and (< j len) (not result))
      (let ((c (aref s j)))
        (cond
         ((eq c ?\\) (setq j (+ j 2)))
         ((and (not (eq c open)) (memq c '(?' ?\")))
          (setq j (astraea/raku-regex--skip-quote s j)))
         ((and (not (eq c open)) (eq c ?<))
          (setq j (astraea/raku-regex--skip-angle s j)))
         ((eq c open) (setq depth (1+ depth) j (1+ j)))
         ((eq c close)
          (setq depth (1- depth))
          (if (<= depth 0) (setq result j) (setq j (1+ j))))
         (t (setq j (1+ j))))))
    result))

(defun astraea/raku-regex--split-alternatives (text)
  "Split TEXT on top-level `|' and `||'.
Returns a list of (ALT . SEPARATOR) where SEPARATOR is nil for the
first alternative, \"|\" for longest-match and \"||\" for first-match."
  (let ((len (length text)) (i 0) (start 0) (depth 0) (acc nil))
    (while (< i len)
      (let ((c (aref text i)))
        (cond
         ((eq c ?\\) (setq i (+ i 2)))
         ((memq c '(?' ?\")) (setq i (astraea/raku-regex--skip-quote text i)))
         ((eq c ?<) (setq i (astraea/raku-regex--skip-angle text i)))
         ((eq c ?\[) (setq depth (1+ depth) i (1+ i)))
         ((eq c ?\]) (setq depth (1- depth) i (1+ i)))
         ((eq c ?\() (setq depth (1+ depth) i (1+ i)))
         ((eq c ?\)) (setq depth (1- depth) i (1+ i)))
         ((and (eq c ?|) (zerop depth))
          (let ((sep (if (and (< (1+ i) len) (eq (aref text (1+ i)) ?|)) "||" "|")))
            (push (cons (substring text start i) sep) acc)
            (setq i (+ i (length sep)) start i)))
         (t (setq i (1+ i))))))
    (nreverse (cons (cons (substring text start) nil) acc))))

(defun astraea/raku-regex--literal-p (raw)
  "Return non-nil when RAW is a pure literal (safe to reorder)."
  (let ((len (length raw)) (i 0) (ok t))
    (while (and (< i len) ok)
      (let ((c (aref raw i)))
        (cond
         ((eq c ?\\) (setq i (+ i 2)))
         ((memq c '(?' ?\")) (setq i (astraea/raku-regex--skip-quote raw i)))
         ((memq c '(?\( ?\) ?\[ ?\] ?< ?> ?| ?* ?+ ?? ?^ ?$ ?. ?{ ?}))
          (setq ok nil))
         (t (setq i (1+ i))))))
    ok))

;; ── Literal emission ──────────────────────────────────────────────────────

(defconst astraea/raku-regex--specials
  '(?\[ ?\\ ?^ ?$ ?. ?* ?+ ??)
  "Characters that need a backslash to be literal in an Emacs regexp.
Emacs treats `(', `)', `{', `}', `|' and `]' as literal unless they are
escaped, so they are emitted verbatim.")

(defun astraea/raku-regex--lit (ch st)
  "Return CH as a literal Emacs regexp fragment, honouring `:i' in ST."
  (cond
   ((memq ch astraea/raku-regex--specials)
    (concat "\\" (string ch)))
   ((and (astraea-rakure-ignorecase st)
         (or (and (>= ch ?a) (<= ch ?z))
             (and (>= ch ?A) (<= ch ?Z))))
    (format "[%c%c]" (downcase ch) (upcase ch)))
   (t (string ch))))

(defun astraea/raku-regex--lit-string (s st)
  "Return string S as literal Emacs regexp text."
  (mapconcat (lambda (c) (astraea/raku-regex--lit c st)) (string-to-list s) ""))

;; ── Character classes ─────────────────────────────────────────────────────

(defconst astraea/raku-regex--named-classes
  '(("alpha" . "[[:alpha:]]") ("alnum" . "[[:alnum:]]")
    ("digit" . "[[:digit:]]") ("lower" . "[[:lower:]]")
    ("upper" . "[[:upper:]]") ("space" . "[ \t\n\r\f\v]")
    ("blank" . "[ \t]") ("punct" . "[[:punct:]]")
    ("xdigit" . "[[:xdigit:]]") ("cntrl" . "[[:cntrl:]]")
    ("graph" . "[[:graph:]]") ("print" . "[[:print:]]")
    ("word" . "[[:alnum:]_]") ("ident" . "[[:alpha:]_][[:alnum:]_]*")
    ("ascii" . "[^[:multibyte:]]") ("null" . ""))
  "Raku named character classes and their Emacs equivalents.")

(defun astraea/raku-regex--expand-fragment (frag)
  "Expand a simple class FRAGMENT to a sorted list of char codes, or nil.
Understands literals, `X..Y' ranges and the \\d \\w \\s \\h shorthands."
  (let ((len (length frag)) (i 0) (chars nil) (ok t))
    (while (and (< i len) ok)
      (let ((c (aref frag i)))
        (cond
         ((eq c ?\\)
          (let ((n (and (< (1+ i) len) (aref frag (1+ i)))))
            (let ((add (pcase n
                         (?d (number-sequence ?0 ?9))
                         (?w (append (number-sequence ?0 ?9)
                                     (number-sequence ?a ?z)
                                     (number-sequence ?A ?Z) (list ?_)))
                         (?s (list ?\s ?\t ?\n ?\r ?\f ?\v))
                         (?h (list ?\s ?\t))
                         (_ (setq ok nil) nil))))
              (setq chars (append chars add) i (+ i 2)))))
         ((and (< (+ i 3) len) (eq (aref frag (1+ i)) ?.)
               (eq (aref frag (+ i 2)) ?.))
          (let ((a (aref frag i)) (b (aref frag (+ i 3))))
            (if (<= a b)
                (setq chars (append chars (number-sequence a b)) i (+ i 4))
              (setq ok nil))))
         ((eq c ?.) (setq ok nil))
         (t (push c chars) (setq i (1+ i))))))
    (and ok (sort (delete-dups chars) #'<))))

(defun astraea/raku-regex--compress-chars (chars)
  "Render sorted CHARS as an Emacs class body."
  (let ((out "") (i 0) (n (length chars)))
    (while (< i n)
      (let ((start (nth i chars)) (end (nth i chars)))
        (while (and (< (1+ i) n) (= (nth (1+ i) chars) (1+ end)))
          (setq i (1+ i) end (nth i chars)))
        (setq out
              (concat out
                      (cond
                       ((= start end)
                        (if (memq start '(?\] ?\\ ?^ ?-))
                            (concat "\\" (string start)) (string start)))
                       ((= end (1+ start)) (concat (string start) (string end)))
                       (t (format "%c-%c" start end)))))
        (setq i (1+ i))))
    out))

(defun astraea/raku-regex--class-tokens (content)
  "Split class CONTENT into (OP . FRAGMENT) pairs.
OP is nil for the first operand, then `+', `-' or `&'."
  (let ((len (length content)) (i 0) (start 0) (ops nil) (acc nil))
    (while (< i len)
      (let ((c (aref content i)))
        (cond
         ((eq c ?\\) (setq i (+ i 2)))
         ((and (memq c '(?+ ?- ?&))
               (not (and (> i 0) (eq (aref content (1- i)) ?.)))
               (not (and (< (+ i 2) len) (eq (aref content (1+ i)) ?.)))
               (> i start))
          (push (substring content start i) acc)
          (push c ops)
          (setq start (1+ i) i (1+ i)))
         (t (setq i (1+ i))))))
    (push (substring content start) acc)
    (let ((frags (nreverse acc)) (ops (nreverse ops)) (out nil) (op nil))
      (dolist (f frags)
        (push (cons op f) out)
        (setq op (pop ops)))
      (nreverse out))))

(defun astraea/raku-regex--fragment-body (frag st)
  "Render a single class FRAGMENT as an Emacs class body."
  (let ((expanded (astraea/raku-regex--expand-fragment frag)))
    (cond
     (expanded
      (when (astraea-rakure-ignorecase st)
        (setq expanded
              (sort (delete-dups
                     (append expanded
                             (mapcar (lambda (c)
                                       (cond ((and (>= c ?a) (<= c ?z)) (- c 32))
                                             ((and (>= c ?A) (<= c ?Z)) (+ c 32))
                                             (t c)))
                                     expanded)))
                    #'<)))
      (astraea/raku-regex--compress-chars expanded))
     (t
      (astraea/raku-regex--warn
       st 'approx (format "character class <%s> may over-match" frag))
      (let ((out "") (i 0) (len (length frag)))
        (while (< i len)
          (let ((c (aref frag i)))
            (cond
             ((eq c ?\\)
              (let ((n (and (< (1+ i) len) (aref frag (1+ i)))))
                (setq out (concat out
                                  (pcase n
                                    (?d "0-9") (?w "[:alnum:]_")
                                    (?s " \t\n\r\f\v") (?h " \t")
                                    (_ (if n (string n) "\\\\"))))
                      i (+ i 2))))
             ((and (< (+ i 3) len) (eq (aref frag (1+ i)) ?.)
                   (eq (aref frag (+ i 2)) ?.))
              (setq out (concat out (format "%c-%c" (aref frag i)
                                            (aref frag (+ i 3))))
                    i (+ i 4)))
             ((memq c '(?\] ?\\ ?^ ?-))
              (setq out (concat out "\\" (string c)) i (1+ i)))
             (t (setq out (concat out (string c)) i (1+ i))))))
        out)))))

(defun astraea/raku-regex--class-regex (content negate st)
  "Translate Raku class CONTENT to an Emacs class regexp.
NEGATE inverts the class; ST carries `:i'."
  (let* ((tokens (astraea/raku-regex--class-tokens content))
         (simple (cl-every (lambda (tok) (null (car tok))) tokens)))
    (cond
     (simple
      (concat "[" (if negate "^" "") 
              (astraea/raku-regex--fragment-body (cdr (car tokens)) st) "]"))
     (t
      ;; Set operations are exact only over enumerable ASCII operands.
      (let ((sets (mapcar (lambda (tok)
                            (astraea/raku-regex--expand-fragment (cdr tok)))
                          tokens)))
        (if (cl-every #'identity sets)
            (let ((result (car sets))
                  (rest (cdr sets)))
              (dolist (tok (cdr tokens) result)
                (let ((other (pop rest)))
                  (setq result
                        (pcase (car tok)
                          (?+ (sort (delete-dups (append result other)) #'<))
                          (?- (cl-set-difference result other))
                          (?& (cl-intersection result other))
                          (_ result)))))
              (let ((body (astraea/raku-regex--compress-chars result)))
                (cond
                 ((and (string-empty-p body) negate) ".")
                 ((string-empty-p body)
                  (astraea/raku-regex--warn
                   st 'unsupported "empty character class can never match")
                  "\\(?:\\b\\B\\)")
                 (t (concat "[" (if negate "^" "") body "]")))))
          (astraea/raku-regex--warn
           st 'approx "character class set operation approximated by union")
          (concat "[" (if negate "^" "")
                  (mapconcat (lambda (tok)
                               (astraea/raku-regex--fragment-body (cdr tok) st))
                             tokens "")
                  "]")))))))

;; ── Class expressions: [..] + [..] - [..] & [..] ─────────────────────────

(defun astraea/raku-regex--strip-brackets (s)
  "Strip one pair of surrounding [ ] from S."
  (if (and (> (length s) 1)
           (eq (aref s 0) ?\[)
           (eq (aref s (1- (length s))) ?\]))
      (substring s 1 (1- (length s)))
    s))

(defun astraea/raku-regex--class-split (expr)
  "Split class EXPR into (OP . OPERAND) at top level.
OP is nil for the first operand, then `+', `-' or `&'."
  (let ((len (length expr)) (i 0) (start 0) (depth 0) (acc nil))
    (while (< i len)
      (let ((c (aref expr i)))
        (cond
         ((eq c ?\\) (setq i (+ i 2)))
         ((eq c ?\[) (setq depth (1+ depth) i (1+ i)))
         ((eq c ?\]) (setq depth (1- depth) i (1+ i)))
         ((and (memq c '(?+ ?- ?&)) (zerop depth) (> i start))
          (push (cons nil (substring expr start i)) acc)
          (push (cons c nil) acc)
          (setq start (1+ i) i (1+ i)))
         (t (setq i (1+ i))))))
    (push (cons nil (substring expr start)) acc)
    (let ((out nil) (pending nil))
      (dolist (item (nreverse acc))
        (if (cdr item)
            (progn
              (push (if pending (cons pending (cdr item)) item) out)
              (setq pending nil))
          (setq pending (car item))))
      (nreverse out))))

(defun astraea/raku-regex--class-expr (expr negate st)
  "Translate a Raku class expression EXPR (inside <...>) to Emacs.
EXPR may be `[a..z]', `[a..z] - [aeiou]', `\\d + [a..f]', or `\\d'."
  (let* ((parts (astraea/raku-regex--class-split expr))
         (contents (mapcar (lambda (p)
                             (astraea/raku-regex--strip-brackets
                              (string-trim (cdr p))))
                           parts)))
    (if (and (null (cdr parts)) (null (car (car parts))))
        (astraea/raku-regex--class-regex (car contents) negate st)
      (let ((sets (mapcar #'astraea/raku-regex--expand-fragment contents)))
        (cond
         ((and (not negate) (cl-every #'identity sets))
          (let ((result (car sets))
                (rest (cdr sets)))
            (dolist (part (cdr parts) result)
              (let ((other (pop rest)))
                (setq result
                      (pcase (car part)
                        (?+ (sort (delete-dups (append result other)) #'<))
                        (?- (cl-set-difference result other))
                        (?& (cl-intersection result other))
                        (_ result)))))
            (let ((body (astraea/raku-regex--compress-chars result)))
              (if (string-empty-p body)
                  (progn
                    (astraea/raku-regex--warn
                     st 'unsupported "empty class expression can never match")
                    "\\(?:\\b\\B\\)")
                (concat "[" body "]")))))
         (t
          (when negate
            (astraea/raku-regex--warn
             st 'approx "negated class with set operations approximated"))
          (concat "[" (if negate "^" "")
                  (mapconcat (lambda (c)
                               (astraea/raku-regex--fragment-body c st))
                             contents "")
                  "]")))))))

;; ── Escapes ───────────────────────────────────────────────────────────────

(defun astraea/raku-regex--escape (s i st)
  "Translate the backslash escape at I in S.  Returns (REGEX . NEXT)."
  (let* ((len (length s))
         (n (and (< (1+ i) len) (aref s (1+ i))))
         (next (+ i 2)))
    (cons
     (pcase n
       (?d "[0-9]") (?D "[^0-9]")
       (?w "[[:alnum:]_]") (?W "[^[:alnum:]_]")
       (?s "[ \t\n\r\f\v]") (?S "[^ \t\n\r\f\v]")
       (?h "[ \t]") (?H "[^ \t]")
       (?v "[\n\r\f]") (?V "[^\n\r\f]")
       (?n "\n") (?t "\t") (?r "\r") (?f "\f") (?e "\e") (?a "\a")
       (?N "[^\n]")
       (?b "\\b") (?B "\\B")
       (?A "\\`") (?z "\\'")
       (?x (let ((rest (substring s (+ i 2))))
             (cond
              ((string-match "\\`\\[\\([0-9A-Fa-f]+\\)\\]" rest)
               (setq next (+ i 2 (match-end 0)))
               (char-to-string (string-to-number (match-string 1 rest) 16)))
              ((string-match "\\`\\([0-9A-Fa-f]\\{1,6\\}\\)" rest)
               (setq next (+ i 2 (match-end 0)))
               (char-to-string (string-to-number (match-string 1 rest) 16)))
              (t (astraea/raku-regex--warn st 'approx "malformed \\x escape")
                 (astraea/raku-regex--lit ?x st)))))
       (?o (let ((rest (substring s (+ i 2))))
             (if (string-match "\\`\\[\\([0-7]+\\)\\]" rest)
                 (progn (setq next (+ i 2 (match-end 0)))
                        (char-to-string (string-to-number (match-string 1 rest) 8)))
               (prog1 (astraea/raku-regex--lit ?o st)
                 (astraea/raku-regex--warn st 'approx "malformed \\o escape")))))
       (?\s (astraea/raku-regex--lit ?\s st))
       (?/ (astraea/raku-regex--lit ?/ st))
       (_ (cond
           ((null n) "\\\\")
           ((string-match-p "[[:alnum:]]" (char-to-string n))
            (astraea/raku-regex--warn st 'approx (format "unknown escape \\%c" n))
            (astraea/raku-regex--lit n st))
           (t (astraea/raku-regex--lit n st)))))
     next)))

;; ── Quantifiers and adverbs ───────────────────────────────────────────────

(defun astraea/raku-regex--quantifiers (s i st)
  "Parse quantifiers at I in S.  Returns (SUFFIX . NEXT-INDEX)."
  (let ((len (length s)) (out "") (next i) (done nil))
    (while (and (not done) (< next len))
      (let ((c (aref s next)))
        (cond
         ((and (eq c ?*) (< (1+ next) len) (eq (aref s (1+ next)) ?*))
          ;; ** quantifier (checked before the single-* case)
          (let* ((rest (substring s (+ next 2)))
                 (spaces (if (string-match "\\`[ \t]*" rest) (match-end 0) 0))
                 (body (substring rest spaces))
                 (spec nil)
                 (used 0))
            (cond
             ((string-match "\\`\\([0-9]+\\)\\.\\.\\([0-9]*\\)\\(\\*?\\)" body)
              (let ((lo (match-string 1 body))
                    (hi (match-string 2 body))
                    (star (match-string 3 body)))
                (setq spec (format "%s,%s" lo (if (or (equal star "*") (string-empty-p hi))
                                                  "" hi))
                      used (match-end 0))))
             ((string-match "\\`\\.\\.\\([0-9]+\\)" body)
              (setq spec (format "0,%s" (match-string 1 body))
                    used (match-end 0)))
             ((string-match "\\`\\.\\.\\*" body)
              (setq spec "0," used (match-end 0)))
             ((string-match "\\`\\([0-9]+\\)" body)
              (setq spec (match-string 1 body) used (match-end 0)))
             (t (astraea/raku-regex--warn st 'unsupported "malformed ** quantifier")))
            (if spec
                (setq out (concat out "\\{" spec "\\}")
                      next (+ next 2 spaces used))
              (setq done t))))
         ((memq c '(?* ?+ ??))
          (let* ((lazy (and (< (1+ next) len) (eq (aref s (1+ next)) ??)))
                 (q (string c)))
            (setq out (concat out q (if lazy "?" ""))
                  next (+ next (if lazy 2 1)))))
         (t (setq done t)))))
    (when (and (< next len) (eq (aref s next) ?%))
      (astraea/raku-regex--warn
       st 'unsupported "separator (%) modifier ignored"))
    (cons out next)))

(defun astraea/raku-regex--adverb (s i st)
  "Parse the adverb at I in S.  Returns the next index, or nil."
  (let ((rest (substring s i)))
    (cond
     ((string-match "\\`:i\\(?:gnorecase\\)?\\_>" rest)
      (setf (astraea-rakure-ignorecase st) t)
      (+ i (match-end 0)))
     ((string-match "\\`:s\\(?:igspace\\)?\\_>" rest)
      (setf (astraea-rakure-sigspace st) t)
      (+ i (match-end 0)))
     ((string-match "\\`:g\\(?:lobal\\)?\\_>" rest)
      (setf (astraea-rakure-global st) t)
      (+ i (match-end 0)))
     ((string-match "\\`:x\\(?:perimental\\)?\\_>" rest)
      (+ i (match-end 0)))
     ((string-match "\\`:[a-zA-Z]+\\(?:([^()]*)\\)?" rest)
      (astraea/raku-regex--warn
       st 'unsupported (format "adverb %s ignored" (match-string 0 rest)))
      (+ i (match-end 0)))
     (t nil))))

;; ── Atoms ─────────────────────────────────────────────────────────────────

(defun astraea/raku-regex--angle (s i st)
  "Translate the `<…>' construct starting at I in S.  Returns (REGEX . NEXT)."
  (let* ((end (astraea/raku-regex--skip-angle s i))
         (inner (substring s (1+ i) (max (1+ i) (1- end))))
         (next end))
    (cond
     ;; <( … )> marks the match
     ((string-prefix-p "(" inner)
      (let* ((close (astraea/raku-regex--find-close s (1+ i) ?\( ?\)))
             (body (and close (substring s (+ i 2) close))))
        (if (not body)
            (progn (astraea/raku-regex--warn st 'unsupported "unbalanced <(")
                   (cons "" next))
          (astraea/raku-regex--new-group st nil 'marker)
          (cons (concat "\\(" (astraea/raku-regex--compile body st) "\\)") next))))
     ;; <[...]>, <-[...]>, <+[...]>, and bare <-\d>
     ((string-match "\\`\\([-+]\\)?\\(\\[.*\\]\\)\\'" inner)
      (cons (astraea/raku-regex--class-expr
             (match-string 2 inner) (equal (match-string 1 inner) "-") st)
            next))
     ;; lookaround
     ((string-match "\\`\\([?!]\\)\\(before\\|after\\)\\(.*\\)\\'" inner)
      (astraea/raku-regex--warn
       st 'unsupported
       (format "lookaround <%s%s> dropped" (match-string 1 inner)
               (match-string 2 inner)))
      (cons "" next))
     ((member inner '("at-start" "at-start-of-line")) (cons "\\`" next))
     ((member inner '("at-end" "at-end-of-line")) (cons "\\'" next))
     ((assoc inner astraea/raku-regex--named-classes)
      (cons (cdr (assoc inner astraea/raku-regex--named-classes)) next))
     ((equal inner "ws") (cons "[ \t\n\r\f\v]*" next))
     ;; <-\d>, <+alpha>: class negation/union in non-bracket form
     ((string-match "\\`\\([-+]\\)\\(.+\\)\\'" inner)
      (cons (astraea/raku-regex--class-expr
             (match-string 2 inner) (equal (match-string 1 inner) "-") st)
            next))
     ((string-prefix-p "." inner)
      (cons (or (cdr (assoc (substring inner 1)
                            astraea/raku-regex--named-classes)) "")
            next))
     (t
      (astraea/raku-regex--warn
       st 'unsupported (format "subrule <%s> cannot be translated" inner))
      (cons "" next)))))

(defun astraea/raku-regex--atom (text i st)
  "Parse one atom at I in TEXT.  Returns (REGEX . NEXT)."
  (let ((len (length text)) (c (aref text i)))
    (cond
     ;; double-angle word boundaries come before the < construct
     ((and (eq c ?<) (< (1+ i) len) (eq (aref text (1+ i)) ?<))
      (cons "\\<" (+ i 2)))
     ((and (eq c ?>) (< (1+ i) len) (eq (aref text (1+ i)) ?>))
      (cons "\\>" (+ i 2)))
     ((eq c ?<) (astraea/raku-regex--angle text i st))
     ((eq c ?\\) (astraea/raku-regex--escape text i st))
     ;; capture group
     ((eq c ?\()
      (let ((close (astraea/raku-regex--find-close text i ?\( ?\))))
        (if (not close)
            (progn (astraea/raku-regex--warn st 'unsupported "unbalanced (")
                   (cons (astraea/raku-regex--lit ?\( st) (1+ i)))
          (astraea/raku-regex--new-group st)
          (cons (concat "\\("
                        (astraea/raku-regex--compile (substring text (1+ i) close) st)
                        "\\)")
                (1+ close)))))
     ;; non-capturing group
     ((eq c ?\[)
      (let ((close (astraea/raku-regex--find-close text i ?\[ ?\])))
        (if (not close)
            (progn (astraea/raku-regex--warn st 'unsupported "unbalanced [")
                   (cons (astraea/raku-regex--lit ?\[ st) (1+ i)))
          (cons (concat "\\(?:"
                        (astraea/raku-regex--compile (substring text (1+ i) close) st)
                        "\\)")
                (1+ close)))))
     ;; named capture $<name>=( … )
     ((and (eq c ?$) (< (1+ i) len) (eq (aref text (1+ i)) ?<)
           (string-match "\\`\\$<\\([^>]+\\)>=" (substring text i)))
      (let* ((name (match-string 1 (substring text i)))
             (open (+ i (match-end 0)))
             (close (and (< open len) (eq (aref text open) ?\()
                         (astraea/raku-regex--find-close text open ?\( ?\)))))
        (if (not close)
            (progn (astraea/raku-regex--warn
                    st 'unsupported (format "unbalanced $<%s>=(" name))
                   (cons "" open))
          (astraea/raku-regex--new-group st name 'named)
          (cons (concat "\\("
                        (astraea/raku-regex--compile (substring text (1+ open) close) st)
                        "\\)")
                (1+ close)))))
     ;; named capture back-reference $<name> (no `=' following)
     ((and (eq c ?$) (< (1+ i) len) (eq (aref text (1+ i)) ?<)
           (string-match "\\`\\$<\\([^>]+\\)>" (substring text i)))
      (let* ((name (match-string 1 (substring text i)))
             (group (cdr (assoc name (astraea-rakure-names st))))
             (end (+ i (match-end 0))))
        (cond
         ((and group (<= group 9))
          (cons (concat "\\" (number-to-string group)) end))
         (group
          (astraea/raku-regex--warn
           st 'unsupported (format "back-reference $<%s> to group %d needs the Raku engine" name group))
          (cons "" end))
         (t
          (astraea/raku-regex--warn
           st 'unsupported (format "unknown back-reference $<%s>" name))
          (cons "" end)))))
     ;; positional back-reference $0, $1 …
     ((and (eq c ?$) (< (1+ i) len)
           (string-match "\\`\\$\\([0-9]+\\)" (substring text i)))
      (let* ((idx (string-to-number (match-string 1 (substring text i))))
             (group (nth idx (astraea-rakure-positional st)))
             (end (+ i (match-end 0))))
        (if (and group (<= group 9))
            (cons (concat "\\" (number-to-string group)) end)
          (progn
            (astraea/raku-regex--warn
             st 'unsupported
             (format "back-reference $%d needs the Raku engine" idx))
            (cons "" end)))))
     ((eq c ?^)
      (if (and (< (1+ i) len) (eq (aref text (1+ i)) ?^))
          (cons "^" (+ i 2))
        (cons "\\`" (1+ i))))
     ((eq c ?$)
      (if (and (< (1+ i) len) (eq (aref text (1+ i)) ?$))
          (cons "$" (+ i 2))
        (cons "\\'" (1+ i))))
     ((eq c ?«) (cons "\\<" (1+ i)))
     ((eq c ?») (cons "\\>" (1+ i)))
     ((memq c '(?' ?\"))
      (let ((end (astraea/raku-regex--skip-quote text i)))
        (cons (astraea/raku-regex--lit-string
               (substring text (1+ i) (max (1+ i) (1- end))) st)
              end)))
     ((eq c ?.)
      ;; Raku `.` also matches newline; Emacs `.` does not.
      (cons "\\(?:.\\|\n\\)" (1+ i)))
     (t
      (cons (astraea/raku-regex--lit c st) (1+ i))))))

(defun astraea/raku-regex--compile-seq (text st)
  "Compile the sequence TEXT (no top-level alternation) into an Emacs regexp."
  (let ((i 0) (len (length text)) (out '()))
    (while (< i len)
      (let ((c (aref text i)))
        (cond
         ;; whitespace
         ((memq c '(?\s ?\t ?\n ?\r))
          (let ((j i))
            (while (and (< j len) (memq (aref text j) '(?\s ?\t ?\n ?\r)))
              (setq j (1+ j)))
            ;; leading whitespace (right after the opening of a group or
            ;; after an adverb) is not significant, even with :sigspace
            (when out
              (pcase (astraea-rakure-sigspace st)
                ('t (push "[ \t\n\r]+" out))
                ('sigspace (push "[ \t\n\r]+" out))
                ('literal (push (make-string (- j i) ?\s) out))
                (_ nil)))
            (setq i j)))
         ;; comment
         ((eq c ?#)
          (setq i (or (string-match "\n" text i) len)))
         ;; adverb
         ((and (eq c ?:) (astraea/raku-regex--adverb text i st))
          (setq i (astraea/raku-regex--adverb text i st)))
         ;; stray alternation
         ((eq c ?|)
          (astraea/raku-regex--warn st 'approx "stray | treated literally")
          (push "\\|" out) (setq i (1+ i)))
         (t
          (let* ((atom (astraea/raku-regex--atom text i st))
                 (q (astraea/raku-regex--quantifiers text (cdr atom) st)))
            (push (concat (car atom) (car q)) out)
            (setq i (cdr q)))))))
    (apply #'concat (nreverse out))))

(defun astraea/raku-regex--compile (pattern st)
  "Compile PATTERN (with top-level alternation) using state ST."
  (let* ((alts (astraea/raku-regex--split-alternatives pattern))
         (compiled (mapcar (lambda (alt)
                             (list (car alt) (cdr alt)
                                   (astraea/raku-regex--compile-seq (car alt) st)))
                           alts)))
    (if (null (cdr compiled))
        (nth 2 (car compiled))
      (let* ((can-reorder
              (and (cl-every (lambda (a)
                               (let ((sep (nth 1 a)))
                                 (or (null sep) (equal sep "|"))))
                             compiled)
                   (cl-every (lambda (a) (astraea/raku-regex--literal-p (car a)))
                             compiled)))
             (ordered (if can-reorder
                          (sort (copy-sequence compiled)
                                (lambda (a b) (> (length (car a)) (length (car b)))))
                        compiled)))
        (unless can-reorder
          (when (cl-some (lambda (a) (equal (nth 1 a) "|")) compiled)
            (astraea/raku-regex--warn
             st 'approx "| longest-match falls back to first-match")))
        (if (null (cdr ordered))
            (nth 2 (car ordered))
          (concat "\\(?:" (mapconcat (lambda (a) (nth 2 a)) ordered "\\|") "\\)"))))))

;; ── Public translation API ────────────────────────────────────────────────

(defun astraea/raku-regex-raw-p (pattern)
  "Return non-nil when PATTERN asks for a plain Emacs regexp."
  (and (stringp pattern)
       (> (length astraea-raku-regex-raw-prefix) 0)
       (string-prefix-p astraea-raku-regex-raw-prefix pattern)))

(defun astraea/raku-regex-translate (pattern &optional noerror)
  "Translate Raku regexp PATTERN to an Emacs regexp.
Returns a plist:
  :regex          the Emacs regexp
  :captures       number of capture groups
  :positional     group numbers for Raku $0, $1 …
  :names          alist of (NAME . GROUP)
  :marker         group number of <( … )>, or nil
  :sigspace       non-nil when whitespace is significant
  :ignorecase     non-nil when :i was used
  :global         non-nil when :g was used
  :unsupported    constructs the native engine cannot express
  :approximations constructs that were approximated
  :raku           the original pattern.
With NOERROR, an untranslatable pattern falls back to a quoted literal."
  (if (astraea/raku-regex-raw-p pattern)
      (list :regex (substring pattern (length astraea-raku-regex-raw-prefix))
            :captures 0 :positional nil :names nil :marker nil
            :sigspace nil :ignorecase nil :global nil
            :unsupported nil :approximations nil :raku pattern :raw t)
    (condition-case err
        (let ((st (astraea-rakure--make)))
          (setf (astraea-rakure-sigspace st)
                (pcase astraea-raku-regex-whitespace
                  ('literal 'literal)
                  ('sigspace t)
                  (_ nil)))
          (let ((regex (astraea/raku-regex--compile pattern st)))
            (list :regex regex
                  :captures (astraea-rakure-groups st)
                  :positional (astraea-rakure-positional st)
                  :names (astraea-rakure-names st)
                  :marker (astraea-rakure-marker st)
                  :sigspace (astraea-rakure-sigspace st)
                  :ignorecase (astraea-rakure-ignorecase st)
                  :global (astraea-rakure-global st)
                  :unsupported (astraea-rakure-unsupported st)
                  :approximations (astraea-rakure-approximations st)
                  :raku pattern)))
      (error
       (if noerror
           (list :regex (regexp-quote pattern) :captures 0 :positional nil
                 :names nil :marker nil :sigspace nil :ignorecase nil
                 :global nil :approximations nil
                 :unsupported (list (error-message-string err)) :raku pattern)
         (signal (car err) (cdr err)))))))

(defun astraea/raku-regex-translate-replacement (replacement info &optional target)
  "Translate a Raku replacement REPLACEMENT using capture INFO.
TARGET is `emacs' (default) or `evil'.  Understands $0…$9, $<name>,
$/ (the whole match or the <( … )> region), $& and $$; Emacs \\N and
\\, forms are passed through untouched."
  (let ((len (length replacement)) (i 0) (out "")
        (target (or target 'emacs))
        (warn-st (astraea-rakure--make)))
    (cl-labels ((group-ref (n)
                  (cond
                   ((null n) "")
                   ((<= n 9) (concat "\\" (number-to-string n)))
                   ((eq target 'evil) (concat "\\" (number-to-string n)))
                   (t (format "\\,(match-string %d)" n)))))
      (while (< i len)
        (let ((c (aref replacement i)))
          (cond
           ((eq c ?\\)
            (if (< (1+ i) len)
                (setq out (concat out (substring replacement i (+ i 2))) i (+ i 2))
              (setq out (concat out "\\\\") i (1+ i))))
           ((and (eq c ?$) (< (1+ i) len))
            (let ((n (aref replacement (1+ i))))
              (cond
               ((eq n ?$)
                (setq out (concat out "$") i (+ i 2)))
               ((eq n ?/)
                (setq out (concat out (if (plist-get info :marker)
                                          (group-ref (plist-get info :marker))
                                        "\\&"))
                      i (+ i 2)))
               ((eq n ?&)
                (setq out (concat out "\\&") i (+ i 2)))
               ((eq n ?<)
                (if (string-match "\\`\\$<\\([^>]+\\)>" (substring replacement i))
                    (let* ((name (match-string 1 (substring replacement i)))
                           (group (cdr (assoc name (plist-get info :names)))))
                      (unless group
                        (astraea/raku-regex--warn
                         warn-st 'unsupported (format "unknown capture $<%s>" name)))
                      (setq out (concat out (if group (group-ref group) ""))
                            i (+ i (match-end 0))))
                  (setq out (concat out "$") i (1+ i))))
               ((and (>= n ?0) (<= n ?9))
                (let* ((rest (substring replacement (1+ i)))
                       (digits (and (string-match "\\`[0-9]+" rest)
                                    (match-string 0 rest)))
                       (idx (string-to-number digits))
                       (group (nth idx (plist-get info :positional))))
                  (unless group
                    (astraea/raku-regex--warn
                     warn-st 'unsupported (format "$%d has no matching capture" idx)))
                  (setq out (concat out (if group (group-ref group) ""))
                        i (+ i 1 (length digits)))))
               ((memq n '(?\( ?{))
                (astraea/raku-regex--warn
                 warn-st 'unsupported
                 "code interpolation in a replacement needs the Raku engine")
                (setq out (concat out (string n)) i (+ i 2)))
               (t (setq out (concat out "$") i (1+ i))))))
           (t (setq out (concat out (char-to-string c)) i (1+ i))))))
      (when (and astraea-raku-regex-warn-approximations
                 (astraea-rakure-unsupported warn-st))
        (message "Astraea Raku replacement: %s"
                 (string-join (astraea-rakure-unsupported warn-st) "; ")))
      out)))

(defun astraea/raku-regex-describe (pattern)
  "Show how PATTERN is translated, including captures and warnings."
  (interactive (list (read-string "Raku pattern: ")))
  (let* ((info (astraea/raku-regex-translate pattern t))
         (buf (get-buffer-create "*Astraea Raku Regex*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Raku pattern\n  %s\n\n" pattern))
        (insert (format "Emacs regexp\n  %s\n\n" (plist-get info :regex)))
        (insert (format "Captures\n  total %d\n" (plist-get info :captures)))
        (let ((idx 0))
          (dolist (g (plist-get info :positional))
            (insert (format "  $%d -> group %d\n" idx g))
            (setq idx (1+ idx))))
        (dolist (pair (plist-get info :names))
          (insert (format "  $<%s> -> group %d\n" (car pair) (cdr pair))))
        (when-let* ((m (plist-get info :marker)))
          (insert (format "  <( ... )> -> group %d\n" m)))
        (when-let* ((u (plist-get info :unsupported)))
          (insert "\nUnsupported (native engine)\n")
          (dolist (x u) (insert (format "  - %s\n" x))))
        (when-let* ((a (plist-get info :approximations)))
          (insert "\nApproximated\n")
          (dolist (x a) (insert (format "  - %s\n" x))))
        (special-mode)))
    (pop-to-buffer buf)))

;; ── Subprocess engine (full Raku semantics) ───────────────────────────────

(defun astraea/raku-regex-available-p ()
  "Return non-nil when a Raku interpreter can be executed."
  (and (stringp astraea-raku-program)
       (or (file-executable-p astraea-raku-program)
           (executable-find astraea-raku-program))))

(defun astraea/raku-regex--run-script (script args)
  "Run Raku SCRIPT with ARGS, returning its stdout as a string.
Signals an error with stderr when the interpreter fails."
  (unless (astraea/raku-regex-available-p)
    (user-error "Raku executable not found (customize `astraea-raku-program')"))
  (let* ((prog (or (and (file-executable-p astraea-raku-program)
                        astraea-raku-program)
                   (executable-find astraea-raku-program)))
         (buf (generate-new-buffer " *astraea-raku*"))
         (errbuf (generate-new-buffer " *astraea-raku-err*"))
         (proc (make-process
                :name "astraea-raku"
                :buffer buf
                :stderr errbuf
                :command (append (list prog script) args)
                :connection-type 'pipe
                :coding 'utf-8-unix
                :sentinel #'ignore
                :noquery t))
         (deadline (+ (float-time) astraea-raku-regex-timeout))
         (coding-system-for-read 'utf-8-unix)
         (coding-system-for-write 'utf-8-unix))
    (unwind-protect
        (progn
          (while (and (process-live-p proc) (< (float-time) deadline))
            (accept-process-output proc 0.02))
          (when (process-live-p proc)
            (delete-process proc)
            (user-error "Raku regex timed out after %ss" astraea-raku-regex-timeout))
          (when (/= 0 (process-exit-status proc))
            (user-error "Raku regex failed: %s"
                        (string-trim
                         (with-current-buffer errbuf (buffer-string)))))
          (with-current-buffer buf (buffer-string)))
      (when (buffer-live-p buf) (kill-buffer buf))
      (when (buffer-live-p errbuf) (kill-buffer errbuf)))))

(defconst astraea/raku-regex--spans-script
  (concat
   "use MONKEY-SEE-NO-EVAL;\n"
   "my $pat = slurp @*ARGS[0];\n"
   "my $txt = slurp @*ARGS[1];\n"
   "my $adv = (slurp @*ARGS[2]).trim;\n"
   "my $rx = EVAL('rx' ~ $adv ~ '\u27E6' ~ $pat ~ '\u27E7');\n"
   "my $count = 0;\n"
   "for $txt.match($rx, :g) -> $m {\n"
   "  say $m.from ~ \"\\t\" ~ $m.to;\n"
   "  last if (++$count) >= 200000;\n"
   "}\n")
  "Raku program printing every match span as FROM<TAB>TO.")

(defconst astraea/raku-regex--subst-script
  (concat
   "use MONKEY-SEE-NO-EVAL;\n"
   "my $pat = slurp @*ARGS[0];\n"
   "my $txt = slurp @*ARGS[1];\n"
   "my $rep = slurp @*ARGS[2];\n"
   "my $glob = (slurp @*ARGS[3]).trim eq 'g';\n"
   "my $adv = (slurp @*ARGS[4]).trim;\n"
   "my $rx = EVAL('rx' ~ $adv ~ '\u27E6' ~ $pat ~ '\u27E7');\n"
   "my $fn = EVAL('-> $/ { Q:qq\u27E6' ~ $rep ~ '\u27E7 }');\n"
   "print $glob ?? $txt.subst($rx, $fn, :g) !! $txt.subst($rx, $fn);\n")
  "Raku program applying a real s/// with code-interpolated replacement.")

(defconst astraea/raku-regex--test-script
  (concat
   "use MONKEY-SEE-NO-EVAL;\n"
   "my $pat = slurp @*ARGS[0];\n"
   "my $txt = slurp @*ARGS[1];\n"
   "my $adv = (slurp @*ARGS[2]).trim;\n"
   "my $rx = EVAL('rx' ~ $adv ~ '\u27E6' ~ $pat ~ '\u27E7');\n"
   "my $m = $txt.match($rx);\n"
   "if $m { say \"MATCH \" ~ $m.from ~ '..' ~ $m.to; say \"text: \" ~ $m.Str; say $m.raku }\n"
   "else { say 'NO MATCH' }\n")
  "Raku program showing the first match and its capture tree.")

(defun astraea/raku-regex--split-adverbs (pattern)
  "Strip leading :i :s :g adverbs from PATTERN.
Returns (ADVERB-STRING . PATTERN)."
  (let ((rest pattern) (adv ""))
    (while (string-match "\\`\\(:i\\(?:gnorecase\\)?\\|:s\\(?:igspace\\)?\\|:g\\(?:lobal\\)?\\)"
                         rest)
      (setq adv (concat adv (match-string 1 rest))
            rest (substring rest (match-end 0))))
    (cons adv rest)))

(defun astraea/raku-regex--temp-file (content)
  "Write CONTENT to a new temporary file and return its name."
  (let ((file (make-temp-file "astraea-rakure-" nil ".txt"))
        (coding-system-for-write 'utf-8-unix))
    (with-temp-file file
      (set-buffer-multibyte t)
      (insert content))
    file))

(defun astraea/raku-regex--with-script (script args fn)
  "Write SCRIPT and ARGS temp files, call FN with their names, then clean up."
  (let ((script-file (make-temp-file "astraea-rakure-" nil ".raku"))
        (arg-files nil)
        (coding-system-for-write 'utf-8-unix))
    (unwind-protect
        (progn
          (with-temp-file script-file (insert script))
          (setq arg-files (mapcar #'astraea/raku-regex--temp-file args))
          (apply fn script-file arg-files))
      (ignore-errors (delete-file script-file))
      (dolist (f arg-files) (ignore-errors (delete-file f))))))

(defun astraea/raku-regex-spans (text pattern)
  "Return the list of (START . END) char offsets where PATTERN matches TEXT.
Uses the real Raku engine (0-based offsets)."
  (let* ((split (astraea/raku-regex--split-adverbs pattern))
         (adv (car split)) (pat (cdr split)))
    (astraea/raku-regex--with-script
     astraea/raku-regex--spans-script (list pat text adv)
     (lambda (script patfile txtfile advfile)
       (let ((out (astraea/raku-regex--run-script
                   script (list patfile txtfile advfile))))
         (delq nil
               (mapcar (lambda (line)
                         (when (string-match "\\`\\([0-9]+\\)\t\\([0-9]+\\)" line)
                           (cons (string-to-number (match-string 1 line))
                                 (string-to-number (match-string 2 line)))))
                       (split-string out "\n" t))))))))

(defun astraea/raku-regex-substitute (text pattern replacement &optional global)
  "Apply Raku s/PATTERN/REPLACEMENT/ to TEXT using the real engine.
GLOBAL applies the substitution everywhere.  REPLACEMENT is evaluated
as Raku code, so $0, $1, $<name>, $/ and even method calls work."
  (let* ((split (astraea/raku-regex--split-adverbs pattern))
         (adv (car split)) (pat (cdr split)))
    (astraea/raku-regex--with-script
     astraea/raku-regex--subst-script
     (list pat text replacement (if global "g" "") adv)
     (lambda (script patfile txtfile repfile globfile advfile)
       (astraea/raku-regex--run-script
        script (list patfile txtfile repfile globfile advfile))))))

(defun astraea/raku-regex-test-string (text pattern)
  "Return a human-readable report of the first PATTERN match in TEXT."
  (let* ((split (astraea/raku-regex--split-adverbs pattern))
         (adv (car split)) (pat (cdr split)))
    (astraea/raku-regex--with-script
     astraea/raku-regex--test-script (list pat text adv)
     (lambda (script patfile txtfile advfile)
       (astraea/raku-regex--run-script script (list patfile txtfile advfile))))))

;; ── User-facing Raku-engine commands ──────────────────────────────────────

(defvar astraea/raku-regex-history nil
  "History for Raku regexp prompts.")

(defun astraea/raku-regex-read (prompt)
  "Read a Raku pattern with completion history."
  (let ((input (read-string prompt (car astraea/raku-regex-history)
                            'astraea/raku-regex-history)))
    (push input astraea/raku-regex-history)
    input))

(defun astraea/raku-regex-search (pattern)
  "Search forward for the next real-Raku match of PATTERN."
  (interactive (list (astraea/raku-regex-read "Raku search: ")))
  (let* ((text (buffer-substring-no-properties (point-min) (point-max)))
         (spans (astraea/raku-regex-spans text pattern))
         (here (- (point) (point-min)))
         (hit (or (cl-find-if (lambda (s) (>= (cdr s) here)) spans)
                  (car spans))))
    (if (not hit)
        (user-error "No Raku match for %s" pattern)
      (deactivate-mark)
      (goto-char (+ (point-min) (car hit)))
      (pulse-momentary-highlight-region (point) (+ (point-min) (cdr hit)))
      (message "Match %d..%d of %d" (car hit) (cdr hit) (length spans)))))

(defvar astraea/raku-regex-occur-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "RET") #'astraea/raku-regex-occur-jump)
    map)
  "Keymap for `astraea/raku-regex-occur-mode'.")

(define-derived-mode astraea/raku-regex-occur-mode special-mode "RakuOccur"
  "Major mode for Raku regex occur results.")

(defun astraea/raku-regex--occur-buffer (matches)
  "Render MATCHES, a list of (LINE-NUMBER TEXT MARKER), in a result buffer."
  (let ((buf (get-buffer-create "*Astraea Raku Occur*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "%d matching line%s\n\n"
                        (length matches) (if (= 1 (length matches)) "" "s")))
        (dolist (m matches)
          (let ((start (point)))
            (insert (format "%6d: %s\n" (nth 0 m) (nth 1 m)))
            (add-text-properties start (line-end-position)
                                 `(astraea-rakure-marker ,(nth 2 m)
                                   mouse-face highlight))))
        (goto-char (point-min)))
      (astraea/raku-regex-occur-mode))
    (pop-to-buffer buf)))

(defun astraea/raku-regex-occur-jump ()
  "Jump to the match on the current occur line."
  (interactive)
  (let ((marker (get-text-property (line-beginning-position)
                                   'astraea-rakure-marker)))
    (if (not marker)
        (user-error "No match here")
      (pop-to-buffer (marker-buffer marker))
      (goto-char marker))))

(defun astraea/raku-regex--line-start (text pos)
  "Return the start offset of the line containing POS in TEXT."
  (let ((p (min pos (length text))))
    (while (and (> p 0) (not (eq (aref text (1- p)) ?\n)))
      (setq p (1- p)))
    p))

(defun astraea/raku-regex-occur (pattern)
  "List lines matching the real-Raku PATTERN."
  (interactive (list (astraea/raku-regex-read "Raku occur: ")))
  (let* ((base (point-min))
         (text (buffer-substring-no-properties base (point-max)))
         (spans (astraea/raku-regex-spans text pattern))
         (lines nil))
    (dolist (span spans)
      (let* ((start (car span))
             (ls (astraea/raku-regex--line-start text start))
             (le (or (string-match "\n" text start) (length text)))
             (lineno (1+ (cl-count ?\n text :end start))))
        (unless (and lines (eql (caar lines) lineno))
          (push (list lineno (substring text ls le)
                      (copy-marker (+ base start)))
                lines))))
    (if (null lines)
        (message "No Raku matches for %s" pattern)
      (astraea/raku-regex--occur-buffer (nreverse lines)))))

(defun astraea/raku-regex-replace-region (pattern replacement
                                          &optional beg end global)
  "Replace Raku PATTERN with REPLACEMENT in the region (or buffer).
REPLACEMENT is real Raku code: $0, $1, $<name>, $/ and method calls work.
With a prefix argument, replace every match."
  (interactive
   (let ((pattern (astraea/raku-regex-read "Raku regexp: "))
         (replacement (read-string "Replacement (Raku code): ")))
     (list pattern replacement
           (if (use-region-p) (region-beginning) (point-min))
           (if (use-region-p) (region-end) (point-max))
           current-prefix-arg)))
  (let* ((text (buffer-substring-no-properties beg end))
         (out (astraea/raku-regex-substitute text pattern replacement global)))
    (if (equal text out)
        (message "No Raku match for %s" pattern)
      (let ((inhibit-modification-hooks nil))
        (delete-region beg end)
        (goto-char beg)
        (insert out))
      (message "Replaced with Raku s/%s/.../%s" pattern (if global "g" "")))))

(defun astraea/raku-regex-test (pattern)
  "Show the capture tree of the first real-Raku PATTERN match in the buffer."
  (interactive (list (astraea/raku-regex-read "Raku pattern to test: ")))
  (let* ((text (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (buffer-substring-no-properties (point-min) (point-max))))
         (report (astraea/raku-regex-test-string text pattern))
         (buf (get-buffer-create "*Astraea Raku Match*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Pattern: %s\n\n%s\n" pattern report))
        (special-mode)))
    (pop-to-buffer buf)))

;; ── Global minor mode and integrations ────────────────────────────────────

(defvar astraea-raku-regex--saved-isearch-fun nil
  "Value of `isearch-search-fun-function' before the mode was enabled.")

(defvar astraea-raku-regex--last-info nil
  "Translation info of the most recent search pattern.")

(defvar astraea-raku-regex--advices nil
  "Alist of (COMMAND . ADVICE-FUNCTION) installed by the mode.")

(defvar astraea-raku-regex--known-translations (make-hash-table :test #'equal)
  "Emacs regexps produced by the translator.
Evil re-uses a translated regex as if it were a raw pattern (for `n', `N'
and repeated `:s'), so a translated string must never be translated twice.")

(defun astraea-raku-regex--already-translated-p (string)
  "Return non-nil when STRING is a regexp the translator produced."
  (and (hash-table-p astraea-raku-regex--known-translations)
       (gethash string astraea-raku-regex--known-translations)))

(defun astraea-raku-regex--remember-translation (string)
  "Record STRING as a translator output."
  (when (> (hash-table-count astraea-raku-regex--known-translations) 512)
    (clrhash astraea-raku-regex--known-translations))
  (puthash string t astraea-raku-regex--known-translations))

(defun astraea/raku-regex--safe-translate (pattern)
  "Translate PATTERN, quoting it as a literal when translation fails."
  (if (astraea-raku-regex--already-translated-p pattern)
      pattern
    (let ((info (astraea/raku-regex-translate pattern t)))
      (when (and astraea-raku-regex-warn-approximations
                 (plist-get info :unsupported))
        (message "Astraea Raku: %s"
                 (string-join (plist-get info :unsupported) "; ")))
      (setq astraea-raku-regex--last-info info)
      (astraea-raku-regex--remember-translation (plist-get info :regex))
      (plist-get info :regex))))

(defun astraea/raku-regex--isearch-fun ()
  "Return the search function isearch should call under Raku syntax."
  (let* ((maker (if (functionp astraea-raku-regex--saved-isearch-fun)
                    astraea-raku-regex--saved-isearch-fun
                  #'isearch-search-fun-default))
         (base (funcall maker)))
    (lambda (string bound noerror)
      (funcall base
               (if (and isearch-regexp (not (astraea/raku-regex-raw-p string)))
                   (astraea/raku-regex--safe-translate string)
                 string)
               bound noerror))))

(defun astraea/raku-regex--evil-search-function (orig &rest args)
  "Make evil's search functions understand Raku patterns."
  (let ((fun (apply orig args)))
    (if (and astraea-raku-regex-mode (nth 1 args))
        (lambda (string &optional bound noerror count)
          (funcall fun
                   (if (astraea/raku-regex-raw-p string)
                       string
                     (astraea/raku-regex--safe-translate string))
                   bound noerror count))
      fun)))

(defun astraea/raku-regex--evil-ex-make-pattern (orig regexp case whole-line)
  "Translate REGEXP for evil's ex search and `:s' commands."
  (if (not (and astraea-raku-regex-mode regexp
                (not (astraea/raku-regex-raw-p regexp))
                (not (astraea-raku-regex--already-translated-p regexp))))
      (funcall orig regexp case whole-line)
    (let* ((marker (cond ((string-suffix-p "\\C" regexp) "\\C")
                         ((string-suffix-p "\\c" regexp) "\\c")
                         (t "")))
           (bare (if (string-empty-p marker) regexp
                   (substring regexp 0 (- (length regexp) 2))))
           (info (astraea/raku-regex-translate bare t)))
      (setq astraea-raku-regex--last-info info)
      (astraea-raku-regex--remember-translation
       (concat (plist-get info :regex) marker))
      (funcall orig (concat (plist-get info :regex) marker) case whole-line))))

(defun astraea/raku-regex--evil-ex-get-substitute-info (orig string &optional implicit-r)
  "Record the substitute pattern's captures before evil compiles the replacement.
`evil-ex-get-substitute-info' compiles the replacement before it builds
the pattern, so `astraea-raku-regex--last-info' must be refreshed here
for $0 and $<name> to map to the right capture groups."
  (when (and astraea-raku-regex-mode (stringp string))
    (let* ((args (ignore-errors (evil-delimited-arguments string 3)))
           (pat (car args)))
      (when (and pat (not (string-empty-p pat))
                 (not (string-match-p "\\`[a-zA-Z]" pat))
                 (not (astraea/raku-regex-raw-p pat))
                 (not (astraea-raku-regex--already-translated-p pat)))
        (condition-case nil
            (let ((info (astraea/raku-regex-translate pat t)))
              (setq astraea-raku-regex--last-info info)
              (astraea-raku-regex--remember-translation (plist-get info :regex)))
          (error nil)))))
  (funcall orig string implicit-r))

(defun astraea/raku-regex--evil-compile-replacement (orig replacement)
  "Translate a Raku replacement string for evil's `:s'."
  (if (not astraea-raku-regex-mode)
      (funcall orig replacement)
    (funcall orig
             (astraea/raku-regex-translate-replacement
              replacement astraea-raku-regex--last-info 'evil))))

(defun astraea/raku-regex--arg-advice (position)
  "Return advice translating the POSITION-th argument as a Raku pattern."
  (lambda (orig &rest args)
    (if (not (and astraea-raku-regex-mode
                  (called-interactively-p 'interactive)
                  (stringp (nth position args))))
        (apply orig args)
      (let* ((raw (nth position args))
             (info (astraea/raku-regex-translate raw t)))
        (setf (nth position args) (plist-get info :regex))
        (setq astraea-raku-regex--last-info info)
        (if (plist-get info :ignorecase)
            (let ((case-fold-search t)) (apply orig args))
          (apply orig args))))))

(defun astraea/raku-regex--replace-advice (orig &rest args)
  "Translate the pattern and replacement of query/replace-regexp."
  (if (not (and astraea-raku-regex-mode
                (called-interactively-p 'interactive)
                (stringp (car args))))
      (apply orig args)
    (let* ((from (car args))
           (info (astraea/raku-regex-translate from t))
           (new (append (list (plist-get info :regex)) (cdr args))))
      (when (and (nth 1 new) (stringp (nth 1 new)))
        (setf (nth 1 new)
              (astraea/raku-regex-translate-replacement (nth 1 new) info)))
      (setq astraea-raku-regex--last-info info)
      (if (plist-get info :ignorecase)
          (let ((case-fold-search t)) (apply orig new))
        (apply orig new)))))

(defconst astraea-raku-regex--evil-integrations
  '((evil-search-function . astraea/raku-regex--evil-search-function)
    (evil-ex-make-pattern . astraea/raku-regex--evil-ex-make-pattern)
    (evil-ex-get-substitute-info . astraea/raku-regex--evil-ex-get-substitute-info)
    (evil-compile-replacement . astraea/raku-regex--evil-compile-replacement))
  "Advices bridging Evil's search and `:s' onto the Raku translator.")

(defun astraea-raku-regex--enable-evil (&rest _)
  "Install the Evil integrations for the commands that are loaded."
  (when astraea-raku-regex-mode
    (dolist (spec astraea-raku-regex--evil-integrations)
      (when (fboundp (car spec))
        (unless (advice-member-p (cdr spec) (car spec))
          (advice-add (car spec) :around (cdr spec))
          (push spec astraea-raku-regex--advices))))))

(defun astraea-raku-regex--install-advices ()
  (unless astraea-raku-regex--advices
    (dolist (spec '((occur . 0) (multi-occur . 0) (keep-lines . 0)
                    (flush-lines . 0) (delete-matching-lines . 0)
                    (delete-non-matching-lines . 0) (how-many . 0)
                    (highlight-regexp . 0) (unhighlight-regexp . 0)
                    (align-regexp . 2)))
      (when (fboundp (car spec))
        (let ((adv (astraea/raku-regex--arg-advice (cdr spec))))
          (advice-add (car spec) :around adv)
          (push (cons (car spec) adv) astraea-raku-regex--advices))))
    (dolist (fn '(query-replace-regexp replace-regexp))
      (when (fboundp fn)
        (advice-add fn :around #'astraea/raku-regex--replace-advice)
        (push (cons fn #'astraea/raku-regex--replace-advice)
              astraea-raku-regex--advices)))
    (astraea-raku-regex--enable-evil)
    ;; Evil may not be loaded yet if the mode is enabled early.
    (with-eval-after-load 'evil-search #'astraea-raku-regex--enable-evil)
    (with-eval-after-load 'evil-common #'astraea-raku-regex--enable-evil)))

(defun astraea-raku-regex--remove-advices ()
  (dolist (pair astraea-raku-regex--advices)
    (when (fboundp (car pair))
      (advice-remove (car pair) (cdr pair))))
  (setq astraea-raku-regex--advices nil))

;;;###autoload
(define-minor-mode astraea-raku-regex-mode
  "Use Raku regular expressions for search and replace everywhere.
Affects isearch, evil `/` and `:s`, query-replace-regexp,
replace-regexp, occur, keep/flush-lines, align-regexp and friends.
Prefix a pattern with `astraea-raku-regex-raw-prefix' (default
\"emacs:\") to pass a plain Emacs regexp through untouched."
  :global t
  :group 'astraea-raku-regex
  :lighter " Raku"
  (if astraea-raku-regex-mode
      (progn
        ;; Enabling twice must not save our own wrapper as the base.
        (unless (eq isearch-search-fun-function #'astraea/raku-regex--isearch-fun)
          (setq astraea-raku-regex--saved-isearch-fun isearch-search-fun-function)
          (setq isearch-search-fun-function #'astraea/raku-regex--isearch-fun))
        (astraea-raku-regex--install-advices)
        (unless (astraea/raku-regex-available-p)
          (display-warning
           'astraea
           "astraea-raku-regex: `raku' not found on PATH; only the native translator is available"
           :warning)))
    (setq isearch-search-fun-function astraea-raku-regex--saved-isearch-fun)
    (setq astraea-raku-regex--saved-isearch-fun nil)
    (astraea-raku-regex--remove-advices)))

(defun astraea/raku-regex-toggle ()
  "Toggle `astraea-raku-regex-mode'."
  (interactive)
  (astraea-raku-regex-mode (if astraea-raku-regex-mode -1 1)))

(defun astraea/raku-regex-cycle-whitespace ()
  "Cycle how whitespace inside Raku patterns is treated.
`ignore' is Raku's `regex' default, `sigspace' is its `rule'
behaviour (a space matches a whitespace run), `literal' matches a
plain space."
  (interactive)
  (setq astraea-raku-regex-whitespace
        (pcase astraea-raku-regex-whitespace
          ('ignore 'sigspace)
          ('sigspace 'literal)
          (_ 'ignore)))
  (message "Raku regex whitespace: %s" astraea-raku-regex-whitespace))

(provide 'astraea-raku-regex)
;;; astraea-raku-regex.el ends here
