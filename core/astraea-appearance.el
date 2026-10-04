;;; astraea-appearance.el --- Live theme & frame appearance tools -*- lexical-binding: t; -*-
;;
;; Interactive appearance commands: switch themes with live completion,
;; pick a Catppuccin flavor, cycle frame transparency.  All of them respect
;; Astraea's tab-bar restyling (`astraea/ui//apply-tab-bar-faces').

(declare-function astraea/ui//apply-tab-bar-faces "astraea-ui" t)

;; ── Theme switching ──────────────────────────────────────────────────────
(defun astraea/set-theme (theme)
  "Switch to THEME (completion over every installed theme) and remember it.
Disables all currently enabled themes first, so switches are clean."
  (interactive
   (list (intern (completing-read "Theme: "
                                  (mapcar #'symbol-name
                                          (custom-available-themes))
                                  nil t nil nil
                                  (symbol-name astraea-theme)))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t)
  (setq astraea-theme theme)
  (when (fboundp 'astraea/ui//apply-tab-bar-faces)
    (astraea/ui//apply-tab-bar-faces))
  (message "Astraea: theme set to %s (add (setq astraea-theme '%s) to your
init to keep it across sessions)" theme theme))

(defun astraea/catppuccin-flavor (flavor)
  "Switch the Catppuccin theme to FLAVOR (latte/frappe/macchiato/mocha)."
  (interactive
   (list (intern (completing-read "Catppuccin flavor: "
                                  '("latte" "frappe" "macchiato" "mocha")
                                  nil t nil nil "mocha"))))
  (unless (fboundp 'catppuccin-reload)
    (user-error "Catppuccin theme is not installed/loaded"))
  (setq catppuccin-flavor flavor
        astraea-theme 'catppuccin)
  (catppuccin-reload)
  (when (fboundp 'astraea/ui//apply-tab-bar-faces)
    (astraea/ui//apply-tab-bar-faces))
  (message "Astraea: catppuccin %s" flavor))

;; ── Frame transparency (cute pastel glass effect) ────────────────────────
(defun astraea/cycle-frame-alpha ()
  "Cycle frame transparency: opaque → 95 → 90 → 85 → opaque."
  (interactive)
  (let* ((current (frame-parameter nil 'alpha))
         (alpha (cond ((numberp current) current)
                      ((consp current) (car current))
                      (t 100)))
         (next (pcase alpha
                 (100 95)
                 (95 90)
                 (90 85)
                 (_ 100))))
    (set-frame-parameter nil 'alpha next)
    (modify-frame-parameters nil `((alpha . ,next)))
    (message "Frame alpha: %d" next)))

(provide 'astraea-appearance)
;;; astraea-appearance.el ends here
