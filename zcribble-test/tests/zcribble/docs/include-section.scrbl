#lang zcribble/base

@; Check that a macro-introduced `include-section' works:
@(define-syntax-rule (inc) (include-section "diamond.scrbl"))

@(inc)
