;;; -*- lexical-binding: t; -*-
;;; fix-encoding.el --- recover original UTF-8 from double-encoded README.adoc
(let* ((f "C:/Users/Ahri/projects/astraea-emacs/README.adoc")
       (text (with-temp-buffer
               (insert-file-contents f)
               (buffer-string)))
       (bytes (encode-coding-string text 'windows-1252)))
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert bytes)
    (write-region (point-min) (point-max) f))
  (message "bytes written: %d" (length bytes)))
