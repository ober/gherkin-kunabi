#!chezscheme
;; Gzip decompression compat module
(library (compat gzip)
  (export gunzip-bytes gzip-data?)
  (import (chezscheme))

  ;; Decompress gzip data via temporary file + gunzip subprocess
  (define (gunzip-bytes bv)
    (let* ([tmp (string-append "/tmp/kunabi-gz-" (number->string (random 1000000)) ".gz")])
      (let ([p (open-file-output-port tmp)])
        (put-bytevector p bv)
        (close-port p))
      (let-values ([(to-stdin from-stdout from-stderr pid)
                    (open-process-ports (string-append "gunzip -c " tmp) 'block (native-transcoder))])
        (close-port to-stdin)
        (let ([result (get-string-all from-stdout)])
          (close-port from-stdout)
          (close-port from-stderr)
          (when (file-exists? tmp) (delete-file tmp))
          result))))

  ;; Check if data looks like gzip (starts with magic bytes 1f 8b)
  (define (gzip-data? bv)
    (and (bytevector? bv)
         (>= (bytevector-length bv) 2)
         (= (bytevector-u8-ref bv 0) #x1f)
         (= (bytevector-u8-ref bv 1) #x8b)))
)
