#!chezscheme
;; Build a native kunabi binary.
;;
;; Produces a fully self-contained ELF with zero dependencies on any
;; Chez kernel, libs, boot files, or external .so files.
;;
;; Usage: cd gherkin-kunabi && make binary

(import (chezscheme))

;; --- Helper: generate C header from binary file ---
(define (file->c-header input-path output-path array-name size-name)
  (let* ((port (open-file-input-port input-path))
         (data (get-bytevector-all port))
         (size (bytevector-length data)))
    (close-port port)
    (call-with-output-file output-path
      (lambda (out)
        (fprintf out "/* Auto-generated */~n")
        (fprintf out "static const unsigned char ~a[] = {~n" array-name)
        (let loop ((i 0))
          (when (< i size)
            (when (= 0 (modulo i 16)) (fprintf out "  "))
            (fprintf out "0x~2,'0x" (bytevector-u8-ref data i))
            (when (< (+ i 1) size) (fprintf out ","))
            (when (= 15 (modulo i 16)) (fprintf out "~n"))
            (loop (+ i 1))))
        (fprintf out "~n};~n")
        (fprintf out "static const unsigned int ~a = ~a;~n" size-name size))
      'replace)
    (printf "  ~a: ~a bytes~n" output-path size)))

;; --- Locate Chez install directory ---
(define chez-dir
  (or (getenv "CHEZ_DIR")
      (let* ((mt (symbol->string (machine-type)))
             (home (getenv "HOME"))
             (lib-dir (format "~a/.local/lib" home))
             (csv-dir
               (let lp ((dirs (guard (e (#t '())) (directory-list lib-dir))))
                 (cond
                   ((null? dirs) #f)
                   ((and (> (string-length (car dirs)) 3)
                         (string=? "csv" (substring (car dirs) 0 3)))
                    (format "~a/~a/~a" lib-dir (car dirs) mt))
                   (else (lp (cdr dirs)))))))
        (and csv-dir
             (file-exists? (format "~a/main.o" csv-dir))
             csv-dir))))

(unless chez-dir
  (display "Error: Cannot find Chez install dir. Set CHEZ_DIR.\n")
  (exit 1))

;; --- Locate gherkin runtime ---
(define gherkin-dir
  (or (getenv "GHERKIN_DIR")
      (let ((home (getenv "HOME")))
        (format "~a/mine/gherkin/src" home))))

(unless (file-exists? (format "~a/compat/types.so" gherkin-dir))
  (printf "Error: Cannot find gherkin runtime at ~a~n" gherkin-dir)
  (exit 1))

;; --- Locate leveldb shim source ---
(define chez-leveldb-dir
  (or (getenv "CHEZ_LEVELDB_DIR")
      (let ((home (getenv "HOME")))
        (format "~a/mine/chez-leveldb" home))))

;; --- Locate chez-ssl and chez-zlib ---
(define home (getenv "HOME"))
(define chez-ssl-dir (format "~a/mine/chez-ssl" home))
(define chez-https-dir (format "~a/mine/chez-https" home))
(define chez-zlib-dir (format "~a/mine/chez-zlib" home))

(printf "Chez dir:      ~a~n" chez-dir)
(printf "Gherkin dir:   ~a~n" gherkin-dir)
(printf "LevelDB shim:  ~a~n" chez-leveldb-dir)
(printf "SSL shim:      ~a~n" chez-ssl-dir)
(printf "Zlib shim:     ~a~n" chez-zlib-dir)

(printf "
[1/7] Compiling C shims (leveldb, ssl, zlib)...
")
;; LevelDB shim
(let ((cmd (format "gcc -c -O2 -o leveldb_shim.o ~a/leveldb_shim.c -I/usr/include 2>&1"
             chez-leveldb-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: leveldb_shim.c compilation failed\n")
    (exit 1)))

;; SSL shim
(let ((cmd (format "gcc -c -O2 -o chez_ssl_shim.o ~a/chez_ssl_shim.c -I/usr/include 2>&1"
             chez-ssl-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: chez_ssl_shim.c compilation failed\n")
    (exit 1)))

;; Zlib shim
(let ((cmd (format "gcc -c -O2 -o chez_zlib_shim.o ~a/chez_zlib_shim.c -I/usr/include 2>&1"
             chez-zlib-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: chez_zlib_shim.c compilation failed\n")
    (exit 1)))

(printf "[2/7] Compiling all modules...
")
;; Prepend src/ to library-directories so our embedded (leveldb) library
;; (which uses load-shared-object "" instead of loading external .so files)
;; takes priority over the external chez-leveldb version.
;; Also include chez-ssl, chez-https, chez-zlib source dirs.
(parameterize ([compile-imported-libraries #t]
               [library-directories (append (list
                                              '("src" . "src")
                                              '("gherkin-aws/src" . "gherkin-aws/src")
                                              (cons gherkin-dir gherkin-dir)
                                              (cons chez-leveldb-dir chez-leveldb-dir))
                                            (library-directories))])
  (compile-program "kunabi.ss"))

(printf "[3/7] Creating boot file with libraries + program...
")
;; Include BOTH libraries and the program in the boot file.
;; This avoids the need for Sscheme_script/memfd entirely.
(apply make-boot-file "kunabi.boot" '("scheme" "petite")
  (append
    (list
      (format "~a/compat/types.so" gherkin-dir)
      (format "~a/compat/gambit-compat.so" gherkin-dir)
      (format "~a/runtime/util.so" gherkin-dir)
      (format "~a/runtime/table.so" gherkin-dir)
      (format "~a/runtime/c3.so" gherkin-dir)
      (format "~a/runtime/mop.so" gherkin-dir)
      (format "~a/runtime/error.so" gherkin-dir)
      (format "~a/runtime/hash.so" gherkin-dir)
      (format "~a/runtime/syntax.so" gherkin-dir)
      (format "~a/runtime/eval.so" gherkin-dir)
      (format "~a/reader/reader.so" gherkin-dir)
      (format "~a/compiler/compile.so" gherkin-dir)
      (format "~a/boot/gherkin.so" gherkin-dir)
      (format "~a/compat/std-sync-channel.so" gherkin-dir)
      (format "~a/compat/std-srfi-19.so" gherkin-dir)
      (format "~a/compat/std-getopt.so" gherkin-dir)
      (format "~a/compat/std-srfi-13.so" gherkin-dir)
      (format "~a/compat/std-text-base64.so" gherkin-dir)
      (format "~a/compat/std-crypto-digest.so" gherkin-dir)
    )
    ;; chez-ssl, chez-https, chez-zlib (local copies in src/)
    (list "src/chez-ssl.so" "src/chez-https.so" "src/chez-zlib.so")
    (map (lambda (m) (format "src/compat/~a.so" m))
      '(json sugar process format pregexp sort getopt misc gambit wg))
    (map (lambda (m) (format "src/clan/~a.so" m))
      '(db-leveldb text-yaml))
    ;; Use our embedded (leveldb) that resolves symbols from the process
    (list "src/leveldb.so")
    (map (lambda (m) (format "gherkin-aws/src/compat/~a.so" m))
      '(request uri sigv4))
    (map (lambda (m) (format "gherkin-aws/src/gerbil-aws/~a.so" m))
      '(aws-creds s3-xml s3-api s3-objects))
    (map (lambda (m) (format "src/ober/~a.so" m))
      '(kunabi-main kunabi-config kunabi-storage kunabi-parser
        kunabi-loader kunabi-query kunabi-detection kunabi-billing))
    ;; Include the program itself in the boot file
    (list "kunabi.so")))

(printf "[4/7] Embedding boot files as C headers...
")
(file->c-header (format "~a/petite.boot" chez-dir) "kunabi_petite_boot.h"
                "petite_boot_data" "petite_boot_size")
(file->c-header (format "~a/scheme.boot" chez-dir) "kunabi_scheme_boot.h"
                "scheme_boot_data" "scheme_boot_size")
(file->c-header "kunabi.boot" "kunabi_app_boot.h"
                "kunabi_app_boot_data" "kunabi_app_boot_size")

(printf "[5/7] Compiling and linking...
")
(let ((cmd (format "gcc -c -O2 -o kunabi-main.o kunabi-main.c -I~a -I. -Wall 2>&1" chez-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: C compilation failed\n")
    (exit 1)))
;; Link: Chez kernel (static .a) + C shims + system libs.
;; Now includes chez_ssl_shim.o and chez_zlib_shim.o for native HTTPS and gzip.
(let ((cmd (format (string-append
              "gcc -rdynamic -o gherkin-kunabi"
              " kunabi-main.o leveldb_shim.o chez_ssl_shim.o chez_zlib_shim.o"
              " -L~a -lkernel"
              " -lleveldb -lssl -lcrypto"
              " -llz4 -lz -lm -ldl -lpthread -luuid -lncurses -lstdc++"
              " 2>&1")
             chez-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: Link failed\n")
    (exit 1)))

(printf "[6/7] Cleaning up...
")
(for-each (lambda (f)
            (when (file-exists? f) (delete-file f)))
  '("kunabi-main.o" "leveldb_shim.o" "chez_ssl_shim.o" "chez_zlib_shim.o"
    "kunabi_petite_boot.h" "kunabi_scheme_boot.h" "kunabi_app_boot.h"
    "kunabi.so" "kunabi.wpo" "kunabi.boot"))

(printf "
========================================
")
(printf "Build complete!

")
(let ((p (open-file-input-port "gherkin-kunabi")))
  (printf "  Binary: ./gherkin-kunabi  (~a KB)~n"
    (quotient (file-length p) 1024))
  (close-port p))
(printf "  Self-contained: native HTTPS + gzip, no curl subprocess~n")
