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
;;
;; Clicking the horizontal lines will hide/show following sections of
;; code. Comments just after the form-feed function as headers.

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

(defvar form-feed--keymap
  (let ((k (make-sparse-keymap)))
    (define-key k (kbd "<mouse-1>") #'form-feed-toggle-hiding)
    (define-key k (kbd "<tab>") #'form-feed-toggle-hiding)
    k))

(defvar form-feed--font-lock-face
  ;; NOTE see (info "(elisp) Search-based fontification") and the
  ;; `(MATCHER . FACESPEC)' section for an explanation of the syntax
  `(face form-feed-line display (space . (:width text))
         ,@(when form-feed-kick-cursor '(point-entered form-feed--kick-cursor))
         keymap ,form-feed--keymap
         pointer hand))

(defvar form-feed--font-lock-keywords
  `((,page-delimiter 0 form-feed--font-lock-face t)))


;; Hiding and showing form-feed-delimited sections of code.

(defun form-feed-show-all ()
  "Show all form-feed-delimited code sections."
  (interactive)
  (remove-overlays (point-min) (point-max) 'category 'form-feed--hs)
  (remove-overlays (point-min) (point-max) 'category 'form-feed--hs-interior))

(defun form-feed-hide-all ()
  "Hide all form-feed-delimited code sections."
  (interactive)
  (let ((old-point (point)) next)
    (form-feed-show-all)
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        (while (search-forward-regexp page-delimiter nil t)
          (setq next (save-excursion
                       (when (search-forward-regexp
                              (concat "\\'\\|" page-delimiter) nil t)
                         (point))))
          (unless (and next (<= (point) old-point) (<= old-point next))
            (form-feed-hide)))))))

(defun form-feed-toggle-hiding ()
  "Toggle hiding the form-feed section surrounding point."
  (interactive)
  (if (get-char-property (point) 'form-feed--hidden)
      (form-feed-show)
    (form-feed-hide)))

(defun form-feed-show (&rest _args)
  "Show a hidden form-feed section at point.

_ARGS are ignored."
  (interactive)
  ;; Find all top-level overlays; they contain pointers to invisible
  ;; interior overlays.
  (save-excursion
    (mapcar
     (lambda (o)
       (when (eq (overlay-get o 'category) 'form-feed--hs)
         (let ((o-int (overlay-get o 'form-feed--hs-interior)))
           (when o-int (delete-overlay o-int))
           (delete-overlay o))))
     (overlays-at (point)))))

(defun form-feed--overlay-modification (o _before _start _end _length)
  (let ((o-int (overlay-get o 'form-feed--hs-interior)))
    (delete-overlay o-int))
  (delete-overlay o))

;; Default properties of overlays.
(put 'form-feed--hs 'evaporate t)
(put 'form-feed--hs 'form-feed--hidden t)
;; Any modification should show the overlays.
(put 'form-feed--hs 'insert-in-front-hooks #'form-feed--overlay-modification)
(put 'form-feed--hs 'insert-behind-hooks #'form-feed--overlay-modification)
(put 'form-feed--hs 'modification-hooks #'form-feed--overlay-modification)

(put 'form-feed--hs-interior 'evaporate t)
;; The invisible property is a symbol that specifies who made it
;; invisible. See also Info node (elisp)Invisible Text.
(put 'form-feed--hs-interior 'invisible 'form-feed)
(put 'form-feed--hs-interior 'isearch-open-invisible #'form-feed-show)
(put 'form-feed--hs-interior 'isearch-open-invisible-temporary
     (lambda (o invisible) (overlay-put o 'invisible (and invisible 'form-feed))))

(defun form-feed-hide ()
  "Hide a form-feed section surrounding point."
  (interactive)
  ;; The comment directly below the form-feed will be shown,
  ;; everything else will become invisible
  (let* ((start
          (save-excursion
            (when (looking-at-p page-delimiter) (forward-line))
            (search-backward-regexp page-delimiter nil t)
            (point)))
         (start-int
          (save-excursion (goto-char start)
                          (while (and (= 0 (forward-line))
                                    (looking-at-p comment-start)))
                          (point)))
         (end
          (save-excursion
            (goto-char start-int)
            (search-forward-regexp (concat "\\'\\|" page-delimiter) nil t)
            (unless (eobp)
              (forward-char -1)
              (when (bolp) (forward-char -1)))
            (point)))
         o-top o-int)
    (when (and start start-int end)
      (remove-overlays start end 'category 'form-feed--hs)
      (remove-overlays start end 'category 'form-feed--hs-interior)
      (setq o-top (make-overlay start end)
            o-int (make-overlay start-int end))
      (overlay-put o-top 'category 'form-feed--hs)
      (overlay-put o-top 'form-feed--hs-interior o-int)
      (overlay-put o-int 'category 'form-feed--hs-interior)
      ;; (let ((num-lines-hidden
      ;;        (when (< (- end start) 100000)
      ;;          (format "[%d lines]"
      ;;                  (- (line-number-at-pos end)
      ;;                     (line-number-at-pos start-int))))))
      ;;   (overlay-put o-int 'before-string num-lines-hidden))
      )))


;; Font-lock definitions

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

    (add-hook 'emacs-lisp-mode-hook 'form-feed-mode)

Clicking the horizontal lines will hide/show following sections of
code. Comments just after the form-feed function as headers."
  :lighter " ^L"
  (let ((invisibility '(form-feed . t)))
    (cond
     (form-feed-mode
      (add-to-invisibility-spec invisibility)
      (form-feed--add-font-lock-keywords))
     (t
      (form-feed-show-all)
      (remove-from-invisibility-spec invisibility)
      (form-feed--remove-font-lock-keywords)))))

(provide 'form-feed)
;;; form-feed.el ends here
