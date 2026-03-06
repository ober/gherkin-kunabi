#!chezscheme
;; Re-export from gherkin's full getopt implementation
(library (compat getopt)
  (export
    getopt
    getopt?
    getopt-object?
    getopt-error?
    getopt-parse
    getopt-display-help
    getopt-display-help-topic
    option
    flag
    command
    argument
    optional-argument
    rest-arguments
    call-with-getopt)
  (import (compat std-getopt)))
