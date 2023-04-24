; -*- encoding: utf-8; indent-tabs-mode: nil -*-
(progn
(defun md-arrow      () (interactive) (insert "→"))
(defun md-backquotes () (interactive) (insert "``")   (forward-char -1))
(defun md-guillemets () (interactive) (insert "«  »") (forward-char -2))
(defun md-programme  () (interactive) (insert "\n```\n\n```\n") (forward-line -2))
  (define-key global-map "\C-c-"      'md-arrow)
  (define-key global-map "\C-cè"      'md-backquotes)
  (define-key global-map "\C-c<"      'md-guillemets)
  (define-key global-map "\C-cp"      'md-programme)
)
