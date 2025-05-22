#lang racket/base

(require "valid-blueboxes-info-nc.rkt")

(require scribble/core racket/contract/base)

(provide
 (contract-out
  (valid-blueboxes-info?
   (-> any/c boolean?))))