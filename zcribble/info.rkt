#lang info

(define collection 'multi)

(define deps '("zcribble-lib"
               "zcribble-doc"))
(define implies '("zcribble-lib"
                  "zcribble-doc"))

(define pkg-desc "Racket documentatation and typesetting tool")

(define pkg-authors '(mflatt eli))

(define license
  '(Apache-2.0 OR MIT))
