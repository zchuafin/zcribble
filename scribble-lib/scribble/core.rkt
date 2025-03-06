#lang racket/base
(require "private/provide-structs.rkt"
         "core-nc.rkt"
         racket/serialize
         racket/contract/base
         file/convertible)

(provide (struct-out collect-info)
         (struct-out resolve-info))

;; ----------------------------------------
;(provide deserialize-info:style-v0 deserialize-info:element-v0)

(provide
 (contract-out
  (tag?
   [-> any/c
       boolean?])
  (block?
   [-> any/c
       boolean?])
  (content?
   [-> any/c
       boolean?])
  (element-style?
   [-> any/c
       boolean?])))

;; ----------------------------------------

(provide
 (contract-out
  (deserialize-link-render-style
   any/c)))

(provide
 (contract-out
  [current-link-render-style (parameter/c link-render-style?)]))

(provide
 (contract-out
  (struct link-render-style ([mode (or/c 'default 'number)]))))

;; ----------------------------------------

(provide
 (contract-out
  (deserialize-numberer
   any/c)))

(provide
 (contract-out
  [make-numberer ((any/c (listof part-number-item?)
                         . -> . (values part-number-item? any/c))
                  any/c
                  . -> . numberer?)]
  [numberer-step (numberer?
                  (listof part-number-item?)
                  collect-info?
                  hash?
                  . -> . (values part-number-item? hash?))]
  [part-number-item?
   (-> any/c
       boolean?)]
  [numberer?
   (-> any/c
       boolean?)]))

;; ----------------------------------------

(define (same-lengths? ls)
  (or (null? ls)
      (let ([l1 (length (car ls))])
        (andmap (λ (l) (= l1 (length l)))
                (cdr ls)))))

