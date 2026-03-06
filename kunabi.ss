#!chezscheme
(import (chezscheme)
        (ober kunabi-main))

(suppress-greeting #t)

(scheme-start
  (lambda fmls
    (apply main fmls)
    (exit 0)))
