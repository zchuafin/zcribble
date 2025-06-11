#lang racket/base
(require zcribble/private/lp)
(provide chunk CHUNK)

(module reader syntax/module-reader
  zcribble/lp/lang/lang2

  #:read read-inside
  #:read-syntax read-syntax-inside
  #:whole-body-readers? #t
  #:info (scribble-base-info)
  (require scribble/reader
           (only-in scribble/base/reader
                    scribble-base-info)))
