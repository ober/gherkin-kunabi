(library (chez-zlib)
  (export gunzip-bytevector
          inflate-bytevector
          gzip-bytevector
          deflate-bytevector
          gzip-data?)
  (import (chezscheme))

  ;; Load shim symbols from the process itself
  ;; (the shim is statically linked into the binary via -rdynamic)
  (define dummy (load-shared-object ""))

  (define c-gunzip
    (foreign-procedure "chez_gunzip"
      (u8* size_t void* void*)
      int))

  (define c-inflate
    (foreign-procedure "chez_inflate"
      (u8* size_t void* void*)
      int))

  (define c-gzip
    (foreign-procedure "chez_gzip"
      (u8* size_t void* void*)
      int))

  (define c-deflate
    (foreign-procedure "chez_deflate"
      (u8* size_t void* void*)
      int))

  (define c-memcpy-to-bv
    (foreign-procedure "chez_memcpy_to_bv"
      (u8* void* size_t)
      void))

  (define c-zlib-free
    (foreign-procedure "chez_zlib_free" (void*) void))

  (define (call-zlib who c-func bv)
    (let ([out-ptr (foreign-alloc 8)]
          [out-len (foreign-alloc 8)])
      (let ([rc (c-func bv (bytevector-length bv) out-ptr out-len)])
        (if (= rc 0)
            (let* ([ptr (foreign-ref 'void* out-ptr 0)]
                   [len (foreign-ref 'size_t out-len 0)]
                   [result (make-bytevector len)])
              (c-memcpy-to-bv result ptr len)
              (c-zlib-free ptr)
              (foreign-free out-ptr)
              (foreign-free out-len)
              result)
            (begin
              (foreign-free out-ptr)
              (foreign-free out-len)
              (error who "zlib operation failed" bv))))))

  (define (gunzip-bytevector bv)
    (call-zlib 'gunzip-bytevector c-gunzip bv))

  (define (inflate-bytevector bv)
    (call-zlib 'inflate-bytevector c-inflate bv))

  (define (gzip-bytevector bv)
    (call-zlib 'gzip-bytevector c-gzip bv))

  (define (deflate-bytevector bv)
    (call-zlib 'deflate-bytevector c-deflate bv))

  (define (gzip-data? bv)
    (and (bytevector? bv)
         (>= (bytevector-length bv) 2)
         (= (bytevector-u8-ref bv 0) #x1f)
         (= (bytevector-u8-ref bv 1) #x8b))))
