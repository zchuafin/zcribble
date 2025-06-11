#lang racket/base
(require racket/match
         zcribble/scheme
         zcribble/basic
         zcribble/struct
         zcribble/manual
         (for-label racket/base))

(provide parse-match-grammar)

(define (match-nonterm s)
  (make-element variable-color (list s)))

(define (fixup s middle)
  (lambda (m)
    (make-element #f
                  (list (fixup-meaning (substring s 0 (caar m)))
                        middle
                        (fixup-meaning (substring s (cdar m)))))))

(define (fixup-meaning s)
  (cond
   [(regexp-match-positions #rx"pattern" s)
    => (fixup s "pattern")]
   [(regexp-match-positions #rx"equal%" s)
    => (fixup s (racket equal?))]
   [(regexp-match-positions #rx"pat" s)
    => (fixup s (fixup-sexp 'pat))]
   [(regexp-match-positions #rx"qp" s)
    => (fixup s (fixup-sexp 'qp))]
   [(regexp-match-positions #rx"lvp" s)
    => (fixup s (fixup-sexp 'lvp))]
   [(regexp-match-positions #rx"kv-opt" s)
    => (fixup s (fixup-sexp 'kv-opt))]
   [(regexp-match-positions #rx"ht-opt" s)
    => (fixup s (fixup-sexp 'ht-opt))]
   [(regexp-match-positions #rx"struct-id" s)
    => (fixup s (fixup-sexp 'struct-id))]
   [(regexp-match-positions #rx"pred-expr" s)
    => (fixup s (fixup-sexp 'pred-expr))]
   [(regexp-match-positions #rx"def-expr" s)
    => (fixup s (fixup-sexp 'def-expr))]
   [(regexp-match-positions #rx"expr" s)
    => (fixup s (fixup-sexp 'expr))]
   [(regexp-match-positions #rx"[*][*][*]" s)
    => (fixup s (racketidfont "..."))]
   [(regexp-match-positions #rx"[(]" s)
    => (fixup s (racketparenfont "("))]
   [(regexp-match-positions #rx"[)]" s)
    => (fixup s (racketparenfont ")"))]
   [(regexp-match-positions #rx"K" s)
    => (fixup s (match-nonterm "k"))]
   [else s]))

(define (fixup-rhs s)
  (to-element (fixup-sexp (read-syntax #f (open-input-string s)))))

(define (fixup-sexp s)
  (match (cond
           [(syntax? s) (syntax-e s)]
           [else s])
    [(list xs ...)
     (cond
       [(and (syntax? s) (syntax-property s 'paren-shape))
        (shaped-parens (map fixup-sexp xs) (syntax-property s 'paren-shape))]
       [else (map fixup-sexp xs)])]
    [(cons a b) (cons (fixup-sexp a) (fixup-sexp b))]
    [(vector xs ...) (list->vector (map fixup-sexp xs))]
    [(box s)
     (box (fixup-sexp s))]
    [(? struct? s)
     (apply make-prefab-struct
            (prefab-struct-key s)
            (cdr (map fixup-sexp (vector->list (struct->vector s)))))]
    [(? symbol? s)
     (case s
       [(lvp pat qp ht-opt kv-opt literal ooo datum struct-id
             string bytes number character expr id
             rx-expr px-expr pred-expr def-expr
             derived-pattern)
        (match-nonterm (symbol->string s))]
       [(QUOTE VAR LIST LIST-REST LIST* LIST-NO-ORDER VECTOR HASH-TABLE BOX STRUCT
               REGEXP PREGEXP AND OR NOT APP ? QUASIQUOTE CONS MCONS HASH HASH*)
        (make-element symbol-color (list (string-downcase (symbol->string s))))]
       [(***)
        (make-element symbol-color '("..."))]
       [(___) (make-element symbol-color '("___"))]
       [(__K)
        (make-element #f (list (make-element symbol-color '("__"))
                               (match-nonterm "k")))]
       [(..K)
        (make-element #f (list (make-element symbol-color '(".."))
                               (match-nonterm "k")))]
       [else s])]
    [(? keyword? s) (make-element paren-color (list (format "~a" s)))]
    [_ s]))

(define re:start-prod #rx"^([^ ]*)( +)::= (.*[^ ])( +)[@](.*)$")
(define re:or-prod #rx"^( +) [|]  (.*[^ ])( +)[@](.*)$")
(define re:eng-prod #rx"^([^ ]*)( +):== (.*)$")

(define (parse-match-grammar grammar)
  (define lines (let ([lines (regexp-split "\r?\n" grammar)])
                  (reverse (cdr (reverse (cdr lines))))))

  (define spacer (hspace 1))

  (define (to-flow e)
    (make-flow (list (make-paragraph (list e)))))

  (define (table-line lhs eql rhs desc)
    (list (to-flow lhs)
          (to-flow spacer)
          (to-flow eql)
          (to-flow spacer)
          (to-flow rhs)
          (to-flow spacer)
          (to-flow desc)))

  (define equals (tt "::="))
  (define -or- (tt " | "))

  (make-table
   #f
   (map
    (lambda (line)
      (cond
       [(regexp-match re:start-prod line)
        => (lambda (m)
             (let ([prod (list-ref m 1)]
                   [lspace (list-ref m 2)]
                   [val (list-ref m 3)]
                   [rspace (list-ref m 4)]
                   [meaning (list-ref m 5)])
               (table-line (match-nonterm prod)
                           equals
                           (fixup-rhs val)
                           (fixup-meaning meaning))))]
       [(regexp-match re:eng-prod line)
        => (lambda (m)
             (let ([prod (list-ref m 1)]
                   [lspace (list-ref m 2)]
                   [meaning (list-ref m 3)])
               (table-line (match-nonterm prod)
                           equals
                           "???"
                           (fixup-meaning meaning))))]
       [(regexp-match re:or-prod line)
        => (lambda (m)
             (let ([lspace (list-ref m 1)]
                   [val (list-ref m 2)]
                   [rspace (list-ref m 3)]
                   [meaning (list-ref m 4)])
               (table-line spacer
                           -or-
                           (fixup-rhs val)
                           (fixup-meaning meaning))))]
       [else (error 'make-match-grammar
                    "non-matching line: ~e"
                    line)]))
    lines)))


