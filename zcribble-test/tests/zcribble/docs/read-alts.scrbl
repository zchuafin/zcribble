#lang zcribble/manual
@(require zcribble/manual)
@; test that various alternatives in reader syntax get
@; turned into the right things when rendered
@racketblock[#t
             #true
             #f
             #false
             (a . < . b)
             (< a b)
             "abcdef"
             ([{}])]

