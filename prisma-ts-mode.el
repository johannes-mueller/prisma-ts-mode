;;; prisma-ts-mode.el --- Major mode for prisma using tree-sitter -*- lexical-binding: t; -*-
;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/prisma-ts-mode
;; Version: 1.0.0
;; Package-Requires: ((emacs "29.1"))
;; Created: 6 October 2023
;; Keywords: prisma languages tree-sitter

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This package defines a major mode for prisma schema language buffers using
;; tree-sitter. It provides support for indentation, font-locking, imenu, and
;; structural navigation.
;;
;; The tree-sitter grammar compatible with this package can be found at
;; https://github.com/victorhqc/tree-sitter-prisma.
;;
;;; Installation:
;;
;; Install the tree-sitter grammar library from
;; https://github.com/victorhqc/tree-sitter-prisma, eg.
;;
;;     (add-to-list
;;      'treesit-language-source-alist
;;      '(prisma "https://github.com/victorhqc/tree-sitter-prisma")
;;
;; and call `treesit-install-language-grammar' to do the installation.
;;
;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'treesit)

(defcustom prisma-ts-mode-indent-level 2
  "Number of spaces for each indentation step."
  :group 'prisma
  :type 'integer
  :safe 'integerp)

;;; Syntax

(defvar prisma-ts-mode--syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?\^m "> b" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?+  "." st)
    (modify-syntax-entry ?-  "." st)
    (modify-syntax-entry ?=  "." st)
    (modify-syntax-entry ?%  "." st)
    (modify-syntax-entry ?<  "." st)
    (modify-syntax-entry ?>  "." st)
    (modify-syntax-entry ?&  "." st)
    (modify-syntax-entry ?|  "." st)
    (modify-syntax-entry ?\' "\"" st)
    (modify-syntax-entry ?_  "_" st)
    (modify-syntax-entry ?$ "'" st)
    (modify-syntax-entry ?@ "'" st)
    (modify-syntax-entry ?? "'" st)
    st)
  "Syntax table in use in Prisma Mode buffers.")

;;; Indentation

(defvar prisma-ts-mode--indent-rules
  '((prisma
     ((parent-is "program") parent 0)
     ((node-is "}") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is ")") parent-bol 0)
     ((parent-is "block") parent-bol prisma-ts-mode-indent-level)
     ((parent-is "column_declaration") prev-sibling 0)
     (no-node parent-bol prisma-ts-mode-indent-level)
     (catch-all parent-bol prisma-ts-mode-indent-level)))
  "Tree-sitter indentation rules for prisma.")

;;; Font-Lock

(defvar prisma-ts-mode--feature-list
  '(( comment definition)
    ( keyword string type)
    ( attribute property constant function variable)
    ( number bracket delimiter operator error))
  "`treesit-font-lock-feature-list' for `prisma-ts-mode'.")

(defvar prisma-ts-mode--keywords
  '("datasource" "enum" "generator" "model" "type" "view")
  "Prisma keywords for tree-sitter font-locking.")

(defvar prisma-ts-mode--operators
  '("="
    "+" "-" "*" "/" "%" "**" "^" "&" "|"
    ">>" ">>>" "<<"
    "&&" "||" "<" "<=" "==" "===" "!=" "!==" ">=" ">")
  "Prisma operators for tree-sitter font-lock.")

