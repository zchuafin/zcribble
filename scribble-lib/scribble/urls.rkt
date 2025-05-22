#lang racket/base
(require "urls-nc.rkt"
         racket/contract)

(provide (contract-out
          (url:drracket
           string?)
          (url:download-drracket
           string?)
          (url:planet
           string?))
         (rename-out [url:drracket url:drscheme]
                     [url:download-drracket url:download-drscheme]))