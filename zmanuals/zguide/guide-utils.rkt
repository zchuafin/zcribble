#lang at-exp racket/base

(require zcribble/manual
         zcribble/struct
         zcribble/decode
         zcribble/eval
         syntax/parse/define
         "../icons.rkt")

(require (for-label racket/base)
         (for-syntax racket/base))
(provide (for-label (all-from-out racket/base)))

(provide Racket HtDP inside-doc
         tool
         moreguide
         guideother
         refalso
         refdetails
         refdetails/gory
         refsecref
         ext-refsecref
         r5rs r6rs
         hash-lang-note)

(define HtDP
  (italic (link "https://htdp.org" "How to Design Programs")))

(define (tool name . desc)
  (apply item (bold name) ", " desc))

(define (moreguide tag . s)
  (apply margin-note
         (decode-content (append
                          (list
                           finger (secref tag) " (later in this guide)"
                           " explains more about ")
                          s
                          (list ".")))))

(define (guideother . s)
  (apply margin-note
         (cons finger (decode-content s))))

(define (refdetails* tag what . s)
  (apply margin-note
         (decode-content (append (list magnify (ext-refsecref tag))
                                 (list what)
                                 s
                                 (list ".")))))

(define (refdetails tag . s)
  (apply refdetails* tag " provides more on " s))

(define (refalso tag . s)
  (apply refdetails* tag " also documents " s))

(define (refdetails/gory tag . s)
  (apply refdetails* tag " documents the fine points of " s))

(define (refsecref s)
  (secref #:doc '(lib "scribblings/reference/reference.scrbl") s))

(define (ext-refsecref s)
  (make-element #f (list (refsecref s) " in " Racket)))

(define Racket (other-manual '(lib "scribblings/reference/reference.scrbl")))

(define inside-doc '(lib "scribblings/inside/inside.scrbl"))

(define r6rs @elem{R@superscript{6}RS})
(define r5rs @elem{R@superscript{5}RS})

(define-syntax-parse-rule (hash-lang-note what {~optional {~seq #:lang lang}})
  @margin-note{@racket[(require what)] is needed@(~? @elem{ for @racket[@#,hash-lang[] @#,racketmodname[lang]]}).})
