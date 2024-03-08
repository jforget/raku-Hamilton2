; -*- encoding: utf-8; indent-tabs-mode: nil -*-
(progn
(defun md-arrow         () (interactive) (insert "→"))  ; U+2192 rightwards arrow
(defun md-arrow2        () (interactive) (insert "↣"))  ; U+21A3 rightwards arrow with tail
(defun md-less-equal    () (interactive) (insert "≤"))  ; U+2264 less-than or equal to
(defun md-greater-equal () (interactive) (insert "≥"))  ; U+2265 greater-than or equal to
(defun md-epsilon    () (interactive) (insert "ε"))
(defun md-iota       () (interactive) (insert "ɩ"))
(defun md-kappa      () (interactive) (insert "κ"))
(defun md-lambda     () (interactive) (insert "λ"))
(defun md-pi         () (interactive) (insert "π"))
(defun md-join       () (interactive) (insert "⟗"))
(defun md-infinite   () (interactive) (insert "∞"))
(defun md-backquotes () (interactive) (insert "``")   (forward-char -1))
(defun md-guillemets () (interactive) (insert "«  »") (forward-char -2))
(defun md-programme  () (interactive) (insert "\n```\n\n```\n") (forward-line -2))
  (define-key global-map "\C-c-"      'md-arrow)
  (define-key global-map "\C-c\C-c-"  'md-arrow2)
  (define-key global-map "\C-c<"      'md-less-equal)
  (define-key global-map "\C-c>"      'md-greater-equal)
  (define-key global-map "\C-ce"      'md-epsilon)
  (define-key global-map "\C-ci"      'md-iota)
  (define-key global-map "\C-cj"      'md-join)
  (define-key global-map "\C-ck"      'md-kappa)
  (define-key global-map "\C-cl"      'md-lambda)
  (define-key global-map "\C-cp"      'md-pi)
  (define-key global-map "\C-cè"      'md-backquotes)
  (define-key global-map "\C-cb"      'md-inifinite)
  (define-key global-map "\C-c\C-c<"  'md-guillemets)
  (define-key global-map "\C-cp"      'md-programme)
)
