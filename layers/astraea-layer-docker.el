;;; astraea-layer-docker.el --- Astraea layer: +tools/docker -*- lexical-binding: t; -*-

(astraea-layer! +tools/docker
  :packages (docker dockerfile-mode)
  :init
  (progn
    (elpaca dockerfile-mode)
    (elpaca docker))
  :keybinds
  (astraea/leader-def
   "d D" #'docker
   "d d" #'dockerfile-build))

(provide 'astraea-layer-docker)
;;; astraea-layer-docker.el ends here
