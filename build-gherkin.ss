#!chezscheme
;;; build-gherkin.ss — Compile kunabi .ss modules to .sls via Gherkin compiler
;;; Usage: scheme -q --libdirs src:<gherkin-path> --compile-imported-libraries < build-gherkin.ss

(import
  (except (chezscheme) void box box? unbox set-box!
          andmap ormap iota last-pair find
          1+ 1- fx/ fx1+ fx1-
          error error? raise with-exception-handler identifier?
          hash-table? make-hash-table)
  (compiler compile))

(define submodule-dir "kunabi")
(define output-dir "src/ober")

(define (find-source path)
  (let ((local (string-append "./" path))
        (sub   (string-append submodule-dir "/" path)))
    (cond
      ((file-exists? local) local)
      ((file-exists? sub)   sub)
      (else (error 'find-source "source file not found" path)))))

(define ober-import-map
  '((*default-package* . ober)
    (:gerbil/compiler . #f)
    (:gerbil/expander . #f)
    (:gerbil/runtime/loader . #f)
    (:gerbil/runtime/init . #f)
    (:gerbil/runtime . #f)
    (:gerbil/core . #f)
    (:std/test . #f)
    (:std/build-script . #f)
    (:std/foreign . #f)
    (:std/srfi/1 . (compat misc))
    (:std/error . (runtime error))
    (:std/iter . #f)
    (:std/misc/hash . (compat misc))
    (:std/misc/path . (compat misc))
    (:std/misc/list . (compat misc))
    (:std/misc/string . (compat misc))
    (:std/sort . (compat sort))
    (:std/format . (compat format))
    (:std/sugar . (compat sugar))
    (:std/pregexp . (compat pregexp))
    (:std/cli/getopt . (compat getopt))
    (:std/misc/process . (compat process))
    (:std/text/json . (compat json))
    ))

(define ober-base-imports
  '((except (chezscheme) box box? unbox set-box!
            andmap ormap iota last-pair find
            1+ 1- fx/ fx1+ fx1-
            error? raise with-exception-handler identifier?
            hash-table? make-hash-table
            sort sort! path-extension
            printf fprintf
            file-directory? file-exists? getenv close-port
            void
            open-output-file open-input-file)
    (compat types)
    (except (runtime util)
            string->bytes bytes->string
            string-split string-join find string-index
            pgetq pgetv pget)
    (except (runtime table) string-hash)
    (runtime mop)
    (except (runtime error) with-catch with-exception-catcher)
    (runtime hash)
    (except (compat gambit) number->string make-mutex
            with-output-to-string)
    (compat misc)))

;; --- Import conflict resolution ---
(define (fix-import-conflicts lib-form)
  (let* ((lib-name (cadr lib-form))
         (export-clause (caddr lib-form))
         (import-clause (cadddr lib-form))
         (body (cddddr lib-form))
         (imports (cdr import-clause))
         (local-defs
           (let lp ((forms body) (names '()))
             (if (null? forms) names
               (lp (cdr forms) (append (extract-def-names (car forms)) names)))))
         (all-earlier-names
           (let lp ((imps imports) (seen '()) (result '()))
             (if (null? imps) (reverse result)
               (let* ((imp (car imps))
                      (lib (get-import-lib-name imp))
                      (exports (if lib
                                 (or (begin (ensure-library-loaded lib)
                                       (guard (e (#t #f)) (library-exports lib)))
                                     (read-sls-exports lib) '()) '()))
                      (provided (cond
                                  ((and (pair? imp) (eq? (car imp) 'except))
                                   (filter (lambda (s) (not (memq s (cddr imp)))) exports))
                                  ((and (pair? imp) (eq? (car imp) 'only)) (cddr imp))
                                  (else exports))))
                 (lp (cdr imps) (append provided seen) (cons seen result)))))))
    (let ((fixed-imports
            (map (lambda (imp earlier-names)
                   (fix-one-import imp (append local-defs earlier-names)))
                 imports all-earlier-names)))
      (let ((fixed-body (fix-assigned-exports (cdr export-clause)
                          (list (cons 'import fixed-imports)) body)))
        `(library ,lib-name ,export-clause
          (import ,@fixed-imports) ,@fixed-body)))))

(define (fix-assigned-exports exports import-forms body)
  (let ((assigned-names
          (let lp ((tree body) (names '()))
            (cond ((not (pair? tree)) names)
              ((and (eq? (car tree) 'set!) (pair? (cdr tree))
                    (symbol? (cadr tree)) (memq (cadr tree) exports)
                    (not (memq (cadr tree) names)))
               (cons (cadr tree) names))
              (else (lp (cdr tree) (lp (car tree) names)))))))
    (if (null? assigned-names) body
      (let ((new-body
              (let lp ((forms body) (result '()))
                (if (null? forms) (reverse result)
                  (let ((form (car forms)))
                    (cond
                      ((and (pair? form) (eq? (car form) 'define)
                            (let ((def-name (if (pair? (cadr form)) (caadr form) (cadr form))))
                              (and (symbol? def-name) (memq def-name assigned-names))))
                       (let* ((def-name (if (pair? (cadr form)) (caadr form) (cadr form)))
                              (init (if (pair? (cadr form))
                                      `(lambda ,(cdadr form) ,@(cddr form))
                                      (if (pair? (cddr form)) (caddr form) '(void))))
                              (cell-name (string->symbol
                                           (string-append (symbol->string def-name) "-cell"))))
                         (lp (cdr forms)
                             (append (list
                                       `(define-syntax ,def-name
                                          (identifier-syntax
                                            (id (vector-ref ,cell-name 0))
                                            ((set! id v) (vector-set! ,cell-name 0 v))))
                                       `(define ,cell-name (vector ,init)))
                                     result))))
                      (else (lp (cdr forms) (cons form result)))))))))
        new-body))))

(define (extract-def-names form)
  (cond ((not (pair? form)) '())
    ((eq? (car form) 'define)
     (cond ((symbol? (cadr form)) (list (cadr form)))
       ((pair? (cadr form)) (list (caadr form))) (else '())))
    ((eq? (car form) 'define-syntax)
     (if (symbol? (cadr form)) (list (cadr form)) '()))
    ((eq? (car form) 'begin)
     (let lp ((forms (cdr form)) (names '()))
       (if (null? forms) names
         (lp (cdr forms) (append (extract-def-names (car forms)) names)))))
    (else '())))

(define (ensure-library-loaded lib-name)
  (guard (e (#t #f)) (eval `(import ,lib-name) (interaction-environment)) #t))

(define (read-sls-exports lib-name)
  (let ((path (lib-name->sls-path lib-name)))
    (if (and path (file-exists? path))
      (guard (e (#t #f))
        (call-with-input-file path
          (lambda (port)
            (let ((first (read port)))
              (let ((lib-form (if (and (pair? first) (eq? (car first) 'library))
                                first (read port))))
                (if (and (pair? lib-form) (eq? (car lib-form) 'library))
                  (let ((export-clause (caddr lib-form)))
                    (if (and (pair? export-clause) (eq? (car export-clause) 'export))
                      (cdr export-clause) #f)) #f))))))
      #f)))

(define (lib-name->sls-path lib-name)
  (cond
    ((and (pair? lib-name) (= (length lib-name) 2) (eq? (car lib-name) 'ober))
     (string-append output-dir "/" (symbol->string (cadr lib-name)) ".sls"))
    ((and (pair? lib-name) (= (length lib-name) 2) (eq? (car lib-name) 'compat))
     (string-append "src/compat/" (symbol->string (cadr lib-name)) ".sls"))
    (else #f)))

(define (fix-one-import imp local-defs)
  (let ((lib-name (get-import-lib-name imp)))
    (if (not lib-name) imp
      (let* ((_load (ensure-library-loaded lib-name))
             (lib-exports (or (guard (e (#t #f)) (library-exports lib-name))
                              (read-sls-exports lib-name) '()))
             (conflicts (filter (lambda (d) (memq d lib-exports)) local-defs)))
        (if (null? conflicts) imp
          (cond
            ((and (pair? imp) (eq? (car imp) 'except))
             (let ((existing (cddr imp)))
               `(except ,(cadr imp) ,@existing
                  ,@(filter (lambda (d) (not (memq d existing))) conflicts))))
            ((and (pair? imp) (eq? (car imp) 'only))
             `(only ,(cadr imp) ,@(filter (lambda (s) (not (memq s conflicts))) (cddr imp))))
            ((pair? imp) `(except ,imp ,@conflicts))
            (else imp)))))))

(define (get-import-lib-name spec)
  (cond
    ((and (pair? spec) (memq (car spec) '(except only rename prefix)))
     (get-import-lib-name (cadr spec)))
    ((and (pair? spec) (symbol? (car spec))) spec)
    (else #f)))

;; --- Module compilation ---
(define (compile-module source-path flat-name)
  (let* ((input-path (find-source source-path))
         (output-path (string-append output-dir "/" flat-name ".sls"))
         (lib-name `(ober ,(string->symbol flat-name))))
    (display (string-append "  Compiling: " input-path " → " flat-name ".sls\n"))
    (guard (exn
             (#t (display (string-append "  ERROR: " input-path " failed: "))
                 (display (condition-message exn))
                 (when (irritants-condition? exn)
                   (display " — ") (display (condition-irritants exn)))
                 (newline) #f))
      (let* ((lib-form (gerbil-compile-to-library
                         input-path lib-name ober-import-map ober-base-imports))
             (lib-form (fix-import-conflicts lib-form)))
        (call-with-output-file output-path
          (lambda (port)
            (display "#!chezscheme\n" port)
            (parameterize ([print-gensym #f])
              (pretty-print lib-form port)))
          'replace)
        (display (string-append "  OK: " output-path "\n")) #t))))

(display "=== Gherkin OBER Builder ===\n\n")

(display "--- Compiling modules ---\n")
(compile-module "kunabi/main.ss" "kunabi-main")
(compile-module "kunabi/gui-main.ss" "kunabi-gui-main")
(compile-module "kunabi/billing.ss" "kunabi-billing")
(compile-module "kunabi/loader.ss" "kunabi-loader")
(compile-module "kunabi/parser.ss" "kunabi-parser")
(compile-module "kunabi/detection.ss" "kunabi-detection")
(compile-module "kunabi/storage.ss" "kunabi-storage")
(compile-module "kunabi/config.ss" "kunabi-config")
(compile-module "kunabi/query.ss" "kunabi-query")
(compile-module "kunabi/gui.ss" "kunabi-gui")

(display "\n=== Build complete ===\n")
