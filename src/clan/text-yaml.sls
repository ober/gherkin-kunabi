#!chezscheme
;;; text-yaml.sls -- Stub for (clan text-yaml)
;;; TODO: Implement YAML parsing for kunabi config

(library (clan text-yaml)
  (export yaml-load)
  (import (chezscheme))

  (define (yaml-load port)
    (error 'yaml-load "clan text-yaml not yet implemented")))
