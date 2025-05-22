#lang racket/base

(require "example-nc.rkt"
         (only-in "eval.rkt"
                  make-base-eval
                  make-base-eval-factory
                  make-eval-factory
                  close-eval

                  make-log-based-eval
                  scribble-exn->string
                  scribble-eval-handler)
         racket/contract
         "struct.rkt"
         (for-syntax racket/base
                     syntax/parse))

(provide examples

         ;; Re-exports:
         make-base-eval
         make-base-eval-factory
         make-eval-factory
         close-eval

         make-log-based-eval
         scribble-exn->string
         scribble-eval-handler)

