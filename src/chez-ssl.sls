(library (chez-ssl)
  (export ssl-init! ssl-cleanup!
          ssl-connect ssl-write ssl-write-string
          ssl-read ssl-read-all ssl-close
          ssl-connection?)
  (import (chezscheme))

  ;; Load system SSL libs + shim symbols from the process itself
  ;; (the shim is statically linked into the binary via -rdynamic)
  (define load-libs
    (begin
      (load-shared-object "libssl.so")
      (load-shared-object "libcrypto.so")
      (load-shared-object "")))

  (define c-ssl-init     (foreign-procedure "chez_ssl_init" () void))
  (define c-ssl-cleanup  (foreign-procedure "chez_ssl_cleanup" () void))
  (define c-ssl-connect  (foreign-procedure "chez_ssl_connect" (string int u8* int) void*))
  (define c-ssl-write    (foreign-procedure "chez_ssl_write" (void* u8* int) int))
  (define c-ssl-read     (foreign-procedure "chez_ssl_read" (void* u8* int) int))
  (define c-ssl-read-all (foreign-procedure "chez_ssl_read_all" (void* void*) void*))
  (define c-ssl-close    (foreign-procedure "chez_ssl_close" (void*) void))
  (define c-ssl-free-buf (foreign-procedure "chez_ssl_free_buf" (void*) void))
  (define c-ssl-memcpy   (foreign-procedure "chez_ssl_memcpy" (u8* void* size_t) void))

  ;; Track live connections for ssl-connection? predicate
  (define *live-connections* '())

  (define (ssl-connection? obj)
    (and (memq obj *live-connections*) #t))

  (define (ssl-init!) (c-ssl-init))
  (define (ssl-cleanup!) (c-ssl-cleanup))

  (define (ssl-connect hostname port)
    (let ([err-buf (make-bytevector 256 0)])
      (let ([conn (c-ssl-connect hostname port err-buf 256)])
        (if (zero? conn)  ;; void* returns integer; NULL = 0
            (error 'ssl-connect
                   (utf8->string (bytevector-trim-nuls err-buf))
                   hostname port)
            (begin
              (set! *live-connections* (cons conn *live-connections*))
              conn)))))

  (define (ssl-write conn bv)
    (let ([rc (c-ssl-write conn bv (bytevector-length bv))])
      (unless (= rc 0)
        (error 'ssl-write "write failed"))))

  (define (ssl-write-string conn str)
    (ssl-write conn (string->utf8 str)))

  (define (ssl-read conn buf len)
    (c-ssl-read conn buf len))

  (define (ssl-read-all conn)
    (let ([len-buf (foreign-alloc 8)])
      (let ([ptr (c-ssl-read-all conn len-buf)])
        (if (zero? ptr)  ;; void* returns integer; NULL = 0
            (begin (foreign-free len-buf)
                   (error 'ssl-read-all "read failed"))
            (let* ([len (foreign-ref 'size_t len-buf 0)]
                   [result (make-bytevector len)])
              (c-ssl-memcpy result ptr len)
              (c-ssl-free-buf ptr)
              (foreign-free len-buf)
              result)))))

  (define (ssl-close conn)
    (set! *live-connections* (remq conn *live-connections*))
    (c-ssl-close conn))

  ;; Helper
  (define (bytevector-trim-nuls bv)
    (let loop ([i 0])
      (if (or (= i (bytevector-length bv))
              (= (bytevector-u8-ref bv i) 0))
          (let ([result (make-bytevector i)])
            (bytevector-copy! bv 0 result 0 i)
            result)
          (loop (+ i 1))))))
