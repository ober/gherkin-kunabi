#!chezscheme
;;; text-yaml.sls -- Minimal YAML parser for kunabi config files
;;; Supports: scalars, lists of scalars, lists of key-value maps, comments

(library (clan text-yaml)
  (export yaml-load)
  (import
    (except (chezscheme) box box? unbox set-box! andmap ormap
     iota last-pair find \x31;+ \x31;- fx/ fx1+ fx1- error? raise
     with-exception-handler identifier? hash-table?
     make-hash-table sort sort! path-extension printf fprintf
     file-directory? file-exists? getenv close-port void
     open-output-file open-input-file)
    (compat types)
    (except (runtime util) string->bytes bytes->string
      string-split string-join find string-index pgetq pgetv pget)
    (except (runtime table) string-hash)
    (except (runtime mop) class-type-flag-system
     class-type-flag-metaclass class-type-flag-sealed
     class-type-flag-struct type-flag-id type-flag-concrete
     type-flag-macros type-flag-extensible type-flag-opaque
     \x23;\x23;type-fields \x23;\x23;type-super
     \x23;\x23;type-flags \x23;\x23;type-name \x23;\x23;type-id
     \x23;\x23;structure-copy
     \x23;\x23;structure-direct-instance-of?
     \x23;\x23;structure-instance-of?
     \x23;\x23;unchecked-structure-set!
     \x23;\x23;unchecked-structure-ref \x23;\x23;structure-set!
     \x23;\x23;structure-ref \x23;\x23;structure-type-set!
     \x23;\x23;structure-type \x23;\x23;structure?
     \x23;\x23;structure)
    (except (runtime error) with-catch with-exception-catcher)
    (runtime hash))

  ;; Strip leading/trailing whitespace
  (define (string-trim s)
    (let* ([len (string-length s)]
           [start (let loop ([i 0])
                    (if (and (< i len) (char-whitespace? (string-ref s i)))
                        (loop (+ i 1))
                        i))]
           [end (let loop ([i len])
                  (if (and (> i start) (char-whitespace? (string-ref s (- i 1))))
                      (loop (- i 1))
                      i))])
      (substring s start end)))

  ;; Count leading spaces
  (define (indent-level line)
    (let loop ([i 0])
      (if (and (< i (string-length line)) (char=? (string-ref line i) #\space))
          (loop (+ i 1))
          i)))

  ;; Strip inline comments (respecting quoted strings)
  (define (strip-comment s)
    (let ([len (string-length s)])
      (let loop ([i 0] [in-quote #f] [qchar #\space])
        (cond
          [(>= i len) s]
          [(and (not in-quote)
                (char=? (string-ref s i) #\#)
                (or (= i 0)
                    (char-whitespace? (string-ref s (- i 1)))))
           (string-trim (substring s 0 i))]
          [(and (not in-quote)
                (or (char=? (string-ref s i) #\")
                    (char=? (string-ref s i) #\')))
           (loop (+ i 1) #t (string-ref s i))]
          [(and in-quote (char=? (string-ref s i) qchar))
           (loop (+ i 1) #f #\space)]
          [else (loop (+ i 1) in-quote qchar)]))))

  ;; Remove surrounding quotes from a string value
  (define (unquote-value s)
    (let ([len (string-length s)])
      (if (and (>= len 2)
               (or (and (char=? (string-ref s 0) #\")
                        (char=? (string-ref s (- len 1)) #\"))
                   (and (char=? (string-ref s 0) #\')
                        (char=? (string-ref s (- len 1)) #\'))))
          (substring s 1 (- len 1))
          s)))

  ;; Check if line starts with "- " after indentation
  (define (list-item? line)
    (let ([trimmed (string-trim line)])
      (and (>= (string-length trimmed) 2)
           (char=? (string-ref trimmed 0) #\-)
           (char=? (string-ref trimmed 1) #\space))))

  ;; Get content after "- "
  (define (list-item-content line)
    (let* ([trimmed (string-trim line)]
           [rest (substring trimmed 2 (string-length trimmed))])
      (string-trim rest)))

  ;; Check if string contains ": " or ends with ":"
  (define (has-colon? s)
    (let ([len (string-length s)])
      (and (> len 0)
           (or
             ;; Ends with ":"  (key with block value)
             (char=? (string-ref s (- len 1)) #\:)
             ;; Contains ": " (key: value)
             (let loop ([i 0])
               (cond
                 [(>= i (- len 1)) #f]
                 [(and (char=? (string-ref s i) #\:)
                       (char=? (string-ref s (+ i 1)) #\space))
                  #t]
                 [else (loop (+ i 1))]))))))

  ;; Split "key: value" or "key:" into (key . value)
  (define (split-key-value s)
    (let ([len (string-length s)])
      (let loop ([i 0])
        (cond
          [(>= i len) (cons s "")]
          [(char=? (string-ref s i) #\:)
           (if (= i (- len 1))
               ;; Trailing colon: "key:"
               (cons (string-trim (substring s 0 i)) "")
               (if (char=? (string-ref s (+ i 1)) #\space)
                   ;; "key: value"
                   (cons (string-trim (substring s 0 i))
                         (unquote-value (string-trim (substring s (+ i 2) len))))
                   (loop (+ i 1))))]
          [else (loop (+ i 1))]))))

  ;; Read all lines from a file
  (define (read-lines path)
    (call-with-input-file path
      (lambda (port)
        (let loop ([acc '()])
          (let ([line (get-line port)])
            (if (eof-object? line)
                (reverse acc)
                (loop (cons line acc))))))))

  ;; Parse a YAML file, returns a list of documents (each a hash table)
  (define (yaml-load path)
    (let ([lines (read-lines path)])
      (let-values ([(ht _rest) (parse-mapping lines 0)])
        (list ht))))

  ;; Parse top-level mapping from lines, returns (values hash-table remaining-lines)
  (define (parse-mapping lines base-indent)
    (let ([ht (make-hash-table)])
      (let loop ([lines lines])
        (if (null? lines)
            (values ht '())
            (let* ([line (car lines)]
                   [stripped (strip-comment line)]
                   [trimmed (string-trim stripped)])
              (cond
                ;; Skip blank lines, comments, YAML directives, doc markers
                [(or (string=? trimmed "")
                     (and (> (string-length trimmed) 0)
                          (char=? (string-ref trimmed 0) #\#))
                     (and (>= (string-length trimmed) 3)
                          (string=? (substring trimmed 0 3) "---"))
                     (and (>= (string-length trimmed) 4)
                          (string=? (substring trimmed 0 4) "%YAML")))
                 (loop (cdr lines))]
                ;; Key-value line
                [(has-colon? trimmed)
                 (let* ([kv (split-key-value trimmed)]
                        [key (car kv)]
                        [val (cdr kv)])
                   (if (string=? val "")
                       ;; Value is on subsequent indented lines (list)
                       (let-values ([(list-val rest) (parse-list-value (cdr lines) (indent-level line))])
                         (hash-put! ht key list-val)
                         (loop rest))
                       ;; Simple scalar value
                       (begin
                         (hash-put! ht key val)
                         (loop (cdr lines)))))]
                [else (loop (cdr lines))]))))
      (values ht '())))

  ;; Parse indented list items, returns (values list remaining-lines)
  (define (parse-list-value lines parent-indent)
    (let loop ([lines lines] [acc '()])
      (if (null? lines)
          (values (reverse acc) '())
          (let* ([line (car lines)]
                 [stripped (strip-comment line)]
                 [trimmed (string-trim stripped)])
            (cond
              ;; Skip blank/comment lines within the list
              [(or (string=? trimmed "")
                   (and (> (string-length trimmed) 0)
                        (char=? (string-ref trimmed 0) #\#)))
               (loop (cdr lines) acc)]
              ;; Not indented enough — end of list
              [(<= (indent-level line) parent-indent)
               (values (reverse acc) lines)]
              ;; List item
              [(list-item? line)
               (let ([content (list-item-content stripped)])
                 (if (has-colon? content)
                     ;; Map item like "- user: foo"
                     (let-values ([(map-val rest) (parse-map-item content (cdr lines) (indent-level line))])
                       (loop rest (cons map-val acc)))
                     ;; Simple scalar list item
                     (loop (cdr lines) (cons (unquote-value content) acc))))]
              ;; Continuation of previous map item (indented key: val after "- key: val")
              [(and (not (null? acc)) (hash-table? (car acc)) (has-colon? trimmed))
               (let* ([kv (split-key-value trimmed)]
                      [map-ht (car acc)])
                 (hash-put! map-ht (car kv) (cdr kv))
                 (loop (cdr lines) acc))]
              [else (loop (cdr lines) acc)])))))

  ;; Parse a map item starting with "key: val", possibly with more k-v lines
  (define (parse-map-item first-content rest-lines item-indent)
    (let* ([kv (split-key-value first-content)]
           [ht (make-hash-table)])
      (hash-put! ht (car kv) (cdr kv))
      ;; Consume additional key-value lines at deeper indent
      (let loop ([lines rest-lines])
        (if (null? lines)
            (values ht '())
            (let* ([line (car lines)]
                   [stripped (strip-comment line)]
                   [trimmed (string-trim stripped)])
              (cond
                [(or (string=? trimmed "")
                     (and (> (string-length trimmed) 0)
                          (char=? (string-ref trimmed 0) #\#)))
                 (loop (cdr lines))]
                [(and (> (indent-level line) item-indent)
                      (has-colon? trimmed))
                 (let ([kv2 (split-key-value trimmed)])
                   (hash-put! ht (car kv2) (cdr kv2))
                   (loop (cdr lines)))]
                [else (values ht lines)]))))))
)