(define (string-without-newline? s)
  (and (string? s)
       (not (regexp-match? #rx"\n" s))))

(provide
 table
 (contract-out
  (make-table
   (-> style? (listof (listof (or/c block? 'cont)))
       table?))
  (table-style
   (-> table? style?))
  (table-blockss
   (-> table? (listof (listof (or/c block? 'cont)))))
  (table?
   (-> any/c boolean?))))

(provide
 paragraph
 (contract-out
  (make-paragraph
   (-> style? content? paragraph?))
  (paragraph-style
   (-> paragraph? style?))
  (paragraph-content
   (-> paragraph? content?))
  (paragraph?
   (-> any/c boolean?))))
  
(provide
 (contract-out
  [struct part ([tag-prefix (or/c #f string?)]
                [tags (listof tag?)]
                [title-content (or/c #f content?)]
                [style style?]
                [to-collect list?]
                [blocks (listof block?)]
                [parts (listof part?)])]
  [struct delayed-block ([resolve (any/c part? resolve-info? . -> . block?)])]
  [struct itemization ([style style?]
                       [blockss (listof (listof block?))])]
  [struct nested-flow ([style style?]
                       [blocks (listof block?)])]
  [struct compound-paragraph ([style style?]
                              [blocks (listof block?)])]
  [struct target-element ([style element-style?]
                          [content content?]
                          [tag tag?])]
  [struct toc-target-element ([style element-style?]
                              [content content?]
                              [tag tag?])]
  [struct toc-target2-element ([style element-style?]
                               [content content?]
                               [tag tag?]
                               [toc-content content?])]
  [struct page-target-element ([style element-style?]
                               [content content?]
                               [tag tag?])]
  [struct redirect-target-element ([style element-style?]
                                   [content content?]
                                   [tag tag?]
                                   [alt-path path-string?]
                                   [alt-anchor string?])]
  [struct link-element ([style element-style?]
                        [content content?]
                        [tag tag?])]
  [struct index-element ([style element-style?]
                         [content content?]
                         [tag tag?]
                         [plain-seq (and/c pair? (listof string-without-newline?))]
                         [entry-seq (listof content?)]
                         [desc any/c])]
  [struct image-element ([style element-style?]
                         [content content?]
                         [path (or/c path-string?
                                     (cons/c (one-of/c 'collects)
                                             (listof bytes?)))]
                         [suffixes (listof #rx"^[.]")]
                         [scale real?])]
  [struct multiarg-element ([style element-style?]
                            [contents (listof content?)])]
  [struct style ([name (or/c string? symbol? #f)]
                 [properties list?])]
  [struct document-version ([text (or/c string? #f)])]
  [struct document-date ([text (or/c string? #f)])]
  [struct target-url ([addr path-string?])]
  [struct color-property ([color (or/c string? (list/c byte? byte? byte?))])]
  [struct background-color-property ([color (or/c string? (list/c byte? byte? byte?))])]
  [struct numberer-property ([numberer numberer?] [argument any/c])]
  [struct table-columns ([styles (listof style?)])]
  [struct table-cells ([styless (listof (listof style?))])]
  [struct box-mode ([top-name string?]
                    [center-name string?]
                    [bottom-name string?])]
  [struct collected-info ([number (listof part-number-item?)]
                          [parent (or/c #f part?)]
                          [info any/c])]
  [struct known-doc ([v any/c]
                     [id string?])]))

(provide
 element
 (contract-out
  (make-element
   (-> element-style? content?
       element?))
  (element-style
   (-> element?
       element-style?))
  (element-content
   (-> element?
       content?))
  (element?
   (-> any/c boolean?))))

(provide
 (contract-out
  (plain
   style?)))

(provide/contract
 [box-mode* (string? . -> . box-mode?)])

;; ----------------------------------------

(provide
 toc-element
 (contract-out
  (make-toc-element
   (-> element-style? content? content?
       toc-element?))
  (toc-element-toc-content
   (-> toc-element? content?))
  (toc-element?
   (-> any/c boolean?))))

(provide
 (contract-out
  (deserialize-traverse-block
   any/c)))
(define deserialize-traverse-block
  (make-deserialize-info values values))

(provide/contract
 [traverse-block-block (traverse-block?
                        (or/c resolve-info? collect-info?)
                        . -> . block?)])

(provide
 traverse-element
 (contract-out
  (make-traverse-element
   (-> element-traverse-procedure/c
       traverse-element?))
  (traverse-element-traverse
   (-> traverse-element? element-traverse-procedure/c))
  (traverse-element?
   (-> any/c boolean?))))

(provide
 (contract-out
  (struct traverse-block
    ([traverse block-traverse-procedure/c]))))

(define block-traverse-procedure/c
  (recursive-contract
   ((symbol? any/c . -> . any/c)
    (symbol? any/c . -> . any)
    . -> . (or/c block-traverse-procedure/c
                 block?))))

(provide
 (contract-out
  (traverse-element-content
   (-> traverse-element? (or/c resolve-info? collect-info?)
       content?))))

(provide
 (contract-out
  (deserialize-traverse-element
   any/c)))

(provide
 (contract-out
  [element-traverse-procedure/c
   contract?]))

;; ----------------------------------------

(provide/contract
 (struct delayed-element ([resolve (any/c part? resolve-info? . -> . content?)]
                          [sizer (-> any)]
                          [plain (-> any)])))

(provide
 (contract-out
  (add-current-tag-prefix
   (-> pair? pair?))
  (current-tag-prefixes
   (parameter/c (listof string?)))
  (generate-tag
   (-> pair? collect-info? pair?))
  (strip-aux
   (-> content? content?))))

(provide
 (contract-out
  (delayed-element-content
   [-> delayed-element? resolve-info? content?])))

(provide
 (contract-out
  (delayed-block-blocks
   [-> any/c resolve-info? block?])))

(provide
 (contract-out
  (current-serialize-resolve-info
   (parameter/c (or/c #f resolve-info?)))))

;; ----------------------------------------

;; part-relative element has special serialization support:

(provide/contract
 (struct part-relative-element ([collect (collect-info? . -> . content?)]
                                [sizer (-> any)]
                                [plain (-> any)])))

(module deserialize-info racket/base
  (require (submod "core-nc.rkt" deserialize-info))
  (provide (all-from-out (submod "core-nc.rkt" deserialize-info)))
  #|
  (provide deserialize-delayed-element)
  (provide deserialize-delayed-index-desc)
  (provide deserialize-collect-element)
  (provide deserialize-render-element)
  (provide deserialize-generated-tag)
  (provide deserialize-part-relative-element)
  |#)

(provide
 (contract-out
  (part-relative-element-content
   (-> part-relative-element? resolve-info?
       content?))))

;; ----------------------------------------

(provide/contract
 (struct delayed-index-desc ([resolve (any/c part? resolve-info? . -> . any)])))

;; ----------------------------------------

(provide/contract
 [struct collect-element ([style element-style?]
                          [content content?]
                          [collect (collect-info? . -> . any)])])

;; ----------------------------------------

(provide/contract
 [struct render-element ([style element-style?]
                         [content content?]
                         [render (any/c part? resolve-info? . -> . any)])])

;; ----------------------------------------

(provide
 (contract-out
  (struct generated-tag
    ())
  (tag-key
   (-> tag? resolve-info?
       tag?))
  ))

;; ----------------------------------------

(provide
 (contract-out
  (content->string
   (case-> (-> content? string?)
           (-> content? any/c part? resolve-info? string?)))))

;; ----------------------------------------

(provide
 (contract-out
  (block-width
   (-> block? exact-nonnegative-integer?))
  (content-width
   (-> content? exact-nonnegative-integer?))))

;; ----------------------------------------

(provide info-key?)
(provide/contract
 [part-collected-info (part? resolve-info? . -> . collected-info?)]
 [collect-put! (collect-info? info-key?  any/c . -> . any)]
 [resolve-get ((or/c part? #f) resolve-info? info-key? . -> . any)]
 [resolve-get/tentative ((or/c part? #f) resolve-info? info-key? . -> . any)]
 [resolve-get/ext? ((or/c part? #f) resolve-info? info-key? . -> . any)]
 [resolve-get/ext-id ((or/c part? #f) resolve-info? info-key? . -> . any)]
 [resolve-search (any/c (or/c part? #f) resolve-info? info-key? . -> . any)]
 [resolve-get-keys ((or/c part? #f) resolve-info? (info-key? . -> . any/c) . -> . any/c)])
