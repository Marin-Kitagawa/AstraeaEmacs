;;; astraea-layer-raku-regex.el --- Astraea layer: +tools/raku-regex -*- lexical-binding: t; -*-
;;
;; Raku (Perl 6) regular expressions for every search and replace
;; surface: isearch, evil `/` and `:s`, query-replace-regexp,
;; replace-regexp, occur, keep/flush-lines and align-regexp.
;;
;; The engine lives in core/astraea-raku-regex.el.  This layer turns it
;; on, adds keybinds and keeps the Raku language layer in sync.
;;
;; Enable with (astraea/enable-layer '+tools/raku-regex).

(astraea-layer! +tools/raku-regex
  ;; raku-mode itself is queued by `astraea-lang-registry' once Emacs
  ;; goes idle, so nothing is installed on the startup path here.
  :init nil
  :config
  (progn
    (astraea-raku-regex-mode 1)
    (unless (astraea/raku-regex-available-p)
      (display-warning
       'astraea
       "raku not found on PATH: the native translator works, but lookaround and exact set operations need Raku++"
       :warning))
    ;; In Raku buffers, make the Raku-engine commands easy to reach
    ;; without shadowing the normal Emacs regexp keys.
    (with-eval-after-load 'raku-mode
      (define-key raku-mode-map (kbd "C-c r s") #'astraea/raku-regex-search)
      (define-key raku-mode-map (kbd "C-c r o") #'astraea/raku-regex-occur)
      (define-key raku-mode-map (kbd "C-c r r") #'astraea/raku-regex-replace-region)
      (define-key raku-mode-map (kbd "C-c r t") #'astraea/raku-regex-test)
      (define-key raku-mode-map (kbd "C-c r d") #'astraea/raku-regex-describe)))
  :keybinds
  (astraea/leader-def
   "s r" #'astraea/raku-regex-search
   "s R" #'astraea/raku-regex-occur
   "s e" #'astraea/raku-regex-replace-region
   "s t" #'astraea/raku-regex-test
   "s d" #'astraea/raku-regex-describe
   "s w" #'astraea/raku-regex-cycle-whitespace
   "T R" #'astraea/raku-regex-toggle))

(provide 'astraea-layer-raku-regex)
;;; astraea-layer-raku-regex.el ends here
