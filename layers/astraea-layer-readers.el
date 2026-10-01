;;; astraea-layer-readers.el --- Astraea layer: +readers/rss-epub -*- lexical-binding: t; -*-
;;
;; elfeed (RSS reader) + nov (epub reader) — spacemacs +readers equivalents.

(astraea-layer! +readers/rss-epub
  :packages (elfeed nov)
  :init
  (progn
    (elpaca elfeed
      (setq elfeed-feeds '())            ; add your feeds: (list "https://…")
      (setq elfeed-db-directory (expand-file-name "org/elfeed/" astraea-user-directory)))
    (elpaca nov
      (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))))
  :keybinds
  (astraea/leader-def
   "n f" #'elfeed
   "n F" #'elfeed-update))

(provide 'astraea-layer-readers)
;;; astraea-layer-readers.el ends here
