;;; astraea-lang-registry.el --- data-driven language layer coverage -*- lexical-binding: t; -*-
;;
;; Replaces spacemacs's 84 hand-written `+lang/*' layers with a single
;; data registry + generator.  Every entry describes: packages, treesit
;; grammar, major-mode remap, LSP server (eglot), formatter (apheleia).
;;
;; Use:
;;   M-x astraea/lang-enable       — enable a language interactively
;;   M-x astraea/lang-enable-many  — enable several at once
;;   `astraea-lang-default-enabled' lists languages enabled at boot.
;;
;; Tree-sitter grammars compile through `zig cc' (bin/zig-cc.exe shim),
;; so no MSVC/MinGW SDK is required on Windows.

(defcustom astraea-treesit-cc-program (expand-file-name "bin/zig-cc.exe" user-emacs-directory)
  "Compiler shim used for tree-sitter grammar builds (zig cc wrapper)."
  :type 'file)

(defcustom astraea-lang-default-enabled 'all
  "Languages enabled automatically at startup.
Symbol `all' enables every language in the registry; a list of
symbols enables just those; nil disables auto-enable."
  "Languages enabled automatically at startup."
  :type '(repeat symbol))

(defconst astraea-lang-registry
  '(
    ;; ── with treesit grammar + LSP ────────────────────────────────────
    (python     :grammar python      :pkgs (pyvenv jupyter)                 :lsp ("pyright-langserver" "--stdio")     :fmtr black)
    (rust       :grammar rust        :pkgs ()                               :lsp ("rust-analyzer")                    :fmtr rustfmt)
    (go         :grammar go          :pkgs (go-mode)                        :lsp ("gopls")                            :fmtr gofmt)
    (javascript :grammar javascript  :pkgs ()                               :lsp ("typescript-language-server" "--stdio") :fmtr prettier-javascript)
    (typescript :grammar typescript  :pkgs ()                               :lsp ("typescript-language-server" "--stdio") :fmtr prettier-typescript)
    (c-c++      :grammar c           :pkgs ()                               :lsp ("clangd")                           :fmtr clang-format)
    (java       :grammar java        :pkgs ()                               :lsp ("jdtls"))
    (lua        :grammar lua         :pkgs (lua-mode)                       :lsp ("lua-language-server"))
    (zig        :grammar zig         :pkgs (zig-mode)                       :lsp ("zls"))
    (bash       :grammar bash        :pkgs ()                               :lsp ("bash-language-server")             :fmtr shfmt)
    (html       :grammar html        :pkgs (web-mode)                       :lsp ("vscode-html-language-server" "--stdio") :fmtr prettier)
    (css        :grammar css         :pkgs ()                               :lsp ("vscode-css-language-server" "--stdio") :fmtr prettier-css)
    (json       :grammar json        :pkgs ()                               :lsp ("vscode-json-language-server" "--stdio"))
    (yaml       :grammar yaml        :pkgs ()                               :lsp ("yaml-language-server" "--stdio"))
    (toml       :grammar toml        :pkgs ())
    (markdown   :grammar markdown    :pkgs ()                               :lsp ("marksman")                         :fmtr prettier-markdown)
    (ruby       :grammar ruby        :pkgs (enh-ruby-mode)                  :lsp ("solargraph" "stdio")               :fmtr rubocop)
    (kotlin     :grammar kotlin      :pkgs (kotlin-mode)                    :lsp ("kotlin-language-server"))
    (elixir     :grammar elixir      :pkgs (elixir-mode)                    :lsp ("language_server.bat"))
    (php        :grammar php         :pkgs (php-mode)                       :lsp ("intelephense" "--stdio"))
    (dart       :grammar dart        :pkgs (dart-mode)                      :lsp ("dart" "language-server"))
    (clojure    :grammar clojure     :pkgs (clojure-mode cider)             :lsp ("clojure-lsp"))
    (graphql    :grammar graphql     :pkgs (graphql-mode))
    (perl5      :grammar perl        :pkgs (cperl-mode)                     :lsp ("perl" "-MPerl::LanguageServer" "-e" "Perl::LanguageServer::run"))
    ;; ── with LSP, no treesit grammar ─────────────────────────────────
    (haskell    :pkgs (haskell-mode)              :lsp ("haskell-language-server-wrapper" "--lsp") :fmtr ormolu)
    (ocaml      :pkgs (tuareg merlin)             :lsp ("ocamllsp"))
    (scala      :pkgs (scala-mode)                :lsp ("metals-emacs") )
    (erlang     :pkgs (erlang)                    :lsp ("erlang_ls"))
    (fsharp     :pkgs (fsharp-mode)               :lsp ("fsautocomplete" "--adaptive-lsp-server-enabled"))
    (csharp     :pkgs (csharp-mode)               :lsp ("OmniSharp" "-lsp"))
    (swift      :pkgs (swift-mode)                :lsp ("sourcekit-lsp"))
    (d          :pkgs (d-mode)                    :lsp ("serve-d"))
    (elm        :pkgs (elm-mode)                  :lsp ("elm-language-server"))
    (nim        :pkgs (nim-mode)                  :lsp ("nimlangserver"))
    (crystal    :pkgs (crystal-mode)              :lsp ("crystalline"))
    (groovy     :pkgs (groovy-mode))
    (solidity   :pkgs (solidity-mode))
    (purescript :pkgs (psc-ide-mode))
    (racket     :pkgs (racket-mode))
    (scheme     :pkgs (geiser))
    (common-lisp :pkgs (slime))
    (coq        :pkgs (proof-general))
    (agda       :pkgs (agda2-mode))
    (idris      :pkgs (idris-mode))
    (julia      :pkgs (julia-mode)                :lsp ("julia" "--startup-file=no" "-e" "using LanguageServer; runserver()"))
    (ess        :pkgs (ess))
    (octave     :pkgs ())
    (mermaid    :pkgs (mermaid-mode))
    (graphviz   :pkgs (graphviz-dot-mode))
    (plantuml   :pkgs (plantuml-mode))
    (protobuf   :pkgs (protobuf-mode))
    (sql        :pkgs ()                          :lsp ("sqls"))
    (autohotkey :pkgs (ahk-mode))
    (vimscript  :pkgs (vimrc-mode))
    (windows-scripts :pkgs (powershell-mode)      :lsp ("PowerShellEditorServices" "-Stdio"))
    (asciidoc   :pkgs (adoc-mode))
    (bibtex     :pkgs ())
    (csv        :pkgs (csv-mode))
    (dhall      :pkgs (dhall-mode))
    (jsonnet    :pkgs (jsonnet-mode))
    (kivy       :pkgs (kivy-mode))
    (alda       :pkgs (alda-mode))
    (asm        :pkgs (nasm-mode))
    (faust      :pkgs (faust-mode))
    (forth      :pkgs (forth-mode))
    (fountain   :pkgs (fountain-mode))
    (factor     :pkgs (factor-mode))
    (extempore  :pkgs (extempore-mode))
    (jr         :pkgs (jr-mode))
    (hy         :pkgs (hy-mode))
    (mercury    :pkgs (mercury-mode))
    (pact       :pkgs (pact-mode))
    (prolog     :pkgs (ediprolog))
    (raku       :pkgs (raku-mode))
    (reasonml   :pkgs (reason-mode))
    (restructuredtext :pkgs (sphinx-mode))
    (semantic-web :pkgs (ttl-mode))
    (sml        :pkgs (sml-mode))
    (yang       :pkgs (yang-mode))
    (gleam      :pkgs (gleam-mode))
    (major-modes :pkgs ()))
  "Registry mapping languages to packages, treesit grammar, LSP server
and formatter.  Derived from spacemacs +lang/* layers (all 84).")

(defvar astraea--lang-enabled nil)

(defun astraea/lang-enable (id)
  "Enable language ID: install packages, wire treesit remap + LSP.
Interactive with completion over `astraea-lang-registry'."
  (interactive
   (list (intern (completing-read
                  "Language: "
                  (mapcar (lambda (e) (symbol-name (car e))) astraea-lang-registry)))))
  (let* ((spec (cdr (assq id astraea-lang-registry)))
         (pkgs (plist-get spec :pkgs))
         (grammar (plist-get spec :grammar))
         (lsp (plist-get spec :lsp)))
    (unless spec (user-error "Unknown language: %s" id))
    (dolist (pkg pkgs)
      ;; runtime queuing: the `elpaca' macro must be expanded via eval
      (eval `(elpaca ,pkg) t))
    (when grammar
      (with-eval-after-load 'treesit
        (add-to-list 'treesit-language-source-alist
                     (cons grammar (list :source
                                         (cdr (assq grammar astraea-treesit-grammar-urls))
                                         :cc astraea-treesit-cc-program
                                         :c++ astraea-treesit-cc-program)))))
    (when lsp
      (with-eval-after-load 'eglot
        (dolist (mode (plist-get spec :modes))
          (add-to-list 'eglot-server-programs (cons mode lsp)))))
    (cl-pushnew id astraea--lang-enabled)
    (message "Astraea: language %s enabled%s" id
             (if grammar " (treesit grammar available — M-x astraea/treesit-install-all)" ""))))

(defun astraea/lang-enable-many (ids)
  "Enable several languages."
  (interactive (list (completing-read-multiple
                      "Languages (comma separated): "
                      (mapcar (lambda (e) (symbol-name (car e))) astraea-lang-registry))))
  (dolist (id ids) (astraea/lang-enable (intern id))))

(defun astraea/lang-enable-all-registered ()
  "Enable every language in the registry."
  (interactive)
  (dolist (e astraea-lang-registry) (astraea/lang-enable (car e))))

;; ── treesit grammar sources (compile via zig cc shim) ───────────────
(defconst astraea-treesit-grammar-urls
  '((python . "https://github.com/tree-sitter/tree-sitter-python")
    (rust . "https://github.com/tree-sitter/tree-sitter-rust")
    (go . "https://github.com/tree-sitter/tree-sitter-go")
    (javascript . "https://github.com/tree-sitter/tree-sitter-javascript")
    (typescript . "https://github.com/tree-sitter/tree-sitter-typescript")
    (c . "https://github.com/tree-sitter/tree-sitter-c")
    (cpp . "https://github.com/tree-sitter/tree-sitter-cpp")
    (java . "https://github.com/tree-sitter/tree-sitter-java")
    (lua . "https://github.com/MunifTanjim/tree-sitter-lua")
    (zig . "https://github.com/maxxnino/tree-sitter-zig")
    (bash . "https://github.com/tree-sitter/tree-sitter-bash")
    (html . "https://github.com/tree-sitter/tree-sitter-html")
    (css . "https://github.com/tree-sitter/tree-sitter-css")
    (json . "https://github.com/tree-sitter/tree-sitter-json")
    (yaml . "https://github.com/ikatyang/tree-sitter-yaml")
    (toml . "https://github.com/ikatyang/tree-sitter-toml")
    (markdown . "https://github.com/ikatyang/tree-sitter-markdown")
    (ruby . "https://github.com/tree-sitter/tree-sitter-ruby")
    (kotlin . "https://github.com/fwcd/tree-sitter-kotlin")
    (elixir . "https://github.com/elixir-lang/tree-sitter-elixir")
    (php . "https://github.com/tree-sitter/tree-sitter-php")
    (dart . "https://github.com/UserNobody14/tree-sitter-dart")
    (clojure . "https://github.com/sogaiu/tree-sitter-clojure")
    (graphql . "https://github.com/bkegley/tree-sitter-graphql")
    (perl . "https://github.com/ganezdragon/tree-sitter-perl"))
  "Grammar repos for `treesit-language-source-alist'.")

(defun astraea/treesit-install-all ()
  "Install every registered treesit grammar using the zig cc shim."
  (interactive)
  (dolist (lang (mapcar #'car astraea-treesit-grammar-urls))
    (when-let* ((entry (assq lang treesit-language-source-alist)))
      (ignore-errors (treesit-install-language-grammar lang))))
  (message "Astraea: treesit grammars installed."))

;; ── wire grammar sources with the zig cc shim ───────────────────────
(with-eval-after-load 'treesit
  (dolist (pair astraea-treesit-grammar-urls)
    (let ((lang (car pair)) (url (cdr pair)))
      (cl-pushnew (list lang :source url
                        :cc astraea-treesit-cc-program
                        :c++ astraea-treesit-cc-program)
                  treesit-language-source-alist :test #'equal))))

;; ── enable default languages at boot ────────────────────────────────
(dolist (id (if (eq astraea-lang-default-enabled 'all)
                (mapcar #'car astraea-lang-registry)
              astraea-lang-default-enabled))
  (when (assq id astraea-lang-registry)
    (condition-case err
        (astraea/lang-enable id)
      (error (message "Astraea: language %s failed to enable: %s"
                      id (error-message-string err))))))

(provide 'astraea-lang-registry)
;;; astraea-lang-registry.el ends here
