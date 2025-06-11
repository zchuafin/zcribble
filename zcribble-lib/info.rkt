#lang info

(define collection 'multi)

(define deps '("scheme-lib"
               "base"
               "compatibility-lib"
               "zcribble-text-lib"
               "zcribble-html-lib"
               "planet-lib" ; used dynamically
               "net-lib"
               "at-exp-lib"
               "draw-lib" 
               "syntax-color-lib"
               "sandbox-lib"
               "typed-racket-lib"
               ))
(define build-deps '("rackunit-lib")) ; for embedded module+ test

(define implies '("zcribble-html-lib"))

(define pkg-desc "implementation (no documentation) part of \"scribble\"")

(define pkg-authors '(mflatt eli))

(define version "1.51")

(define license
  '((Apache-2.0 OR MIT)
    AND
    (CC-BY-3.0 ;; sigplanconf.cls
     AND
     (LPPL-1.3c+ ;; acmart.cls
      AND
      LPPL-1.0+)))) ;; pltstabular
