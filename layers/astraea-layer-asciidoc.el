;;; astraea-layer-asciidoc.el --- Astraea layer: +lang/asciidoc -*- lexical-binding: t; -*-
;;
;; AsciiDoc / Asciidoctor support via `adoc-mode' (bbatsov/adoc-mode):
;; rich syntax highlighting, outline folding, native fontification of
;; source blocks, inline image previews, and Asciidoctor preview/export.
;;
;; `adoc-mode' is also listed in `astraea-lang-registry' (language
;; `asciidoc'), which installs it by default.  This layer adds the
;; round-trip Asciidoctor workflow on top: sensible editing defaults and
;; autoloaded preview / export commands bound under the `m a' leader.
;;
;; Preview and export shell out to the `asciidoctor' CLI, so it must be
;; on PATH; PDF and EPUB also need asciidoctor-pdf / asciidoctor-epub3.
;; Enable with (astraea/enable-layer '+lang/asciidoc).

(astraea-layer! +lang/asciidoc
  :packages (adoc-mode)
  :init
  (progn
    ;; the language registry may already have queued `adoc-mode'; don't
    ;; queue it twice.
    (unless (and (fboundp 'elpaca-get) (elpaca-get 'adoc-mode))
      (eval '(elpaca adoc-mode) t)))
  :config
  (progn
    ;; .adoc / .asciidoc are claimed by adoc-mode's autoloads; add .asc and
    ;; the AsciiDoc-flavoured .txt so those files open in adoc-mode too.
    (add-to-list 'auto-mode-alist '("\\.asc\\'" . adoc-mode))
    (add-to-list 'auto-mode-alist '("\\.asciidoc\\.txt\\'" . adoc-mode))
    (with-eval-after-load 'adoc-mode
      (setq adoc-fontify-code-blocks-natively 5000  ; colour short source blocks
            adoc-display-images t                    ; inline image previews
            adoc-max-image-size '(640 . 480)         ; cap oversized images
            adoc-enable-two-line-title nil)          ; one-line titles only
      (add-hook 'adoc-mode-hook
                (lambda ()
                  (outline-minor-mode 1)             ; TAB / S-TAB folding
                  (when (require 'flymake nil t)
                    (flymake-mode 1)))))             ; Asciidoctor diagnostics
    (unless (executable-find "asciidoctor")
      (display-warning
       'astraea
       "adoc-mode preview/export need the `asciidoctor' CLI on PATH (gem install asciidoctor)"
       :warning)))
  :keybinds
  (astraea/leader-def
   "m a p" #'adoc-preview
   "m a l" #'adoc-live-preview-mode
   "m a v" #'visual-line-mode
   "m a h" #'adoc-export-html
   "m a d" #'adoc-export-docbook
   "m a P" #'adoc-export-pdf
   "m a e" #'adoc-export-epub))

(provide 'astraea-layer-asciidoc)
;;; astraea-layer-asciidoc.el ends here
