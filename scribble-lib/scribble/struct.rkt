#lang racket/base
(require
  "struct-nc.rkt"
  (only-in "core-nc.rkt" tag-key part-number-item? element-style? content? style? nested-flow?)
  racket/provide-syntax
  racket/struct-info
  racket/contract/base
  (for-syntax racket/base))

(provide
 (contract-out
  (struct collect-info
    ((fp any/c) (ht any/c) (ext-ht any/c) (ext-demand (tag? collect-info? . -> . any/c)) (parts any/c)
                (tags any/c) (gen-prefix any/c) (relatives any/c) (parents (listof part?))))
  [tag? (-> any/c boolean?)]
  [block? (-> any/c boolean?)]
  [make-flow (-> any/c boolean?)]
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
  (struct table
    ((style style?) (blockss (listof (listof (or/c block? 'cont))))))
  (table-flowss
   (-> table? (listof (listof (or/c (listof block?) (one-of/c 'cont))))))
  (make-auxiliary-table
   (-> any/c (listof (listof (or/c (listof block?) (one-of/c 'cont)))) table?))
  (auxiliary-table?
   (-> any/c boolean?))

  (struct delayed-block
    ((resolve (any/c part? resolve-info? . -> . block?))))
  
  (struct itemization
    ((style style?) (blockss (listof (listof block?)))))
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

  (make-part-relative-element
   (-> (collect-info? . -> . content?) (-> any/c) (-> any/c)
       part-relative-element?))

  (struct paragraph
    ((style style?) (content content?)))

  

  (struct resolve-info
    ((ci any/c) (delays any/c) (undef any/c) (searches any/c)))

  (make-styled-paragraph
   (-> list? any/c
       paragraph?))

  (struct target-url
    ((addr path-string?) (style any/c)))

  (make-target-url
   (-> path-string? any/c
       target-url?))

  (make-unnumbered-part
   (-> (or/c false/c string?) (listof tag?) (or/c false/c list?) any/c list? (listof block?) (listof part?)
       unnumbered-part?))

  (struct with-attributes
    ((style any/c) (assoc (listof (cons/c symbol? string?)))))

  (make-with-attributes
   (-> any/c (listof (cons/c symbol? string?))
       with-attributes?))
  
  (struct part
    ((tag-prefix (or/c #f string?))
     (tags (listof tag?))
     (title-content (or/c #f list?))
     (style style?)
     (to-collect list?)
     (blocks (listof block?))
     (parts (listof part?))))
  
  (content->string
   (case-> [-> content?
               string?]
           [-> content?
               any/c
               part?
               resolve-info?
               string?]))
  
  (struct compound-paragraph
    ((style style?) (blocks (listof block?))))

  (struct element
    ((style element-style?) (content content?)))

  (struct image-file
    ((path (or/c path-string?
                 (cons/c 'collects (listof bytes?))))
     (scale real?)))
  (make-image-file
   (-> (or/c path-string?
             (cons/c 'collects (listof bytes?)))
       real?
       image-file?))

  (struct toc-element
    ((style element-style?) (content content?) (toc-content content?)))
  (struct target-element
    ((style element-style?) (content content?) (tag tag?)))
  (struct toc-target-element
    ((style element-style?) (content content?) (tag tag?)))
  (struct toc-target2-element
    ((style element-style?) (content content?) (tag tag?) (toc-content content?)))
  (struct page-target-element
    ((style element-style?) (content content?) (tag tag?)))
  (struct redirect-target-element
    ((style element-style?) (content content?) (tag tag?) (alt-path path-string?) (alt-anchor string?)))
  (struct link-element
    ((style element-style?) (content content?) (tag tag?)))
  (struct index-element
    ((style element-style?) (content content?) (tag tag?) (plain-seq (and/c pair? (listof string?)))
                            (entry-seq (listof content?))
                            (desc any/c)))
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
  (struct collected-info
    [(number (listof part-number-item?)) (parent (or/c #f part?)) (info any/c)])

  (struct delayed-element
    ((resolve (any/c part? resolve-info? . -> . content?))
     (sizer (-> any/c))
     (plain (-> any/c))))
  
  (make-delayed-element
   (-> (any/c part? resolve-info? . -> . content?) (-> any/c) (-> any/c)
       delayed-element?))
         
  (struct part-relative-element
    ((collect (collect-info? . -> . content?)) (sizer (-> any/c)) (plain (-> any/c))))

  (struct delayed-index-desc
    ((resolve (collect-info? . -> . content?))))
  (make-delayed-index-desc
   (-> (collect-info? . -> . content?)
       delayed-index-desc?))

  (struct collect-element
    ((style element-style?) (content content?) (collect (collect-info? . -> . any/c))))

  (struct render-element
    ((style element-style?) (content content?) (render (any/c part? resolve-info? . -> . any))))

  (struct generated-tag
    ())

  (tag-key
   [-> tag? resolve-info?
       tag?])

  (element->string
   [-> content?
       string?])
  
  (element-width
   [-> content?
       exact-nonnegative-integer?])

  (block-width
   [-> block?
       exact-nonnegative-integer?])

  (info-key?
   [-> any/c
       boolean?])

  (part-collected-info
   [-> part? resolve-info?
       collected-info?])

  (collect-put!
   [-> collect-info? info-key? any/c
       void?])
  
  (resolve-get
   [-> (or/c part? #f) resolve-info? info-key?
       any/c])

  (resolve-get/tentative
   [-> (or/c part? #f) resolve-info? info-key?
       any/c])

  (resolve-get/ext?
   [-> (or/c part? #f) resolve-info? info-key?
       (or/c any/c boolean?)])

  (resolve-search
   [-> any/c (or/c part? #f) resolve-info? info-key?
       void?])

  (resolve-get-keys
   [-> (or/c part? #f) resolve-info? (info-key? . -> . any/c)
       list?])))
