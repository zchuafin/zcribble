#lang racket/base
(require "private/provide-structs.rkt"
         "latex-properties-nc.rkt"
         racket/serialize
         racket/contract/base)

(module deserialize-info racket/base
  (require (submod "latex-properties-nc.rkt" deserialize-info))
  (provide (all-from-out (submod "latex-properties-nc.rkt" deserialize-info))))

(provide
 (contract-out
  [struct tex-addition ([path (or/c path-string? (cons/c 'collects (listof bytes?)) bytes?)])]
  [struct latex-defaults ([prefix (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
                          [style (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
                          [extra-files (listof (or/c path-string? (cons/c 'collects (listof bytes?))))])]
  [struct latex-defaults+replacements
    ([prefix (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
    [style (or/c bytes? path-string? (cons/c 'collects (listof bytes?)))]
    [extra-files (listof (or/c path-string? (cons/c 'collects (listof bytes?))))]
    [replacements (hash/c string? (or/c bytes? path-string? (cons/c 'collects (listof bytes?))))])]
  [struct command-extras ([arguments (listof string?)])]
  [struct command-optional ([arguments (listof string?)])]
  [struct short-title ([text (or/c string? #f)])]
  [struct table-row-skip ([amount string?])]))
