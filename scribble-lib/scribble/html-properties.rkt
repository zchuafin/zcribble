#lang racket/base
(require "private/provide-structs.rkt"
         "html-properties-nc.rkt"
         racket/contract/base
         xml/xexpr
         net/url-structs)

(module deserialize-info racket/base
  (require (submod "html-properties-nc.rkt" deserialize-info))
  (provide (all-from-out (submod "html-properties-nc.rkt" deserialize-info))))

(provide
 (contract-out
  [struct body-id ([value string?])]
  [struct document-source ([module-path module-path?])]
  
  [struct xexpr-property ([before xexpr/c] [after xexpr/c])]
  [struct hover-property ([text string?])]
  [struct script-property ([type string?]
                    [script (or/c path-string? (listof string?))])]
  [struct css-addition ([path (or/c path-string? (cons/c 'collects (listof bytes?)) url? bytes?)])]
  [struct js-addition ([path (or/c path-string? (cons/c 'collects (listof bytes?)) url? bytes?)])]
  [struct html-defaults ([prefix-path (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
                  [style-path (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
                  [extra-files (listof (or/c path-string? (cons/c 'collects (listof bytes?))))])]
  [struct css-style-addition ([path (or/c path-string? (cons/c 'collects (listof bytes?)) url? bytes?)])]
  [struct js-style-addition ([path (or/c path-string? (cons/c 'collects (listof bytes?)) url? bytes?)])]

  [struct url-anchor ([name string?])]
  [struct alt-tag ([name (and/c string? #rx"^[a-zA-Z0-9]+$")])]
  [struct attributes ([assoc (listof (cons/c symbol? string?))])]
  [struct column-attributes ([assoc (listof (cons/c symbol? string?))])]

  [struct part-link-redirect ([url url?])]
  [struct part-title-and-content-wrapper ([tag string?]
                                   [attribs (listof (list/c symbol? string?))])]
  [struct install-resource ([path path-string?])]
  [struct link-resource ([path path-string?])]

  [struct head-extra ([xexpr xexpr/c])]
  [struct head-addition ([xexpr xexpr/c])]
  [struct render-convertible-as ([types (listof (or/c 'png-bytes 'svg-bytes 'gif-bytes))])]))
 