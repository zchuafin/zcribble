#lang racket/base
(require "core.rkt" 
         "base-render.rkt"
         "private/render-utils.rkt"
         "text-render-nc.rkt"
         racket/contract
         racket/class racket/port racket/list racket/string
         scribble/text/wrap)

(provide
 (contract-out
  (render-mixin
   (-> class? class?))))