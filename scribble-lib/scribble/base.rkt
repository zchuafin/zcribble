#lang racket/base

(require "decode.rkt"
         "base-nc.rkt"
         "core.rkt"
         "manual-struct.rkt"
         "decode-struct.rkt"
         "html-properties.rkt"
         "tag.rkt"
         "private/tag.rkt"
         racket/list
         racket/class
         racket/contract/base
         racket/contract/combinator
         (for-syntax racket/base))

(provide (all-from-out "tag.rkt"))

;; ----------------------------------------

(define-syntax-rule (title-like-contract)
  (->* ()
       (#:tag (or/c #f string? (listof string?))
              #:tag-prefix (or/c #f string? module-path?)
              #:style (or/c style? string? symbol? (listof symbol?) #f))
       #:rest (listof pre-content?)
       part-start?))

(provide/contract
 [title (->* ()
             (#:tag (or/c #f string? (listof string?))
                    #:tag-prefix (or/c #f string? module-path?)
                    #:style (or/c style? string? symbol? (listof symbol?) #f)
                    #:version (or/c string? #f)
                    #:date (or/c string? #f))
             #:rest (listof pre-content?)
             title-decl?)]
 [section (title-like-contract)]
 [subsection (title-like-contract)]
 [subsubsection (title-like-contract)]
 [subsubsub*section  (->* ()
                          (#:tag (or/c #f string? (listof string?)))
                          #:rest (listof pre-content?)
                          block?)])
(provide include-section)

;; ----------------------------------------

(provide/contract 
 [author (->* (content?) () #:rest (listof content?) block?)]
 [author+email (->* (content? string?) (#:obfuscate? any/c) element?)])

;; ----------------------------------------

(provide items/c)

(provide/contract 
 [itemlist (->* () 
                (#:style (or/c style? string? symbol? #f)) 
                #:rest (listof items/c)
                itemization?)]
 [item (->* () 
            () 
            #:rest (listof pre-flow?)
            item?)])
(provide/contract
 [item? (any/c . -> . boolean?)])


;; ----------------------------------------

(provide ._ .__ ~ ?- -~-)

;; ----------------------------------------

(provide/contract
 [linebreak (-> element?)]
 [nonbreaking elem-like-contract]
 [hspace (-> exact-nonnegative-integer? element?)]
 [elem (->* ()
            (#:style element-style?)
            #:rest (listof pre-content?)
            element?)]
 [italic elem-like-contract]
 [bold elem-like-contract]
 [smaller elem-like-contract]
 [larger elem-like-contract]
 [emph elem-like-contract]
 [tt elem-like-contract]
 [subscript elem-like-contract]
 [superscript elem-like-contract]

 [literal (->* (string?) () #:rest (listof string?) element?)]

 [image (->* ((or/c path-string? (cons/c 'collects (listof bytes?))))
             (#:scale real?
                      #:suffixes (listof (and/c string? #rx"^[.]"))
                      #:style element-style?)
             #:rest (listof content?)
             image-element?)])

;; ----------------------------------------

(provide/contract
 [para (->* ()
            (#:style (or/c style? string? symbol? #f ))
            #:rest (listof pre-content?)
            paragraph?)]
 [nested (->* ()
              (#:style (or/c style? string? symbol? #f ))
              #:rest (listof pre-flow?)
              nested-flow?)]
 [compound (->* ()
                (#:style (or/c style? string? symbol? #f ))
                #:rest (listof pre-flow?)
                compound-paragraph?)]
 [tabular (->* ((listof (listof (or/c 'cont block? content?))))
               (#:style (or/c style? string? symbol? #f)
                #:sep (or/c content? block? #f)
                #:column-properties (listof any/c)
                #:row-properties (listof any/c)
                #:cell-properties (listof (listof any/c))
                #:sep-properties (or/c list? #f))
               table?)])


;; ----------------------------------------

(provide
 (contract-out
  [elemtag (->* ((or/c taglet? generated-tag?))
                ()
                #:rest (listof pre-content?)
                element?)]
  [elemref (->* ((or/c taglet? generated-tag?))
                (#:underline? any/c)
                #:rest (listof pre-content?)
                element?)]
  [secref (->* (string?)
               (#:doc (or/c #f module-path?)
                #:tag-prefixes (or/c #f (listof string?))
                #:underline? any/c
                #:link-render-style (or/c #f link-render-style?))
               element?)]
  [Secref (->* (string?)
               (#:doc (or/c #f module-path?)
                #:tag-prefixes (or/c #f (listof string?))
                #:underline? any/c
                #:link-render-style (or/c #f link-render-style?))
               element?)]
  [seclink (->* (string?)
                (#:doc (or/c #f module-path?)
                 #:tag-prefixes (or/c #f (listof string?))
                 #:underline? any/c
                 #:indirect? any/c)
                #:rest (listof pre-content?)
                element?)]
  [other-doc (->* (module-path?)
                  (#:underline? any/c
                   #:indirect (or/c #f content?))
                  element?)]))
;; ----------------------------------------

(provide/contract
 [hyperlink (->* ((or/c string? path?))
                 (#:underline? any/c
                               #:style element-style?)
                 #:rest (listof pre-content?)
                 element?)]
 [url (-> string? element?)]
 [margin-note (->* () (#:left? any/c) #:rest (listof pre-flow?) block?)]
 [margin-note* (->* () (#:left? any/c) #:rest (listof pre-content?) element?)]
 [centered (->* () () #:rest (listof pre-flow?) block?)]
 [verbatim (->* (content?) (#:indent exact-nonnegative-integer?) #:rest (listof content?) block?)])


;; ----------------------------------------

; XXX unknown contract
(provide get-index-entries)
(provide/contract
 [index-block (-> delayed-block?)]
 [index (((or/c string? (listof string?))) ()  #:rest (listof pre-content?) . ->* . index-element?)]
 [index* (((listof string?) (listof any/c)) ()  #:rest (listof pre-content?) . ->* . index-element?)] ; XXX first any/c wrong in docs 
 [as-index (() () #:rest (listof pre-content?) . ->* . index-element?)]
 [section-index (() () #:rest (listof string?) . ->* . part-index-decl?)]
 [index-section (() (#:tag (or/c #f string?)) . ->* . part?)])

;; ----------------------------------------

(provide/contract
 [table-of-contents (-> delayed-block?)]
 [local-table-of-contents (() 
                           (#:style (or/c style? string? symbol? (listof symbol?) #f))
                           . ->* . delayed-block?)])