(defvar prisma-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'prisma
   :feature 'comment
   '((comment) @font-lock-doc-face
     (developer_comment) @font-lock-comment-face)

   :language 'prisma
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'prisma
   :feature 'keyword
   `([,@prisma-ts-mode--keywords] @font-lock-keyword-face)

   :language 'prisma
   :feature 'definition
   '((datasource_declaration (identifier) @font-lock-function-name-face)
     (enum_declaration (identifier) @font-lock-function-name-face)
     (generator_declaration (identifier) @font-lock-function-name-face)
     (model_declaration (identifier) @font-lock-function-name-face)
     (type_declaration (identifier) @font-lock-function-name-face)
     (view_declaration (identifier) @font-lock-function-name-face))

   :language 'prisma
   :feature 'constant
   '([(true) (false) (null) (enumeral)] @font-lock-constant-face)

   :language 'prisma
   :feature 'number
   '((number) @font-lock-number-face)

   :language 'prisma
   :feature 'type
   '((column_type (identifier) @font-lock-type-face)
     (type_declaration_type) @font-lock-type-face)

   :language 'prisma
   :feature 'attribute
   '((attribute
      "@" @font-lock-builtin-face
      [(identifier) @font-lock-builtin-face
       (member_expression) @font-lock-builtin-face
       (call_expression [(member_expression) (identifier)] @font-lock-builtin-face)])

     (block_attribute_declaration
      "@@" @font-lock-builtin-face
      [(identifier) @font-lock-builtin-face
       (member_expression) @font-lock-builtin-face
       (call_expression [(member_expression) (identifier)] @font-lock-builtin-face)]))

   :language 'prisma
   :feature 'function
   '((call_expression
      (_) @font-lock-function-call-face
      (arguments "(" (identifier) @font-lock-variable-name-face :* ")")))

   :language 'prisma
   :feature 'property
   '((column_declaration (identifier) @font-lock-property-name-face)
     (property_identifier) @font-lock-property-name-face)

   :language 'prisma
   :feature 'variable
   '((assignment_expression
      (variable) @font-lock-variable-name-face)
     (identifier) @font-lock-variable-use-face)

   :language 'prisma
   :feature 'bracket
   '(["(" ")" "{" "}" "[" "]"] @font-lock-bracket-face)

   :language 'prisma
   :feature 'operator
   `([,@prisma-ts-mode--operators] @font-lock-operator-face
     (maybe) @font-lock-negation-char-face)

   :language 'prisma
   :feature 'delimiter
   '(["," ";" ":"] @font-lock-delimiter-face)

   :language 'prisma
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for prisma.")

;;; Navigation

(defun prisma-ts-mode--defun-name (node)
  "Find name of NODE."
  (treesit-node-text
   (or (treesit-node-child node 1)
       node)))

(defvar prisma-ts-mode--sentence-nodes
  (rx (or "assignment_expression"
          "column_declaration"
          "block_attribute_declaration"
          (or "datasource" "model" "view" "enum" "type") "_declaration"))
  "See `treesit-sentence-type-regexp' for more information.")

(defvar prisma-ts-mode--sexp-nodes nil
  "See `treesit-sexp-type-regexp' for more information.")

(defvar prisma-ts-mode--text-nodes (rx (or "comment" "developer_comment" "string"))
  "See `treesit-text-type-regexp' for more information.")

