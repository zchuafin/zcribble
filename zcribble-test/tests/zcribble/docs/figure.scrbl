#lang zcribble/base
@(require zcriblib/figure)

@title{Waterfowl}

@figure[
"one"
"The Figure"
@para{Duck}]

@figure[
#:continue? #t
"two"
"More of The Figure"
@para{Duck}]

@figure[
"three"
"A Different Figure"
@para{Goose!}]
