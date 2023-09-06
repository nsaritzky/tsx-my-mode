;;; tsx-my-mode.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Nathan Saritzky
;;
;; Author: Nathan Saritzky <nsaritzky@gmail.com>
;; Maintainer: Nathan Saritzky <nsaritzky@gmail.com>
;; Created: September 04, 2023
;; Modified: September 04, 2023
;; Version: 0.0.1
;; Keywords: Symbol’s value as variable is void: finder-known-keywords
;; Homepage: https://github.com/nathan/tsx-mode
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(defvar-keymap tsx-my-mode-map
  :parent tsx-ts-mode-map

  "C-c C-a p" #'tsx-my-attribute-previuos
  "C-c C-a n" #'tsx-my-attribute-next
  "C-c C-a b" #'tsx-my-attribute-beginning
  "C-c C-a e" #'tsx-my-attribute-end
  "C-c C-a k" #'tsx-my-attribute-kill
  "C-c C-a q" #'tsx-my-attribute-raw-string-to-template-string)

(setq tsx-my--query-alist '((attribute .
                             "(jsx_attribute (property_identifier) @tag.attribute)")
                            (template-string .
                             "(template_string) @template")))

(defun tsx-my-point-in-range-p (list) "Return whether point is in the specified range"
       (let ((start (car list))
             (end (cdr list)))
         (and (< (point) end) (>= (point) start))))

(defun tsx-my--attribute-p () "Return whether point is inside an attribute"
       (let* ((query (cdr (assoc 'attribute tsx-my--query-alist)))
              (ranges (treesit-query-range 'tsx query)))
         (-any? #'tsx-my-point-in-range-p ranges)))

(defun tsx-my--point-in-node-type (node-type) "Return whether point is inside a node of node-type"
       (treesit-parent-until
        (treesit-node-at (point))
        (lambda (node) (string= node-type (treesit-node-type node)))))

(defun tsx-my-attribute-previuos ()
  (interactive)
  (let* ((query (cdr (assoc 'attribute tsx-my--query-alist)))
         (starts (-map #'car (treesit-query-range 'tsx query))))
    (goto-char (--last (> (point) it) starts))))

(defun tsx-my-attribute-next ()
  (interactive)
  (let* ((query (cdr (assoc 'attribute tsx-my--query-alist)))
         (starts (-map #'car (treesit-query-range 'tsx query))))
    (goto-char (--first (< (point) it) starts))))

(defun tsx-my-attribute-beginning ()
  (interactive)
  (when-let ((node (tsx-my--point-in-node-type "jsx_attribute")))
    (goto-char (treesit-node-start node))))

(defun tsx-my-attribute-end ()
  (interactive)
  (when-let ((node (tsx-my--point-in-node-type "jsx_attribute")))
    (goto-char (treesit-node-end node))))

(defun tsx-my-attribute-kill ()
  (interactive)
  (when-let ((node (tsx-my--point-in-node-type "jsx_attribute")))
    (kill-region (treesit-node-start node) (treesit-node-end node))))

(defun tsx-my-attribute-raw-string-to-template-string ()
  (interactive)
  (when-let* ((node (tsx-my--point-in-node-type "jsx_attribute"))
              (string-node (first (treesit-query-capture
                             'tsx
                             "(string) @str"
                             (treesit-node-start node)
                             (treesit-node-end node)
                             t)))
              (start (treesit-node-start string-node))
              (end (treesit-node-end string-node)))
    (save-excursion
      (goto-char start)
      (delete-char 1)
      (insert "{`")
      (goto-char (+ 1 end))
      (delete-backward-char 1)
      (insert "`}"))
    ))

(defun tsx-my-convert-to-template-string ()
  (interactive)
  (when-let ((node (tsx-my--point-in-node-type "string")))
    (let ((start (treesit-node-start node))
          (end (treesit-node-end node)))
      (save-excursion
        (goto-char start)
        (delete-char 1)
        (insert "`")
        (goto-char end)
        (delete-backward-char 1)
        (insert "`")))))

(debug-on-entry #'tsx-my-convert-to-template-string)

(define-derived-mode tsx-my-mode
  tsx-ts-mode "TSX"
  "My TSX Mode")

(provide 'tsx-my-mode)
;;; tsx-my-mode.el ends here
