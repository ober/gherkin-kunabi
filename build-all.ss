#!chezscheme
;; Build driver: imports all modules to trigger Chez compilation
(import
  (ober kunabi-main)
  ;; (ober kunabi-gui-main) ;; needs Qt FFI
  (ober kunabi-billing)
  (ober kunabi-loader)
  (ober kunabi-parser)
  (ober kunabi-detection)
  (ober kunabi-storage)
  (ober kunabi-config)
  (ober kunabi-query)
  ;; (ober kunabi-gui) ;; needs Qt FFI
)
