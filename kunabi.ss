#!chezscheme
;; Entry point for gherkin-ober
(import (chezscheme)
        (ober main))

;; Get args from KUNABI_ARGC/KUNABI_ARGn env vars (set by kunabi-main.c)
;; or fall back to (command-line) for interpreted mode.
(define (get-real-args)
  (let ((argc-str (getenv "KUNABI_ARGC")))
    (if argc-str
      (let ((argc (string->number argc-str)))
        (let loop ((i 0) (acc '()))
          (if (>= i argc)
            (reverse acc)
            (let ((val (getenv (format "KUNABI_ARG~a" i))))
              (loop (+ i 1) (cons (or val "") acc))))))
      (let ((cmdline (command-line)))
        (if (pair? cmdline) (cdr cmdline) '())))))

(apply main (get-real-args))