;;;###autoload
(define-derived-mode prisma-ts-mode prog-mode "Prisma"
  "Major mode for editing prisma source code."
  :group 'prisma
  :syntax-table prisma-ts-mode--syntax-table
  (when (treesit-ready-p 'prisma)
    (treesit-parser-create 'prisma)

    ;; Comments
    (setq-local comment-start "//")
    (setq-local comment-end "")
    (setq-local comment-start-skip "//+[ \t]*")
    (setq-local parse-sexp-ignore-comments t)

    ;; Indentation
    (setq-local treesit-simple-indent-rules prisma-ts-mode--indent-rules)

    ;; Electric-indent.
    (setq-local electric-indent-chars (append "{}()[]:," electric-indent-chars))
    (setq-local electric-layout-rules '((?\{ . after) (?\} . before)))

    ;; Font-Locking
    (setq-local treesit-font-lock-settings prisma-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list prisma-ts-mode--feature-list)

    ;; Navigation
    (setq-local treesit-defun-prefer-top-level t)
    (setq-local treesit-defun-name-function #'prisma-ts-mode--defun-name)
    (setq-local treesit-defun-type-regexp
                (rx (or "model" "enum" "datasource" "view" "type") "_declaration"))

    ;; navigation objects
    (setq-local treesit-thing-settings
                `((prisma
                   (sexp ,prisma-ts-mode--sexp-nodes)
                   (sentence ,prisma-ts-mode--sentence-nodes)
                   (text ,prisma-ts-mode--text-nodes))))

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                `(("Datasource" "\\`datasource_declaration\\'")
                  ("Model" "\\`model_declaration\\'")
                  ("View" "\\`view_declaration\\'")
                  ("Type" "\\`type_declaration\\'")
                  ("Enum" "\\`enum_declaration\\'")))

    (treesit-major-mode-setup)))

;;;###autoload
(if (treesit-ready-p 'prisma)
    (add-to-list 'auto-mode-alist '("\\.prisma\\'" . prisma-ts-mode)))


;;;###autoload
(defun prisma-format-model ()
  (interactive)
  (save-excursion
    (let ((number-of-columns (length (prisma--model-declaration-childen))))
      (dotimes (n number-of-columns)
       (prisma--indent-nth-child n)
       (prisma--space-nth-child n)))))

(defun prisma--model-declaration-childen ()
  (seq-filter (lambda (node)
                (equal (treesit-node-type node) "column_declaration"))
              (treesit-node-children (prisma--current-model-start-node))))

(defun prisma--current-model-start-node ()
  (treesit-search-subtree
   (prisma--current-model-declaration-node) "statement_block"))

(defun prisma--current-model-declaration-node ()
  (treesit-parent-until
     (treesit-node-at (point))
     (lambda (node) (equal (treesit-node-type node) "model_declaration"))))

(defun prisma--indent-nth-child (n)
  (prisma--node-initial-indent (nth n (prisma--model-declaration-childen))))

(defun prisma--node-initial-indent (node)
  (goto-char (treesit-node-start node))
  (let ((end (point)))
    (beginning-of-line)
    (delete-region (point) end)
    (insert (make-string prisma-ts-mode-indent-level ?\s))))

(defun prisma--space-nth-child (n)
  (prisma--do-spacing (nth n (prisma--model-declaration-childen)) 0)
  (prisma--do-spacing (nth n (prisma--model-declaration-childen)) 1))

(defun prisma--do-spacing (node first-node-num)
  (when (> (treesit-node-child-count node) (1+ first-node-num))
    (let* ((node-before (treesit-node-child node first-node-num))
           (node-after (treesit-node-child node (1+ first-node-num)))
           (word-length (length (treesit-node-text node-before)))
           (gap-length (- (treesit-node-start node-after) (treesit-node-end node-before)))
           (max-length (prisma--max-length-declaration-in-chunk-of node first-node-num))
           (gap-needed (1+ (- max-length word-length)))
           (gap-discrep (- gap-needed gap-length)))
      (goto-char (treesit-node-start node-after))
      (if (>= gap-discrep 0)
          (insert (make-string gap-discrep ?\s))
        (delete-char gap-discrep)))))

(defun prisma--max-length-declaration-in-chunk-of (node sub-node-num)
  (let* ((node (prisma--first-column-declaration-in-chunk-of node))
         (max-length (length (treesit-node-text (treesit-node-child node sub-node-num)))))
    (while-let ((candidate (treesit-node-next-sibling node))
                ((prisma--is-part-column-declaration-or-comment candidate))
                ((prisma--empty-line-between-nodes node candidate)))
      (setq node candidate)
      (setq max-length (max max-length (length (treesit-node-text (treesit-node-child node sub-node-num))))))
    max-length))

(defun prisma--first-column-declaration-in-chunk-of (node)
  (while-let ((candidate (treesit-node-prev-sibling node))
              ((prisma--is-part-column-declaration-or-comment candidate))
              ((prisma--empty-line-between-nodes candidate node)))
    (setq node candidate))
  node)

(defun prisma--is-part-column-declaration-or-comment (candidate)
  (let ((type (treesit-node-type candidate)))
    (or (equal type "column_declaration")
        (equal type "developer_comment"))))

(defun prisma--empty-line-between-nodes (first second)
  (goto-char (treesit-node-end first))
  (not (search-forward-regexp "^[:space:]*$" (treesit-node-start second) t)))


(provide 'prisma-ts-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; prisma-ts-mode.el ends here
