#lang racket/base
(require
  "tag-nc.rkt"
  racket/contract/base
  syntax/modcollapse
  setup/collects
  scribble/core
  racket/match
  ;; Needed to normalize planet version numbers:
  (only-in planet/resolver get-planet-module-path/pkg)
  (only-in planet/private/data pkg-maj pkg-min))

(provide
 (contract-out
  [make-section-tag ((string?) 
                     (#:doc (or/c #f module-path?)
                      #:tag-prefixes (or/c #f (listof string?)))
                     . ->* .
                     tag?)]
  [make-module-language-tag (-> symbol? tag?)]
  [taglet? (any/c . -> . boolean?)]
  [module-path-prefix->string (module-path? . -> . string?)]
  [module-path-index->taglet (module-path-index? . -> . taglet?)]
  [intern-taglet (any/c . -> . any/c)]
  [doc-prefix (case->
               ((or/c #f module-path?) taglet? . -> . taglet?)
               ((or/c #f module-path?) (or/c #f (listof string?)) taglet? . -> . taglet?))]
  [definition-tag->class/interface-tag (-> definition-tag? class/interface-tag?)]
  [class/interface-tag->constructor-tag (-> class/interface-tag? constructor-tag?)]
  [get-class/interface-and-method (-> method-tag? (values symbol? symbol?))]
  [definition-tag? (-> any/c boolean?)]
  [class/interface-tag? (-> any/c boolean?)]
  [method-tag? (-> any/c boolean?)]
  [constructor-tag? (-> any/c boolean?)]))
