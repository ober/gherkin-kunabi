#!chezscheme
;; Waitgroup compat module — replaces Gerbil's :std/misc/wg
;; Uses Chez condition variables for synchronization
(library (compat wg)
  (export make-wg wg-add! wg-wait!)
  (import (chezscheme))

  ;; A waitgroup tracks: max-workers, active count, mutex, condition-var
  (define-record-type wg
    (fields max-workers
            (mutable active)
            (mutable pending)
            mutex
            cv)
    (protocol
      (lambda (new)
        (lambda (max-workers)
          (new max-workers 0 0 (make-mutex) (make-condition))))))

  ;; Add a thunk to the waitgroup — spawns a thread
  (define (wg-add! wg thunk)
    ;; Wait if at capacity
    (let ([mx (wg-mutex wg)]
          [cv (wg-cv wg)])
      (mutex-acquire mx)
      (let wait ()
        (when (>= (wg-active wg) (wg-max-workers wg))
          (condition-wait cv mx)
          (wait)))
      (wg-active-set! wg (+ (wg-active wg) 1))
      (wg-pending-set! wg (+ (wg-pending wg) 1))
      (mutex-release mx)
      ;; Spawn thread
      (fork-thread
        (lambda ()
          (guard (exn [#t (void)])
            (thunk))
          (mutex-acquire mx)
          (wg-active-set! wg (- (wg-active wg) 1))
          (wg-pending-set! wg (- (wg-pending wg) 1))
          (condition-broadcast cv)
          (mutex-release mx)))))

  ;; Wait for all threads to complete
  (define (wg-wait! wg)
    (let ([mx (wg-mutex wg)]
          [cv (wg-cv wg)])
      (mutex-acquire mx)
      (let wait ()
        (when (> (wg-pending wg) 0)
          (condition-wait cv mx)
          (wait)))
      (mutex-release mx)))
)
