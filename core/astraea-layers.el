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

(defmacro astraea-layer! (name &rest body)
  "Declare a layer NAME with keywords in BODY.

Keywords:
  :packages LIST    extra elpaca/use-package package specs
  :init FORM        run before packages load
  :config FORM      run after packages load (inside with-eval-after-load
                    for each package when :defer t)
  :defer BOOL       defer :config via `with-eval-after-load' (default t)
  :keybinds FORM    evaluated after leader map is installed

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
             :init (lambda () ,@(alist-get :init p))
             :config (lambda () ,@(alist-get :config p))
             :keybinds (lambda () ,@(alist-get :keybinds p))))
       ',name)))

(defun astraea/layers--declare-file-layer (name file)
  "Remember that layer NAME is defined in FILE."
  (put name 'astraea-layer-file file))

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
        (funcall init)))))

(defun astraea/layers--run-config ()
  "Evaluate :config and :keybinds forms of enabled layers.
Called once packages have been installed/loaded."
  (dolist (layer (reverse astraea--enabled-layers))
    (when-let* ((spec (get layer 'astraea-layer)))
      (when-let* ((config (plist-get spec :config)))
        (funcall config))
      (when-let* ((kbs (plist-get spec :keybinds)))
        (funcall kbs)))))

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
