;; chez-https — Native HTTP/1.1 client over TLS for Chez Scheme
;;
;; Dependencies:
;;   chez-ssl  — https://github.com/ober/chez-ssl
;;   chez-zlib — https://github.com/ober/chez-zlib (optional, for gzip content)
;;
;; Provides the same API as (compat request) for drop-in replacement.

(library (chez-https)
  (export
    ;; HTTP client API
    http-get http-post http-put http-delete http-head
    ;; Response accessors
    request-status request-text request-content
    request-headers request-header request-close
    ;; Utilities
    parse-url flatten-request-headers build-query-string url-encode)
  (import (chezscheme) (chez-ssl))

  ;; ================================================================
  ;; String utilities
  ;; ================================================================

  (define (string-prefix? prefix str)
    (let ([plen (string-length prefix)]
          [slen (string-length str)])
      (and (>= slen plen)
           (string=? prefix (substring str 0 plen)))))

  (define (string-index str ch)
    (let ([len (string-length str)])
      (let loop ([i 0])
        (cond
          [(= i len) #f]
          [(char=? (string-ref str i) ch) i]
          [else (loop (+ i 1))]))))

  (define (string-contains str needle)
    (let ([hlen (string-length str)]
          [nlen (string-length needle)])
      (let loop ([i 0])
        (cond
          [(> (+ i nlen) hlen) #f]
          [(string=? needle (substring str i (+ i nlen))) i]
          [else (loop (+ i 1))]))))

  (define (string-trim-left str)
    (let ([len (string-length str)])
      (let loop ([i 0])
        (if (and (< i len) (char-whitespace? (string-ref str i)))
            (loop (+ i 1))
            (substring str i len)))))

  (define (string-trim str)
    (let* ([len (string-length str)]
           [start (let loop ([i 0])
                    (if (and (< i len) (char-whitespace? (string-ref str i)))
                        (loop (+ i 1))
                        i))]
           [end (let loop ([i len])
                  (if (and (> i start) (char-whitespace? (string-ref str (- i 1))))
                      (loop (- i 1))
                      i))])
      (substring str start end)))

  (define (string-join strs sep)
    (if (null? strs)
        ""
        (let loop ([rest (cdr strs)] [acc (car strs)])
          (if (null? rest)
              acc
              (loop (cdr rest) (string-append acc sep (car rest)))))))

  (define (string-split-crlf str)
    (let ([len (string-length str)])
      (let loop ([start 0] [i 0] [acc '()])
        (cond
          [(>= i len)
           (reverse (if (> i start)
                        (cons (substring str start i) acc)
                        acc))]
          [(and (char=? (string-ref str i) #\return)
                (< (+ i 1) len)
                (char=? (string-ref str (+ i 1)) #\newline))
           (loop (+ i 2) (+ i 2) (cons (substring str start i) acc))]
          [else (loop start (+ i 1) acc)]))))

  ;; ================================================================
  ;; Bytevector utilities
  ;; ================================================================

  (define (subbytevector bv start end)
    (let ([result (make-bytevector (- end start))])
      (bytevector-copy! bv start result 0 (- end start))
      result))

  (define (bytevector-concat-list bvs)
    (if (null? bvs)
        (make-bytevector 0)
        (let* ([total (fold-left + 0 (map bytevector-length bvs))]
               [result (make-bytevector total)])
          (let loop ([bvs bvs] [offset 0])
            (if (null? bvs)
                result
                (let ([bv (car bvs)])
                  (bytevector-copy! bv 0 result offset (bytevector-length bv))
                  (loop (cdr bvs) (+ offset (bytevector-length bv)))))))))

  (define (find-crlfcrlf bv len start)
    (let loop ([i start])
      (if (> (+ i 3) len)
          #f
          (if (and (= (bytevector-u8-ref bv i) 13)
                   (= (bytevector-u8-ref bv (+ i 1)) 10)
                   (= (bytevector-u8-ref bv (+ i 2)) 13)
                   (= (bytevector-u8-ref bv (+ i 3)) 10))
              i
              (loop (+ i 1))))))

  (define (read-bv-line bv start len)
    ;; Read line from bytevector terminated by \r\n.
    ;; Returns (values line-string position-after-crlf)
    (let loop ([i start])
      (cond
        [(>= (+ i 1) len)
         (values (utf8->string (subbytevector bv start len)) len)]
        [(and (= (bytevector-u8-ref bv i) 13)
              (= (bytevector-u8-ref bv (+ i 1)) 10))
         (values (utf8->string (subbytevector bv start i)) (+ i 2))]
        [else (loop (+ i 1))])))

  ;; ================================================================
  ;; URL encoding (RFC 3986)
  ;; ================================================================

  (define hex-chars "0123456789ABCDEF")

  (define (url-encode str)
    (let ([out (open-output-string)])
      (string-for-each
       (lambda (c)
         (let ([b (char->integer c)])
           (cond
             [(or (and (fx>= b 65) (fx<= b 90))   ; A-Z
                  (and (fx>= b 97) (fx<= b 122))  ; a-z
                  (and (fx>= b 48) (fx<= b 57))   ; 0-9
                  (memv c '(#\- #\_ #\. #\~)))
              (write-char c out)]
           [else
            (let ([bv (string->utf8 (string c))])
              (do ([i 0 (+ i 1)])
                  ((= i (bytevector-length bv)))
                (let ([b (bytevector-u8-ref bv i)])
                  (write-char #\% out)
                  (write-char (string-ref hex-chars (fxsrl b 4)) out)
                  (write-char (string-ref hex-chars (fxand b #xf)) out))))])))
       str)
      (get-output-string out)))

  ;; ================================================================
  ;; URL parsing
  ;; ================================================================

  (define (parse-url url)
    ;; Returns (values host port path)
    ;; path includes any query string already in the URL.
    (let* ([https? (string-prefix? "https://" url)]
           [http?  (string-prefix? "http://" url)]
           [_ (unless (or https? http?)
                (error 'parse-url "unsupported URL scheme" url))]
           [after-scheme (substring url (if https? 8 7) (string-length url))]
           [slash-pos (string-index after-scheme #\/)]
           [host-port (if slash-pos
                         (substring after-scheme 0 slash-pos)
                         after-scheme)]
           [path (if slash-pos
                     (substring after-scheme slash-pos (string-length after-scheme))
                     "/")]
           [colon-pos (string-index host-port #\:)]
           [host (if colon-pos
                     (substring host-port 0 colon-pos)
                     host-port)]
           [port (if colon-pos
                     (string->number (substring host-port (+ colon-pos 1)
                                                (string-length host-port)))
                     (if https? 443 80))])
      (values host port path)))

  ;; ================================================================
  ;; Header flattening
  ;; ================================================================

  (define (flatten-request-headers hdrs)
    ;; Input:  (("Name" :: "Value") :: ("Name2" :: "Value2") ...)
    ;; Output: (("Name" . "Value") ("Name2" . "Value2") ...)
    ;; Handles the nested :: separator format used by the S3 API layer.
    (if (or (not hdrs) (null? hdrs) (not (pair? hdrs)))
        '()
        (let loop ([items hdrs] [result '()])
          (cond
            [(null? items) (reverse result)]
            [(and (symbol? (car items)) (eq? (car items) '::))
             (loop (cdr items) result)]
            [(pair? (car items))
             (let ([item (car items)])
               (if (and (pair? item)
                        (string? (car item))
                        (pair? (cdr item))
                        (eq? (cadr item) '::)
                        (pair? (cddr item)))
                   (loop (cdr items)
                         (cons (cons (car item) (caddr item)) result))
                   ;; Recurse into nested structure
                   (loop (cdr items)
                         (append (reverse (flatten-request-headers item)) result))))]
            [else (loop (cdr items) result)]))))

  ;; ================================================================
  ;; Query string building
  ;; ================================================================

  (define (build-query-string params)
    ;; params uses the same (name :: value) format as headers.
    (if (or (not params) (null? params))
        ""
        (let ([pairs (flatten-request-headers params)])
          (string-join
           (map (lambda (p)
                  (string-append (url-encode (car p)) "=" (url-encode (cdr p))))
                pairs)
           "&"))))

  ;; ================================================================
  ;; Header lookup (case-insensitive)
  ;; ================================================================

  (define (header-assoc name headers)
    (let ([name-lower (string-downcase name)])
      (let loop ([h headers])
        (cond
          [(null? h) #f]
          [(string=? name-lower (string-downcase (caar h))) (car h)]
          [else (loop (cdr h))]))))

  ;; ================================================================
  ;; HTTP request building
  ;; ================================================================

  (define (build-request method path host headers body-bv)
    (let ([out (open-output-string)])
      (put-string out method)
      (put-string out " ")
      (put-string out path)
      (put-string out " HTTP/1.1\r\n")
      ;; Host header (unless user provided one)
      (unless (header-assoc "Host" headers)
        (put-string out "Host: ")
        (put-string out host)
        (put-string out "\r\n"))
      ;; User-supplied headers
      (for-each
       (lambda (h)
         (put-string out (car h))
         (put-string out ": ")
         (put-string out (cdr h))
         (put-string out "\r\n"))
       headers)
      ;; Content-Length for requests with body
      (when (and body-bv (not (header-assoc "Content-Length" headers)))
        (put-string out "Content-Length: ")
        (put-string out (number->string (bytevector-length body-bv)))
        (put-string out "\r\n"))
      ;; Connection: close (first version; keep-alive is a future optimization)
      (put-string out "Connection: close\r\n")
      (put-string out "\r\n")
      (get-output-string out)))

  ;; ================================================================
  ;; Response parsing
  ;; ================================================================

  (define (parse-status-line line)
    ;; "HTTP/1.1 200 OK" -> 200
    (let ([space (string-index line #\space)])
      (unless space
        (error 'parse-status-line "malformed status line" line))
      (let* ([rest (substring line (+ space 1) (string-length line))]
             [space2 (string-index rest #\space)]
             [code-str (if space2 (substring rest 0 space2) rest)])
        (or (string->number code-str)
            (error 'parse-status-line "invalid status code" code-str)))))

  (define (parse-headers lines)
    ;; Parse header lines into alist with lowercase keys.
    (let loop ([lines lines] [acc '()])
      (if (null? lines)
          (reverse acc)
          (let* ([line (car lines)]
                 [colon (string-index line #\:)])
            (if colon
                (loop (cdr lines)
                      (cons (cons (string-downcase (substring line 0 colon))
                                  (string-trim-left
                                   (substring line (+ colon 1) (string-length line))))
                            acc))
                (loop (cdr lines) acc))))))

  (define (header-value headers name)
    (let ([pair (assoc name headers)])
      (and pair (cdr pair))))

  (define (chunked-encoding? headers)
    (let ([te (header-value headers "transfer-encoding")])
      (and te (string-contains (string-downcase te) "chunked") #t)))

  ;; ================================================================
  ;; Chunked transfer decoding
  ;; ================================================================

  (define (decode-chunked bv)
    (let ([len (bytevector-length bv)])
      (let loop ([pos 0] [chunks '()])
        (if (>= pos len)
            (bytevector-concat-list (reverse chunks))
            (let-values ([(size-str next-pos) (read-bv-line bv pos len)])
              ;; Chunk size may have extensions after semicolon
              (let* ([semi (string-index size-str #\;)]
                     [hex-str (string-trim (if semi (substring size-str 0 semi) size-str))]
                     [chunk-size (string->number hex-str 16)])
                (cond
                  [(or (not chunk-size) (= chunk-size 0))
                   (bytevector-concat-list (reverse chunks))]
                  [(> (+ next-pos chunk-size) len)
                   ;; Truncated final chunk — use what we have
                   (bytevector-concat-list
                    (reverse (cons (subbytevector bv next-pos len) chunks)))]
                  [else
                   (loop (+ next-pos chunk-size 2)
                         (cons (subbytevector bv next-pos (+ next-pos chunk-size))
                               chunks))])))))))

  ;; ================================================================
  ;; SSL auto-initialization
  ;; ================================================================

  (define *ssl-initialized* #f)

  (define (ensure-ssl-init!)
    (unless *ssl-initialized*
      (ssl-init!)
      (set! *ssl-initialized* #t)))

  ;; ================================================================
  ;; Response reading
  ;; ================================================================

  (define (read-response conn)
    ;; With Connection: close, ssl-read-all reads the entire response.
    (let* ([raw (ssl-read-all conn)]
           [len (bytevector-length raw)])
      (let loop ([offset 0])
        (let ([sep (find-crlfcrlf raw len offset)])
          (unless sep
            (error 'read-response
                   "malformed HTTP response: no header terminator found"
                   (if (< len 500) (utf8->string raw) "<response too large to display>")))
          (let* ([header-str (utf8->string (subbytevector raw offset sep))]
                 [body-start (+ sep 4)]
                 [lines (string-split-crlf header-str)])
            (when (null? lines)
              (error 'read-response "empty HTTP response"))
            (let ([status (parse-status-line (car lines))]
                  [headers (parse-headers (cdr lines))])
              (if (= status 100)
                  ;; Skip "100 Continue" and parse the real response
                  (loop body-start)
                  (let* ([raw-body (if (< body-start len)
                                      (subbytevector raw body-start len)
                                      (make-bytevector 0))]
                         [body (if (chunked-encoding? headers)
                                   (decode-chunked raw-body)
                                   raw-body)])
                    (values status headers body)))))))))

  ;; ================================================================
  ;; Request result accessors
  ;; ================================================================

  (define (make-request-result status headers body-bv)
    (vector status headers body-bv))

  (define (request-status req) (vector-ref req 0))
  (define (request-headers req) (vector-ref req 1))
  (define (request-content req) (vector-ref req 2))

  (define (request-text req)
    (let ([body (vector-ref req 2)])
      (if (= (bytevector-length body) 0)
          ""
          (utf8->string body))))

  (define (request-header req name)
    (let ([pair (assoc (string-downcase name) (vector-ref req 1))])
      (and pair (cdr pair))))

  (define (request-close req) (void))

  ;; ================================================================
  ;; Keyword argument parsing
  ;; ================================================================

  (define (parse-keyword-args args)
    ;; Parse ('headers: val 'params: val 'data: val)
    ;; Returns (values headers params data)
    (let loop ([args args] [headers '()] [params #f] [data #f])
      (if (null? args)
          (values headers params data)
          (if (null? (cdr args))
              (error 'http-request "missing value for keyword" (car args))
              (let ([key (car args)] [val (cadr args)])
                (cond
                  [(eq? key 'headers:) (loop (cddr args) val params data)]
                  [(eq? key 'params:)  (loop (cddr args) headers val data)]
                  [(eq? key 'data:)    (loop (cddr args) headers params val)]
                  [else (error 'http-request "unknown keyword" key)]))))))

  ;; ================================================================
  ;; Core request function
  ;; ================================================================

  (define (do-request method url headers params data)
    (ensure-ssl-init!)
    (let-values ([(host port path) (parse-url url)])
      (let* ([query (build-query-string params)]
             [full-path (cond
                          [(string=? query "") path]
                          [(string-contains path "?")
                           (string-append path "&" query)]
                          [else
                           (string-append path "?" query)])]
             [flat-headers (flatten-request-headers headers)]
             [body-bv (cond
                        [(not data) #f]
                        [(bytevector? data) data]
                        [(string? data) (string->utf8 data)]
                        [else (error 'do-request "unsupported body type" data)])]
             [request-str (build-request method full-path host flat-headers body-bv)]
             [conn (ssl-connect host port)])
        (dynamic-wind
          void
          (lambda ()
            (ssl-write-string conn request-str)
            (when body-bv (ssl-write conn body-bv))
            (let-values ([(status resp-headers body) (read-response conn)])
              (make-request-result status resp-headers body)))
          (lambda ()
            (guard (e [#t (void)])
              (ssl-close conn)))))))

  ;; ================================================================
  ;; Public API
  ;; ================================================================

  (define (http-get url . args)
    (let-values ([(headers params data) (parse-keyword-args args)])
      (do-request "GET" url headers params #f)))

  (define (http-post url . args)
    (let-values ([(headers params data) (parse-keyword-args args)])
      (do-request "POST" url headers params data)))

  (define (http-put url . args)
    (let-values ([(headers params data) (parse-keyword-args args)])
      (do-request "PUT" url headers params data)))

  (define (http-delete url . args)
    (let-values ([(headers params data) (parse-keyword-args args)])
      (do-request "DELETE" url headers params #f)))

  (define (http-head url . args)
    (let-values ([(headers params data) (parse-keyword-args args)])
      (do-request "HEAD" url headers params #f)))

) ;; end library
