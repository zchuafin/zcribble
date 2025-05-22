#lang racket/base
(require
  (only-in "struct-nc.rkt" element flow? unnumbered-part? with-attributes? image-file? hover-element? script-element?
           make-flow flow-paragraphs part-flow make-versioned-part versioned-part? styled-paragraph? styled-paragraph-style
           make-omitable-paragraph omitable-paragraph? table-flowss make-auxiliary-table auxiliary-table? itemization-flows
           styled-itemization? styled-itemization-style make-styled-itemization make-blockquote 
           make-styled-paragraph target-url-style make-unnumbered-part make-with-attributes with-attributes-style
           with-attributes-assoc make-image-file image-file-path image-file-scale make-aux-element aux-element?
           make-hover-element hover-element-text make-script-element script-element-type script-element-script
           element->string element-width toc-element make-toc-target2-element make-itemization make-compound-paragraph
           make-element make-part make-table make-paragraph make-page-target-element make-index-element)
  (except-in "core.rkt" make-index-element make-toc-target2-element make-page-target-element make-itemization make-compound-paragraph make-element make-part make-table make-paragraph)
  ;(only-in "core-nc.rkt" tag-key part-number-item? element-style? content? style? nested-flow?)
  racket/provide-syntax
  racket/struct-info
  racket/contract/base
  (for-syntax racket/base))

(provide
 table
 paragraph
 tag-key
 resolve-get/tentative
 resolve-get/ext?
 resolve-get
 part-collected-info
 make-delayed-element
 paragraph-style
 make-render-element
 resolve-get-keys
 element?
 paragraph?
 collect-info
 resolve-info
 tag?
 block?
 table?
 delayed-block
 delayed-element
 itemization
 target-element
 make-target-element
 table-blockss
 make-delayed-block
 part-relative-element
 make-link-element
 make-collect-element
 toc-target-element
 toc-target2-element
 make-toc-target2-element
 make-index-element
 page-target-element
 redirect-target-element
 link-element
 index-element
 collected-info
 collect-element
 render-element
 generated-tag
 content->string
 resolve-search
 info-key?
 collect-put!
 element
 make-page-target-element
 (contract-out
  [make-flow (-> any/c any/c)]
  [flow? (-> any/c boolean?)]

  ;; this is the identity function and looks to be there for backwards compatibility; this contract is a guess
  [flow-paragraphs (-> flow? flow?)]
  
  (part-flow
   (-> part? (listof block?)))
  [make-versioned-part
   (-> (or/c #f string?) (listof tag?) (or/c #f list?) any/c list? (listof block?) (listof part?) string?
       part?)]
  [versioned-part?
   (-> any/c boolean?)]
  #;[make-unnumbered-part
   (-> tag-prefix tags title-content style to-collect blocks parts
       part?)]
  [unnumbered-part?
   (-> any/c boolean?)]
  #;[make-styled-paragraph
   (-> content style
       paragraph?)]
  (styled-paragraph?
   (-> any/c boolean?))
  (styled-paragraph-style
   (-> paragraph? any/c))
  (make-omitable-paragraph
   (-> content? paragraph?))
  (omitable-paragraph?
   (-> any/c boolean?))

  (make-table
   (-> any/c (listof (listof (or/c (listof block?) (one-of/c 'cont))))
       table?))

  (make-itemization
   (-> (listof (listof block?))
       itemization?))

  (make-element
   (-> any/c any/c
       element?))

  (make-compound-paragraph
   (-> any/c (listof block?)
       compound-paragraph?))

  (make-part
   (-> (or/c false/c string?) (listof tag?) (or/c false/c list?)
       any/c list? (listof block?) (listof part?)
       part?))
  
  (table-flowss
   (-> table? (listof (listof (or/c (listof block?) (one-of/c 'cont))))))
  (make-auxiliary-table
   (-> any/c (listof (listof (or/c (listof block?) (one-of/c 'cont)))) table?))
  (auxiliary-table?
   (-> any/c boolean?))
  (itemization-flows
   (-> itemization?
       (listof (listof block?))))
  (styled-itemization?
   (-> itemization?
       boolean?))
  (styled-itemization-style
   (-> itemization?
       style?))
  (make-styled-itemization
   (-> any/c (listof (listof block?))
       itemization?))
  (make-blockquote
   (-> any/c (listof block?)
       nested-flow?))

  (make-toc-element
   (-> any/c list? list? toc-element?))
  
  (make-part-relative-element
   (-> (collect-info? . -> . content?) (-> any/c) (-> any/c)
       part-relative-element?))

  (make-paragraph
   (-> list? paragraph?))
  
  (paragraph-content
   (-> any/c content?))

  (make-styled-paragraph
   (-> list? any/c
       paragraph?))

  (make-target-url
   (-> path-string? 
       target-url?))
  (target-url-addr
   (-> target-url? path-string?))
  (target-url-style
   (-> target-url? any/c))
  (target-url?
   (-> any/c boolean?))

  (make-unnumbered-part
   (-> (or/c false/c string?) (listof tag?) (or/c false/c list?) any/c list? (listof block?) (listof part?)
       unnumbered-part?))

  (make-with-attributes
   (-> any/c (listof (cons/c symbol? string?))
       with-attributes?))
  (with-attributes-style
      (-> with-attributes? any/c))
  (with-attributes-assoc
      (-> with-attributes? (listof (cons/c symbol? string?))))
  (with-attributes?
      (-> any/c boolean?))
  
  (make-image-file
   (-> (or/c path-string?
             (cons/c 'collects (listof bytes?)))
       real?
       image-file?))
  (image-file-path
   (-> image-file? 	
       (or/c path-string?
             (cons/c 'collects (listof bytes?)))))
  (image-file-scale
   (-> image-file? real?))
  (make-aux-element
   [-> any/c list?
       element?])
  (aux-element?
   [-> any/c
       boolean?])
  (make-hover-element
   [-> any/c list? string?
       element?])
  (hover-element?
   [-> any/c
       boolean?])
   (hover-element-text
    [-> hover-element?
        string?])
  (make-script-element
   [-> any/c list? string? (or/c path-string? (listof string?))
       element?])
  (script-element?
   [-> any/c
       boolean?])
  (script-element-type
   [-> script-element?
       string?])
  (script-element-script
   [-> script-element?
       (or/c path-string? (listof string?))])

  
  (make-delayed-index-desc
   (-> (collect-info? . -> . content?)
       delayed-index-desc?))

  (element->string
   [case-> (-> content?
               string?)
           (-> content?
               any/c
               part?
               resolve-info?
               string?)])
  
  (element-width
   [-> content?
       exact-nonnegative-integer?])))
