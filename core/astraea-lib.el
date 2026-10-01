;;; astraea-lib.el --- Utility library for Astraea modules and layers -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'map)

(defmacro astraea/after! (feature &rest body)
  "Evaluate BODY after FEATURE is loaded (defer-safe).
Like `with-eval-after-load' but accepts a list of features and
evaluates BODY after the first one loads."
  (declare (indent 1))
  (if (consp feature)
      `(progn ,@(mapcar (lambda (f) `(with-eval-after-load ',f ,@body)) feature))
    `(with-eval-after-load ',feature ,@body)))

(defmacro astraea/add-hook! (hooks &rest func)
  "Add FUNC to HOOKS.  HOOKS may be a symbol or list of symbols.
FUNC items may be quoted function symbols or lambdas."
  (declare (indent 1))
  (let ((hook-list (if (consp hooks) hooks (list hooks))))
    `(progn
       ,@(mapcar (lambda (h)
                   `(add-hook ',h ,(if (symbolp func) `#',func `(lambda () ,@func)) t))
                 hook-list))))

(defmacro astraea/setq! (&rest pairs)
  "Set each variable in PAIRS after its package loads.
(`var value package…) — PACKAGE is the feature providing VAR."
  (let (forms)
    (while pairs
      (let ((var (pop pairs)) (val (pop pairs)) (pkg (pop pairs)))
        (push (if pkg
                  `(with-eval-after-load ',pkg (setq ,var ,val))
                `(setq ,var ,val))
              forms)))
    `(progn ,@(nreverse forms))))

(defun astraea/buffer-predicate (buf)
  "Return non-nil if BUF is a real editing buffer."
  (let ((name (buffer-name buf)))
    (and (not (string-prefix-p " " name))
         (not (string-prefix-p "*" name))
         (buffer-file-name buf))))

(defun astraea/close-buffer-or-window ()
  "Kill buffer if modified-elsewhere-safe, otherwise delete window."
  (interactive)
  (if (and (buffer-modified-p) (buffer-file-name))
      (kill-buffer)
    (if (= 1 (count-windows))
        (bury-buffer)
      (delete-window))))

(defun astraea/rename-file-and-buffer (new-name)
  "Rename current buffer and the file it is visiting."
  (interactive "sNew name: ")
  (if-let* ((file (buffer-file-name)))
      (let ((new-file (expand-file-name new-name (file-name-directory file))))
        (rename-file file new-file)
        (set-visited-file-name new-file)
        (set-buffer-modified-p nil))
    (user-error "Buffer is not visiting a file")))

(defun astraea/duplicate-buffer ()
  "Open a read-only clone of the current buffer in another window."
  (interactive)
  (let ((buf (current-buffer)))
    (switch-to-buffer-other-window (clone-buffer buf))))

(defun astraea/edit-indirect-region ()
  "Edit the active region in a dedicated buffer, then commit."
  (interactive)
  (if (use-region-p)
      (call-interactively #'edit-indirect-region)
    (user-error "No active region")))

(defun astraea/what-face (pos)
  "Show the face at POS in the echo area."
  (interactive "d")
  (let ((face (or (get-char-property pos 'read-face-name)
                  (get-char-property pos 'face))))
    (message "Face at %d: %s" pos face)))

(provide 'astraea-lib)
;;; astraea-lib.el ends here
