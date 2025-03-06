#lang racket/base
(require "core.rkt"
         "private/provide-structs.rkt"
         "decode-struct.rkt"
         "decode-nc.rkt"
         racket/contract/base
         racket/contract/combinator
         racket/list)

(provide
 (contract-out
  [struct title-decl ([tag-prefix (or/c #f string?)]
                      [tags (listof tag?)]
                      [version (or/c string? #f)]
                      [style style?]
                      [content content?])]
  [struct part-start ([depth integer?]
                      [tag-prefix (or/c #f string?)]
                      [tags (listof tag?)]
                      [style style?]
                      [title content?])]
  [struct splice ([run list?])]
  [struct part-index-decl ([plain-seq (listof string?)]
                           [entry-seq list?])]
  [struct part-collect-decl ([element (or/c element? part-relative-element?)])]
  [struct part-tag-decl ([tag tag?])]))

(provide
 (contract-out
  (whitespace?
   (-> any/c boolean?))
  (pre-content?
   (-> any/c boolean?))
  (pre-flow?
    (-> any/c boolean?))
  (pre-part?
   (-> any/c boolean?))))

 (provide/contract
 [decode (-> (listof pre-part?)
             part?)]
 [decode-part  (-> (listof pre-part?)
                   (listof string?)
                   (or/c #f content?)
                   exact-nonnegative-integer?
                   part?)]
 [decode-flow  (-> (listof pre-flow?)
                   (listof block?))]
 [decode-paragraph (-> (listof pre-content?)
                       paragraph?)]
 [decode-compound-paragraph (-> (listof pre-flow?)
                                block?)]
 [decode-content (-> (listof pre-content?)
                     content?)]
 [rename decode-content decode-elements
         (-> (listof pre-content?)
             content?)]
 [decode-string (-> string? content?)]
 [clean-up-index-string (-> string? string?)])

(provide/contract
 [spliceof (flat-contract? . -> . flat-contract?)])


