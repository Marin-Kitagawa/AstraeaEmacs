;;; astraea-layers.el --- Spacemacs-style layer system -*- lexical-binding: t; -*-
;;
;; A layer is a named bundle of packages + init hooks + config hooks +
;; keybinds.  Layers are declared with `astraea-layer!' and enabled from the
;; user config:
;;
;;   (astraea-layer! +lang/python
;;     :packages (pyvenv python-black)
;;     :config (setq python-indent-offset 4))
;;
;; Layers may also live in files: layers/astraea-layer-NAME.el containing a
;; top-level `astraea-layer!' form; enabling the layer loads that file first.

(defvar astraea--layers (make-hash-table :test 'eq)
  "Registry of declared layers, keyed by layer symbol.")

(defvar astraea--enabled-layers nil
  "Layers enabled by the user, in enable order.")

(defvar astraea--layers-initialized nil
  "Non-nil once `astraea/layers--enable-all' has run.")

(defvar astraea--discovering-layer-file nil
  "Bound to the file being loaded by `astraea/layers--discover-file-layers'.
Lets `astraea-layer!' record which file declares a file layer, without
mistaking the user config (which also has `load-file-name' bound) for one.")

(defmacro astraea-layer! (name &rest body)
  "Declare a layer NAME with keywords in BODY.

Keywords:
  :packages LIST    extra elpaca/use-package package specs
  :init FORM        run before packages load
  :config FORM      run after packages load (inside with-eval-after-load
                    for each package when :defer t)
  :defer BOOL       defer :config via `with-eval-after-load' (default t)
  :keybinds FORM    evaluated after leader map is installed

Each of :init, :config and :keybinds takes a single FORM; wrap several
expressions in a `progn'.

Example:
  (astraea-layer! +lang/python
    :packages (pyvenv)
    :config (setq python-indent-offset 4))"
  (declare (indent defun))
  (let ((p (cl-loop for (k v) on body by #'cddr collect (cons k v))))
    `(progn
       (put ',name 'astraea-layer
            (list
             :packages ',(alist-get :packages p)
             :init (lambda () ,(alist-get :init p))
             :config (lambda () ,(alist-get :config p))
             :keybinds (lambda () ,(alist-get :keybinds p))))
       ;; When the layer is declared while a file layer is being discovered
       ;; (see `astraea/layers--discover-file-layers'), remember which file
       ;; defines it so `astraea/enable-layer' can load it on demand.  Inline
       ;; layers declared in the user config are not inside that binding and
       ;; need no loading.
       (when astraea--discovering-layer-file
         (astraea/layers--declare-file-layer ',name astraea--discovering-layer-file))
       ',name)))

(defun astraea/layers--declare-file-layer (name file)
  "Remember that layer NAME is defined in FILE."
  (put name 'astraea-layer-file file))

(defun astraea/layers--discover-file-layers ()
  "Load every `layers/astraea-layer-*.el' so its declared layer is known.
This is what lets `astraea/enable-layer' load a file layer on demand by
its symbol (as documented) without the user knowing the file name: the
`astraea-layer!' form registers the defining file while it is bound in
`astraea--discovering-layer-file'.  Loading a layer file only records its
spec — packages are installed and :init/:config/:keybinds run only when
the layer is actually enabled."
  (let ((dir (expand-file-name "layers/" user-emacs-directory)))
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "\\`astraea-layer-.*\\.el\\'"))
        (condition-case err
            (let ((astraea--discovering-layer-file file))
              (load file nil 'nomessage))
          (error (message "Astraea: failed to load layer file %s: %s"
                          file (error-message-string err))))))))

(defun astraea/enable-layer (name)
  "Enable layer NAME.  If NAME names a file layer, load it first."
  (cl-pushnew name astraea--enabled-layers)
  (when-let* ((file (get name 'astraea-layer-file)))
    (load file nil 'nomessage)))

(defun astraea/layers--enable-all ()
  "Evaluate :init forms of all enabled layers."
  (unless astraea--layers-initialized
    (setq astraea--layers-initialized t)
    (dolist (layer (reverse astraea--enabled-layers))
      (when-let* ((spec (get layer 'astraea-layer))
                  (init (plist-get spec :init)))
        (condition-case err
            (funcall init)
          (error (message "Astraea: layer %s failed to init: %s"
                          layer (error-message-string err))))))))

(defun astraea/layers--run-config ()
  "Evaluate :config and :keybinds forms of enabled layers.
Called once packages have been installed/loaded."
  (dolist (layer (reverse astraea--enabled-layers))
    (when-let* ((spec (get layer 'astraea-layer)))
      (condition-case err
          (when-let* ((config (plist-get spec :config))) (funcall config))
        (error (message "Astraea: layer %s config failed: %s"
                        layer (error-message-string err))))
      (condition-case err
          (when-let* ((kbs (plist-get spec :keybinds)))
            (funcall kbs))
        (error (message "Astraea: layer %s keybinds failed: %s"
                        layer (error-message-string err)))))))

(defun astraea/list-layers ()
  "List all enabled layers with their packages."
  (interactive)
  (with-current-buffer (get-buffer-create "*Astraea Layers*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (format "Astraea %s — enabled layers\n\n" astraea-version))
      (dolist (layer (reverse astraea--enabled-layers))
        (insert (format "  %s\n" layer))
        (when-let* ((spec (get layer 'astraea-layer))
                    (pkgs (plist-get spec :packages)))
          (dolist (pkg pkgs)
            (insert (format "      %s\n" pkg)))))
      (special-mode)
      (pop-to-buffer (current-buffer)))))

(provide 'astraea-layers)
;;; astraea-layers.el ends here
