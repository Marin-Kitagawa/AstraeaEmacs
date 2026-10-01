;;; astraea-integrations.el --- External service integrations -*- lexical-binding: t; -*-
;;
;; Opt-in bridges to external services, mirroring the user's Neovim plugins:
;;   wakatime.lua  → wakatime-mode
;;   presence.nvim → elcord (Discord rich presence)
;;   copilot.lua   → copilot

;; ── WakaTime (astraea-wakatime-enabled) ─────────────────────────────────
(when astraea-wakatime-enabled
  (elpaca wakatime-mode
    (setq wakatime-cli-path (executable-find "wakatime-cli"))
    (global-wakatime-mode 1)))

;; ── Discord Rich Presence (astraea-discord-presence-enabled) ───────────
(when astraea-discord-presence-enabled
  (elpaca elcord
    (setq elcord-use-major-mode-as-main-icon t)
    (elcord-mode 1)))

;; ── GitHub Copilot (astraea-copilot-enabled) ────────────────────────────
;; Requires the `copilot-language-server' (Node.js) on PATH:
;;   npm install -g @github/copilot-language-server
(when astraea-copilot-enabled
  (elpaca copilot
    (setq copilot-max-chars 150000)
    (add-hook 'prog-mode-hook #'copilot-mode)
    (define-key copilot-completion-map (kbd "M-n") #'copilot-next-completion)
    (define-key copilot-completion-map (kbd "M-p") #'copilot-previous-completion)
    (define-key copilot-completion-map (kbd "M-<return>") #'copilot-accept-completion)
    (define-key copilot-completion-map (kbd "M-]") #'copilot-accept-completion-by-word)))

;; ── EditorConfig — built into Emacs 30+, just enable it ────────────────
(when (fboundp 'editorconfig-mode)
  (editorconfig-mode 1))

(provide 'astraea-integrations)
;;; astraea-integrations.el ends here
