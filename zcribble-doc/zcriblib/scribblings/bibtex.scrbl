#lang zcribble/manual
@(require (for-label zcribble/struct
                     zcriblib/bibtex
                     zcriblib/autobib
                     racket/base
                     racket/contract))

@title[#:tag "bibtex"]{BibTeX Bibliographies}

@defmodule[zcriblib/bibtex]

@defform[(define-bibtex-cite bib-pth ~cite-id citet-id generate-bibliography-id
           option ...)]{

Expands into:
@racketblock[
(begin
  (define-cite autobib-cite autobib-citet generate-bibliography-id
     option ...)
  (define-bibtex-cite* bib-pth
    autobib-cite autobib-citet
    ~cite-id citet-id))]
}

@defform[(define-bibtex-cite* bib-pth autobib-cite autobib-citet
                              ~cite-id citet-id)]{

Parses @racket[bib-pth] as a BibTeX database, and augments
@racket[autobib-cite] and @racket[autobib-citet] into
@racket[~cite-id] and @racket[citet-id] functions so that rather than
accepting @racket[bib?] structures, they accept citation key strings.
       
Each string is broken along spaces into citations keys that are looked up in the BibTeX database and turned into @racket[bib?] structures.

The only BibTeX entries that are supported are: @litchar{misc},
@litchar{book}, @litchar{article}, @litchar{inproceedings},
@litchar{webpage}, @litchar{mastersthesis}, and @litchar{techreport}.

}

@defstruct*[bibdb ([raw (hash/c string? (hash/c string? string?))]
                   [bibs (hash/c string? bib?)])]{
                                             Represents a BibTeX database. The @racket[_raw] hash table maps the labels in the file to hash tables of the attributes and their values. The @racket[_bibs] hash table maps the same labels to Scribble data-structures representing the same information.
                                             }

@defproc[(path->bibdb [path path-string?])
         bibdb?]{
                 Parses a path into a BibTeX database.
                 }

@defproc[(bibtex-parse [ip input-port?])
         bibdb?]{
                 Parses an input port into a BibTeX database.
                 }
