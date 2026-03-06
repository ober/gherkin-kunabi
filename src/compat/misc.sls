#!chezscheme
;;; misc.sls -- Miscellaneous utilities from :std/misc/*
;;; Provides string, list, path, and hash utilities used by gsh.

(library (compat misc)
  (export
    ;; string
    string-prefix? string-suffix? string-split string-join
    string-trim string-trim-right string-contains
    ;; list
    flatten pgetq unique every any iota last take drop
    fold-right remove partition filter
    ;; path
    path-expand path-directory path-strip-directory
    path-extension path-strip-extension
    ;; hash
    hash-ref/default hash-copy/alist
    ;; string (additional)
    string-empty?
    ;; Note: read-line and call-with-output-string are in (compat gambit)
    )

  (import (except (chezscheme) iota filter remove partition fold-right path-extension))

  ;; --- string utilities ---

  (define (string-prefix? prefix str)
    (let ((plen (string-length prefix))
          (slen (string-length str)))
      (and (<= plen slen)
           (string=? prefix (substring str 0 plen)))))

  (define (string-suffix? suffix str)
    (let ((xlen (string-length suffix))
          (slen (string-length str)))
      (and (<= xlen slen)
           (string=? suffix (substring str (- slen xlen) slen)))))

  (define (string-split str sep)
    (let ((slen (string-length str))
          (seplen (string-length sep)))
      (if (= seplen 0) (list str)
        (let loop ((i 0) (start 0) (result '()))
          (cond
            ((> (+ i seplen) slen)
             (reverse (cons (substring str start slen) result)))
            ((string=? (substring str i (+ i seplen)) sep)
             (loop (+ i seplen) (+ i seplen)
                   (cons (substring str start i) result)))
            (else (loop (+ i 1) start result)))))))

  (define (string-join lst sep)
    (if (null? lst) ""
      (let ((p (open-output-string)))
        (display (car lst) p)
        (for-each (lambda (s) (display sep p) (display s p)) (cdr lst))
        (get-output-string p))))

  (define (string-trim str)
    (let* ((len (string-length str))
           (start (let loop ((i 0))
                    (if (and (< i len) (char-whitespace? (string-ref str i)))
                      (loop (+ i 1)) i)))
           (end (let loop ((i (- len 1)))
                  (if (and (>= i start) (char-whitespace? (string-ref str i)))
                    (loop (- i 1)) (+ i 1)))))
      (substring str start end)))

  (define (string-trim-right str)
    (let* ((len (string-length str))
           (end (let loop ((i (- len 1)))
                  (if (and (>= i 0) (char-whitespace? (string-ref str i)))
                    (loop (- i 1)) (+ i 1)))))
      (substring str 0 end)))

  (define (string-contains haystack needle)
    (let ((nlen (string-length needle))
          (hlen (string-length haystack)))
      (if (> nlen hlen) #f
        (let loop ((i 0))
          (cond
            ((> (+ i nlen) hlen) #f)
            ((string=? (substring haystack i (+ i nlen)) needle) i)
            (else (loop (+ i 1))))))))

  ;; --- list utilities ---

  (define (last lst)
    (if (null? (cdr lst))
      (car lst)
      (last (cdr lst))))


  (define (take lst n)
    (if (or (zero? n) (null? lst)) '()
      (cons (car lst) (take (cdr lst) (- n 1)))))

  (define (drop lst n)
    (if (or (zero? n) (null? lst)) lst
      (drop (cdr lst) (- n 1))))

  (define (flatten lst)
    (cond
      ((null? lst) '())
      ((pair? (car lst))
       (append (flatten (car lst)) (flatten (cdr lst))))
      (else (cons (car lst) (flatten (cdr lst))))))

  (define (pgetq key plist)
    (cond
      ((null? plist) #f)
      ((null? (cdr plist)) #f)
      ((eq? key (car plist)) (cadr plist))
      (else (pgetq key (cddr plist)))))

  (define (unique lst)
    (let loop ((l lst) (seen '()) (result '()))
      (cond
        ((null? l) (reverse result))
        ((member (car l) seen) (loop (cdr l) seen result))
        (else (loop (cdr l) (cons (car l) seen) (cons (car l) result))))))

  (define (every pred lst)
    (or (null? lst)
        (and (pred (car lst))
             (every pred (cdr lst)))))

  (define (any pred lst)
    (and (pair? lst)
         (or (pred (car lst))
             (any pred (cdr lst)))))

  (define (iota n . args)
    (let ((start (if (pair? args) (car args) 0))
          (step (if (and (pair? args) (pair? (cdr args))) (cadr args) 1)))
      (let loop ((i 0) (result '()))
        (if (>= i n) (reverse result)
          (loop (+ i 1) (cons (+ start (* i step)) result))))))

  ;; --- path utilities ---

  (define (path-expand path . rest)
    (let ((base (if (pair? rest) (car rest) (current-directory))))
      (cond
        ((and (> (string-length path) 0)
              (char=? (string-ref path 0) #\~))
         (string-append (getenv "HOME")
                        (substring path 1 (string-length path))))
        ((and (> (string-length path) 0)
              (char=? (string-ref path 0) #\/))
         path)
        (else (string-append base "/" path)))))

  (define (path-directory path)
    (let ((idx (let loop ((i (- (string-length path) 1)))
                 (cond ((< i 0) #f)
                       ((char=? (string-ref path i) #\/) i)
                       (else (loop (- i 1)))))))
      (if idx
        (if (= idx 0) "/" (substring path 0 idx))
        ".")))

  (define (path-strip-directory path)
    (let ((idx (let loop ((i (- (string-length path) 1)))
                 (cond ((< i 0) #f)
                       ((char=? (string-ref path i) #\/) i)
                       (else (loop (- i 1)))))))
      (if idx
        (substring path (+ idx 1) (string-length path))
        path)))

  (define (path-extension path)
    (let* ((base (path-strip-directory path))
           (idx (let loop ((i (- (string-length base) 1)))
                  (cond ((< i 0) #f)
                        ((char=? (string-ref base i) #\.) i)
                        (else (loop (- i 1)))))))
      (if (and idx (> idx 0))
        (substring base idx (string-length base))
        "")))

  (define (path-strip-extension path)
    (let ((idx (let loop ((i (- (string-length path) 1)))
                 (cond ((< i 0) #f)
                       ((char=? (string-ref path i) #\/) #f)
                       ((char=? (string-ref path i) #\.) i)
                       (else (loop (- i 1)))))))
      (if (and idx (> idx 0))
        (substring path 0 idx)
        path)))

  ;; --- hash utilities ---

  (define (hash-ref/default ht key default)
    (if (hashtable-contains? ht key)
      (hashtable-ref ht key #f)
      default))

  (define (hash-copy/alist ht)
    (let-values (((keys vals) (hashtable-entries ht)))
      (let loop ((i 0) (result '()))
        (if (>= i (vector-length keys))
          result
          (loop (+ i 1) (cons (cons (vector-ref keys i) (vector-ref vals i)) result))))))

  (define (string-empty? s) (= (string-length s) 0))


  (define (fold-right f init lst)
    (if (null? lst) init
      (f (car lst) (fold-right f init (cdr lst)))))

  (define (filter pred lst)
    (cond ((null? lst) '())
          ((pred (car lst)) (cons (car lst) (filter pred (cdr lst))))
          (else (filter pred (cdr lst)))))

  (define (remove pred lst)
    (filter (lambda (x) (not (pred x))) lst))

  (define (partition pred lst)
    (let loop ((l lst) (yes '()) (no '()))
      (cond ((null? l) (values (reverse yes) (reverse no)))
            ((pred (car l)) (loop (cdr l) (cons (car l) yes) no))
            (else (loop (cdr l) yes (cons (car l) no))))))

  ) ;; end library
