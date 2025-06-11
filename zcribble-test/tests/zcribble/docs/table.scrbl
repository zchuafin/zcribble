#lang zcribble/manual

@(tabular #:column-properties (list 'left 'center 'right)
          #:sep "-"
          (list (list "A" "B" "C" "D")
                (list "apple" "banana" "coconut" "donut")))


@(tabular #:cell-properties (list (list 'right 'center 'left)
                                  (list))
          #:sep "-"
          (list (list "A" "B" "C" "D")
                (list "apple" "banana" "coconut" "donut")
                (list "a" "b" "c" "d")))

@(tabular #:column-properties (list '() '() 'left)
          #:cell-properties (list (list 'right 'center '()))
          #:sep "-"
          (list (list "A" "B" "C" "D")
                (list "apple" "banana" "coconut" "donut")))

@(tabular #:sep "-"
          (list (list "A" 'cont "C" 'cont 'cont)
                (list "apple" "banana" "coconut" "donut" "eclair")))
