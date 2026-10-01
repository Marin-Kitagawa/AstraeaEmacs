;;; astraea-ide.el --- LSP, formatting, debugging, treesitter, flymake -*- lexical-binding: t; -*-
;;
;; AstroNvim LSP stack, translated:
;;   nvim-lspconfig + mason   → eglot (built-in) or lsp-mode + lsp-pyright…
;;   conform.nvim             → apheleia (async, never blocks)
;;   nvim-dap + mason-dap     → dape
;;   none-ls diagnostics      → flymake + flymake-collection
;;   treesitter               → Emacs 30+ built-in treesit (no config needed)
;;   lsp_signature            → eldoc-box floating docs

;; ── Eglot (default: fast, zero-config, built-in) ─────────────────────────
(defvar astraea//eglot-hook '())
(when (eq astraea-lsp-backend 'eglot)
  (setq eglot-autoshutdown t
        eglot-events-buffer-size 0       ; perf: don't log everything
        eglot-sync-connect nil           ; never block opening files
        eglot-send-changes-idle-time 0.3
        eldoc-echo-area-use-multiline-p nil)
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (eldoc-add-command 'corfu-insert)
              (setq-local eldoc-documentation-functions
                          (cons #'eglot-signature-eldoc-function
                                eldoc-documentation-functions))
              (flymake-mode 1))))

;; ── lsp-mode alternative (feature-rich backend) ─────────────────────────
(elpaca lsp-mode
  (when (eq astraea-lsp-backend 'lsp-mode)
    (setq lsp-keymap-prefix "C-c l"
          lsp-enable-symbol-highlighting t
          lsp-enable-which-key-integration t
          lsp-idle-delay 0.2
          lsp-headerline-breadcrumb-enable t
          read-process-output-max (* 1024 1024))))

;; ── Formatting: apheleia (conform.nvim equivalent) ──────────────────────
(elpaca apheleia
  (apheleia-global-mode 1)
  (setq apheleia-remote-always-use-remote nil))

;; ── Debugging: dape (nvim-dap equivalent) ───────────────────────────────
(elpaca dape)

;; ── Diagnostics (flymake is built into Emacs 30+) ───────────────────────
(setq flymake-no-changes-timeout 0.5
      flymake-start-on-flymake-mode t)
(elpaca flymake-collection)
(elpaca flymake-popon)                ; inline diagnostic popups (noice feel)

;; ── Eldoc floats (lsp_signature.nvim equivalent) ────────────────────────
(elpaca eldoc-box
  (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-mode t))

;; ── Treesitter major modes (treesitter.nvim equivalent) ─────────────────
;; Emacs 30+ ships treesit.  Register the language→mode mapping for the
;; languages you use; grammars auto-install on first use.
(defvar astraea-treesit-remap
  '((python . python-ts-mode)
    (rust . rust-ts-mode)
    (zig . zig-ts-mode)
    (javascript . js-ts-mode)
    (typescript . typescript-ts-mode)
    (json . json-ts-mode)
    (yaml . yaml-ts-mode)
    (toml . toml-ts-mode)
    (markdown . markdown-ts-mode)
    (bash . bash-ts-mode)
    (html . html-ts-mode)
    (css . css-ts-mode))
  "treesit language → major mode remapping table.")

(with-eval-after-load 'treesit
  (setq treesit-font-lock-level 4)     ; maximum highlighting
  (setq major-mode-remap-alist
        (append major-mode-remap-alist astraea-treesit-remap)))

(defun astraea/treesit-install-all ()
  "Install every available treesit grammar."
  (interactive)
  (dolist (lang (mapcar #'car treesit-language-source-alist))
    (ignore-errors (treesit-install-language-grammar lang))))

;; ── Project-wide search & replace (grug-far.nvim equivalent) ────────────
(elpaca wgrep)                         ; edit grep/ripgrep results in place
(defun astraea/project-replace ()
  "Project-wide search, then edit the results buffer with wgrep."
  (interactive)
  (consult-ripgrep (project-current t))
  (with-current-buffer "*xref*"
    (when (fboundp 'wgrep-change-to-wgrep-mode)
      (wgrep-change-to-wgrep-mode))))

(provide 'astraea-ide)
;;; astraea-ide.el ends here
