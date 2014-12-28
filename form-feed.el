;;; form-feed.el --- Display ^L glyphs as horizontal lines -*- lexical-binding: t -*-

;; Copyright (C) 2014 Vasilij Schneidermann <v.schneidermann@gmail.com>

;; Author: Vasilij Schneidermann <v.schneidermann@gmail.com>
;; URL: https://github.com/wasamasa/form-feed
;; Keywords: faces
;; Version: 0.1.1

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This minor mode displays page delimiters which usually appear as ^L
;; glyphs on a single line as horizontal lines spanning the entire
;; window.  It is suitable for inclusion into mode hooks and is
;; intended to be used that way.  The following snippet would enable
;; it for Emacs Lisp files for instance:
;;
;;     (add-hook 'emacs-lisp-mode-hook 'form-feed-mode)

;; See the README for more info:
;; https://github.com/wasamasa/form-feed

;;; Code:


;; Customizations

(defgroup form-feed nil
  "Turn ^L glyphs into horizontal lines."
  ;; NOTE doesn't work if ^L is at the beginning of the buffer
  :prefix "form-feed-"
  :group 'faces)

(defface form-feed-line
  '((((type graphic)) :inherit font-lock-comment-face :strike-through t)
    (((type tty)) :inherit font-lock-comment-face :underline t))
  "Face for form-feed-mode lines."
  :group 'form-feed)

(defcustom form-feed-kick-cursor t
  "When t, entering a line moves the cursor away from it."
  :type 'boolean
  :group 'form-feed)

(defvar form-feed--font-lock-face
  ;; NOTE see (info "(elisp) Search-based fontification") and the
  ;; `(MATCHER . FACESPEC)' section for an explanation of the syntax
  `(face form-feed-line display (space . (:width text))
         ,@(when form-feed-kick-cursor '(point-entered form-feed--kick-cursor))))

(defvar form-feed--font-lock-keywords
  `((,page-delimiter 0 form-feed--font-lock-face t)))


;; Definitions

(defun form-feed--kick-cursor (old new)
  ;; Don't do anything inside lisp code, because lisp code uses point
  ;; motion too, but needs to see the exact buffer contents.
  (when (called-interactively-p 'any)
    (cond ((and (< old new) (/= (point-max) (point)))
           (forward-char 1))
          ((and (> old new) (/= (point-min) (point)))
           (forward-char -1)))))

(defun form-feed--add-font-lock-keywords ()
  "Add buffer-local keywords to display page delimiter lines.
Make sure the special properties involved get cleaned up on
removal of the keywords via
`form-feed--remove-font-lock-keywords'."
  (font-lock-add-keywords nil form-feed--font-lock-keywords)
  (set (make-local-variable 'font-lock-extra-managed-props)
       `(display ,(when form-feed-kick-cursor 'point-entered)))
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (with-no-warnings (font-lock-fontify-buffer))))

(defun form-feed--remove-font-lock-keywords ()
  "Remove buffer-local keywords displaying page delimiter lines."
  (font-lock-remove-keywords nil form-feed--font-lock-keywords)
  ;; font-lock-fontify-buffer is unsuitable in lisp code when
  ;; font-lock-flush is available (on later versions)
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (with-no-warnings (font-lock-fontify-buffer))))


;; Minor mode definition

;;;###autoload
(define-minor-mode form-feed-mode
  "Display hard newlines as window-wide horizontal lines.

This minor mode displays page delimiters which usually appear as ^L
glyphs on a single line as horizontal lines spanning the entire
window.  It is suitable for inclusion into mode hooks and is
intended to be used that way.  The following snippet would enable
it for Emacs Lisp files for instance:

    (add-hook 'emacs-lisp-mode-hook 'form-feed-mode)"
  :lighter " ^L"
  (if form-feed-mode
      (form-feed--add-font-lock-keywords)
    (form-feed--remove-font-lock-keywords)))

(provide 'form-feed)

;;; form-feed.el ends here
