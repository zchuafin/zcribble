#lang zcribble/base
@(require zcribble/decode)

@(define sub-table (tabular #:row-properties (list null '(border))
                            '(("B" "B2") ("T" cont))))

@tabular[#:column-properties (list null '(border) '(bottom-border right-border))
  (list (list "Apple" sub-table "Cat") (list "C" "D" "Elephant"))
]
