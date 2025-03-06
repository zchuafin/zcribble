#lang racket/base
(require "private/provide-structs.rkt"
         racket/serialize
         racket/contract/base
         file/convertible)



;; ----------------------------------------

(define-struct collect-info (fp ht ext-ht ext-demand parts tags gen-prefix relatives parents) #:transparent)
(define-struct resolve-info (ci delays undef searches) #:transparent)

(define (part-collected-info part ri)
  (hash-ref (collect-info-parts (resolve-info-ci ri))
            part))

(define (collect-put! ci key val)
  (let ([ht (collect-info-ht ci)])
    (let ([old-val (hash-ref ht key #f)])
      (when old-val
        (eprintf "WARNING: collected information for key multiple times: ~e; values: ~e ~e\n"
                 key old-val val))
      (hash-set! ht key val))))

(define (resolve-get/where part ri key)
  (let ([key (tag-key key ri)])
    (let ([v (hash-ref (if part
                           (collected-info-info (part-collected-info part ri))
                           (collect-info-ht (resolve-info-ci ri)))
                       key
                       #f)])
      (cond
        [v (values v #f)]
        [part (resolve-get/where
               (collected-info-parent (part-collected-info part ri))
               ri key)]
        [else
         (define ci (resolve-info-ci ri))
         (define (try-ext)
           (hash-ref (collect-info-ext-ht ci) key #f))
         (define v
           (or (try-ext)
               (and ((collect-info-ext-demand ci) key ci)
                    (try-ext))))
         (if (known-doc? v)
             (values (known-doc-v v) (known-doc-id v))
             (values v #t))]))))

(define (resolve-get/ext? part ri key)
  (define-values (v ext-id) (resolve-get/ext-id* part ri key #f))
  (values v (and ext-id #t)))

(define (resolve-get/ext-id part ri key)
  (resolve-get/ext-id* part ri key #f))

(define (resolve-get/ext-id* part ri key search-key)
  (let-values ([(v ext-id) (resolve-get/where part ri key)])
    (when ext-id
      (hash-set! (resolve-info-undef ri) (tag-key key ri) 
                 (if v 'found search-key)))
    (values v ext-id)))

(define (resolve-get part ri key)
  (resolve-get* part ri key #f))

(define (resolve-get* part ri key search-key)
  (let-values ([(v ext-id) (resolve-get/ext-id* part ri key search-key)])
    v))

(define (resolve-get/tentative part ri key)
  (let-values ([(v ext-id) (resolve-get/where part ri key)])
    v))

(define (resolve-search search-key part ri key)
  (let ([s-ht (hash-ref (resolve-info-searches ri)
                        search-key
                        (lambda ()
                          (let ([s-ht (make-hash)])
                            (hash-set! (resolve-info-searches ri)
                                       search-key s-ht)
                            s-ht)))])
    (hash-set! s-ht key #t))
  (resolve-get* part ri key search-key))

(define (resolve-get-keys part ri key-pred)
  (for/list ([k (in-hash-keys (if part
                                  (collected-info-info (part-collected-info part ri))
                                  (let ([ci (resolve-info-ci ri)])
                                    ;; Force all xref info:
                                    ((collect-info-ext-demand ci) #f ci)
                                    (collect-info-ext-ht ci))))]
             #:when (key-pred k))
    k))

(provide (struct-out collect-info)
         (struct-out resolve-info))

;; ----------------------------------------

(provide tag?)
(define (tag? s)
  (and (pair? s)
       (symbol? (car s))
       (pair? (cdr s))
       (or (string? (cadr s))
           (generated-tag? (cadr s))
           (and (pair? (cadr s))
                (list? (cadr s))
                (serializable? (cadr s))))
       (null? (cddr s))))

(provide block?)
(define (block? p)
  (or (paragraph? p)
      (table? p)
      (itemization? p)
      (nested-flow? p)
      (compound-paragraph? p)
      (delayed-block? p)
      (traverse-block? p)))

(define content-symbols
  #hasheq([nbsp . #t]
          [mdash . #t]
          [ndash . #t]
          [ldquo . #t]
          [rdquo . #t]
          [rsquo . #t]
          [lsquo . #t]
          [prime . #t]
          [rarr . #t]
          [larr . #t]
          [alpha . #t]
          [infin . #t]
          [lang . #t]
          [rang . #t]))

(provide content?)
(define (content? v) 
  (or (string? v)
      (element? v)
      (and (list? v) (andmap content? v))
      (delayed-element? v)
      (traverse-element? v)
      (part-relative-element? v)
      (multiarg-element? v)
      (hash-ref content-symbols v #f)
      (convertible? v)))

(provide element-style?)
(define (element-style? s)
  (or (style? s) (not s) (string? s) (symbol? s)))

;; ----------------------------------------

(define-struct link-render-style (mode)
  #:constructor-name link-render-style
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (s)
     (vector (link-render-style-mode s)))
   #'deserialize-link-render-style
   #f
   (or (current-load-relative-directory) (current-directory))))

(provide deserialize-link-render-style)
(define deserialize-link-render-style
  (make-deserialize-info (lambda (s)
                           (link-render-style s))
                         (lambda (tag init-val)
                           (error "cannot allocate link-render-style for cycle"))))

(define current-link-render-style (make-parameter (link-render-style 'default)))

(provide
 link-render-style?
 link-render-style-mode
 link-render-style
 current-link-render-style)

;; ----------------------------------------

(define-struct numberer (tag step-proc initial-value)
  #:constructor-name numberer
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (vector (numberer-tag d)
             (numberer-initial-value d)))
   #'deserialize-numberer
   #f
   (or (current-load-relative-directory) (current-directory))))

(provide deserialize-numberer)
(define deserialize-numberer
  (make-deserialize-info (lambda (tag init-val)
                           (numberer tag #f))
                         (lambda (tag init-val)
                           (error "cannot allocate numberer for cycle"))))

(define (make-numberer spec-proc initial-value)
  (numberer (generated-tag) spec-proc initial-value))

(define (numberer-step n parent-numbers ci ht)
  (define tag (generate-tag `(numberer ,(numberer-tag n)) ci))
  (define-values (numberer-str new-val)
    (let ([step (numberer-step-proc n)])
      (step (hash-ref ht tag (lambda () (numberer-initial-value n)))
            parent-numbers)))
  (values numberer-str (hash-set ht tag new-val)))

(define part-number-item?
  (or/c #f exact-nonnegative-integer? string? (list/c string? string?)))

(provide
 part-number-item?
 numberer?
 make-numberer
 numberer-step)

;; ----------------------------------------
(provide
 (struct-out part)
 (struct-out paragraph)
 (struct-out table)
 (struct-out delayed-block)
 (struct-out itemization)
 (struct-out nested-flow)
 (struct-out compound-paragraph)
 (struct-out toc-element)
 (struct-out target-element)
 (struct-out toc-target-element)
 (struct-out toc-target2-element)
 (struct-out page-target-element)
 (struct-out redirect-target-element)
 (struct-out link-element)
 (struct-out index-element)
 (struct-out image-element)
 (struct-out multiarg-element)
 (struct-out style)
 (struct-out document-version)
 (struct-out document-date)
 (struct-out target-url)
 (struct-out color-property)
 (struct-out background-color-property)
 (struct-out numberer-property)
 (struct-out table-columns)
 (struct-out table-cells)
 (struct-out box-mode)
 (struct-out collected-info)
 (struct-out known-doc)
 (struct-out traverse-element)
 (struct-out traverse-block)
 (struct-out render-element)
 (struct-out element)
 make-element
 element-style
 element-content
 element?
 traverse-element-content)


(define-serializable-struct part (tag-prefix
                                  tags
                                  title-content
                                  style
                                  to-collect
                                  blocks
                                  parts))
(define-serializable-struct paragraph (style
                                       content))
(define-serializable-struct table (style
                                   blockss))
(define-serializable-struct delayed-block (resolve))
(define-serializable-struct itemization (style
                                         blockss))
(define-serializable-struct nested-flow (style
                                         blocks))
(define-serializable-struct compound-paragraph (style
                                                blocks))
(define-serializable-struct element (style
                                     content))
(define-serializable-struct (toc-element element) (toc-content))
(define-serializable-struct (target-element element) (tag))
(define-serializable-struct (toc-target-element target-element) ())
(define-serializable-struct (toc-target2-element toc-target-element) (toc-content))
(define-serializable-struct (page-target-element target-element) ())
(define-serializable-struct (redirect-target-element target-element) (alt-path
                                                                      alt-anchor))
(define-serializable-struct (link-element element) (tag))
(define-serializable-struct (index-element element) (tag
                                                     plain-seq
                                                     entry-seq
                                                     desc))
(define-serializable-struct (image-element element) (path
                                                     suffixes
                                                     scale))
(define-serializable-struct multiarg-element (style
                                              contents))
(define-serializable-struct style (name properties))
(define-serializable-struct document-version (text))
(define-serializable-struct document-date (text))
(define-serializable-struct target-url (addr))
(define-serializable-struct color-property (color))
(define-serializable-struct background-color-property (color))
(define-serializable-struct numberer-property (numberer
                                               argument))
(define-serializable-struct table-columns (styles))
(define-serializable-struct table-cells (styless))
(define-serializable-struct box-mode (top-name
                                      center-name
                                      bottom-name))
(define-serializable-struct collected-info (number
                                            parent
                                            info))
(define-serializable-struct known-doc (v
                                       id))


(provide plain)
(define plain (make-style #f null))

(define (box-mode* name)
  (box-mode name name name))
(provide
 box-mode*)

;; ----------------------------------------

;; Traverse block has special serialization support:
(define-struct traverse-block (traverse)
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-traverse-block
                "current-serialize-resolve-info not set"))
       (vector (traverse-block-block d ri))))
   #'deserialize-traverse-block
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(define block-traverse-procedure/c
  (recursive-contract
   ((symbol? any/c . -> . any/c)
    (symbol? any/c . -> . any)
    . -> . (or/c block-traverse-procedure/c
                 block?))))

(provide block-traverse-procedure/c)

(provide deserialize-traverse-block)
(define deserialize-traverse-block
  (make-deserialize-info values values))

(define (traverse-block-block b i)
  (cond
    [(collect-info? i)
     (let ([p (hash-ref (collect-info-fp i) b #f)])
       (if (block? p)
           p
           (error 'traverse-block-block
                  "no block computed for traverse-block: ~e"
                  b)))]
    [(resolve-info? i)
     (traverse-block-block b (resolve-info-ci i))]))

(provide
 traverse-block-block)

;; ----------------------------------------

;; Traverse element has special serialization support:
(define-struct traverse-element (traverse)
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-traverse-block
                "current-serialize-resolve-info not set"))
       (vector (traverse-element-content d ri))))
   #'deserialize-traverse-element
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(define element-traverse-procedure/c
  (recursive-contract
   ((symbol? any/c . -> . any/c)
    (symbol? any/c . -> . any)
    . -> . (or/c element-traverse-procedure/c
                 content?))))

(provide deserialize-traverse-element)
(define deserialize-traverse-element
  (make-deserialize-info values values))

(define (traverse-element-content e i)
  (cond
    [(collect-info? i)
     (let ([c (hash-ref (collect-info-fp i) e #f)])
       (if (content? c)
           c
           (error 'traverse-block-block
                  "no block computed for traverse-block: ~e"
                  e)))]
    [(resolve-info? i)
     (traverse-element-content e (resolve-info-ci i))]))

(provide element-traverse-procedure/c)

;; ----------------------------------------

;; Delayed element has special serialization support:
(define-struct delayed-element (resolve sizer plain)
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-delayed-element
                "current-serialize-resolve-info not set"))
       (with-handlers ([exn:fail:contract?
                        (lambda (exn)
                          (error 'serialize-delayed-element
                                 "serialization failed (wrong resolve info? delayed element never rendered?); ~a"
                                 (exn-message exn)))])
         (vector (delayed-element-content d ri)))))
   #'deserialize-delayed-element
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(provide
 (struct-out delayed-element))

(module+ deserialize-info
  (provide deserialize-delayed-element))
(define deserialize-delayed-element
  (make-deserialize-info values values))

(provide delayed-element-content)
(define (delayed-element-content e ri)
  (hash-ref (resolve-info-delays ri) e))

(provide delayed-block-blocks)
(define (delayed-block-blocks p ri)
  (hash-ref (resolve-info-delays ri) p))

(provide current-serialize-resolve-info)
(define current-serialize-resolve-info (make-parameter #f))

;; ----------------------------------------

;; part-relative element has special serialization support:
(define-struct part-relative-element (collect sizer plain)
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-part-relative-element
                "current-serialize-resolve-info not set"))
       (with-handlers ([exn:fail:contract?
                        (lambda (exn)
                          (error 'serialize-part-relative-element
                                 "serialization failed (wrong resolve info? part-relative element never rendered?); ~a"
                                 (exn-message exn)))])
         (vector
          (part-relative-element-content d ri)))))
   #'deserialize-part-relative-element
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(provide
 (struct-out part-relative-element))

(module+ deserialize-info
  (provide deserialize-part-relative-element))
(define deserialize-part-relative-element
  (make-deserialize-info values values))

(provide part-relative-element-content)
(define (part-relative-element-content e ci/ri)
  (hash-ref (collect-info-relatives
             (if (resolve-info? ci/ri) (resolve-info-ci ci/ri) ci/ri))
            e))

(provide collect-info-parents)

;; ----------------------------------------

;; Delayed index entry also has special serialization support.
;; It uses the same delay -> value table as delayed-element
(define-struct delayed-index-desc (resolve)
  #:mutable
  #:property
  prop:serializable 
  (make-serialize-info
   (lambda (d)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-delayed-index-desc
                "current-serialize-resolve-info not set"))
       (with-handlers ([exn:fail:contract?
                        (lambda (exn)
                          (error 'serialize-index-desc
                                 "serialization failed (wrong resolve info?); ~a"
                                 (exn-message exn)))])
         (vector
          (delayed-element-content d ri)))))
   #'deserialize-delayed-index-desc
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(provide
 (struct-out delayed-index-desc))

(module+ deserialize-info
  (provide deserialize-delayed-index-desc))
(define deserialize-delayed-index-desc
  (make-deserialize-info values values))

;; ----------------------------------------

(define-struct (collect-element element) (collect)
  #:mutable
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (vector (make-element
              (element-style d)
              (element-content d))))
   #'deserialize-collect-element
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(module+ deserialize-info
  (provide deserialize-collect-element))
(define deserialize-collect-element
  (make-deserialize-info values values))

(provide
 (struct-out collect-element))

;; ----------------------------------------

(define-struct (render-element element) (render)
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (d)
     (vector (make-element
              (element-style d)
              (element-content d))))
   #'deserialize-render-element
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(module+ deserialize-info
  (provide deserialize-render-element))
(define deserialize-render-element
  (make-deserialize-info values values))

(provide
 (struct-out render-element))

;; ----------------------------------------

(define-struct generated-tag ()
  #:property
  prop:serializable
  (make-serialize-info
   (lambda (g)
     (let ([ri (current-serialize-resolve-info)])
       (unless ri
         (error 'serialize-generated-tag
                "current-serialize-resolve-info not set"))
       (let ([t (hash-ref (collect-info-tags (resolve-info-ci ri)) g #f)])
         (if t
             (vector t)
             (error 'serialize-generated-tag
                    "serialization failed (wrong resolve info?)")))))
   #'deserialize-generated-tag
   #f
   (or (current-load-relative-directory) (current-directory)))
  #:transparent)

(provide (struct-out generated-tag))

(module+ deserialize-info
  (provide deserialize-generated-tag))
(define deserialize-generated-tag
  (make-deserialize-info values values))

(provide generate-tag tag-key
         current-tag-prefixes
         add-current-tag-prefix)

(define (generate-tag tg ci)
  (if (generated-tag? (cadr tg))
      (let ([t (cadr tg)])
        (list (car tg)
              (let ([tags (collect-info-tags ci)])
                (or (hash-ref tags t #f)
                    (let ([key (list* 'gentag
                                      (hash-count tags)
                                      (collect-info-gen-prefix ci))])
                      (hash-set! tags t key)
                      key)))))
      tg))

(define (tag-key tg ri)
  (if (generated-tag? (cadr tg))
      (list (car tg)
            (hash-ref (collect-info-tags (resolve-info-ci ri)) (cadr tg)))
      tg))

(define current-tag-prefixes
  (make-parameter null))

(define (add-current-tag-prefix t)
  (let ([l (current-tag-prefixes)])
    (if (null? l)
        t
        (cons (car t) (append l (cdr t))))))

;; ----------------------------------------

(provide content->string
         strip-aux)

;; content->port: output-port content -> void
;; Writes the string content of content into op.
(define content->port
  (case-lambda
    [(op c)
     (cond
       [(element? c) (content->port op (element-content c))]
       [(multiarg-element? c) (content->port op (multiarg-element-contents c))]
       [(list? c) (for-each (lambda (e) (content->port op e)) c)]
       [(part-relative-element? c) (content->port op ((part-relative-element-plain c)))]
       [(delayed-element? c) (content->port op ((delayed-element-plain c)))]
       [(string? c) (display c op)]
       [else (display (case c
                        [(mdash) "---"]
                        [(ndash) "--"]
                        [(ldquo rdquo) "\""]
                        [(rsquo) "'"]
                        [(rarr) "->"]
                        [(lang) "<"]
                        [(rang) ">"]
                        [(nbsp) "\xA0"]
                        [else (format "~s" c)])
                      op)])]
    [(op c renderer sec ri)
     (cond
       [(and (link-element? c)
             (null? (element-content c)))
        (let ([dest (resolve-get sec ri (link-element-tag c))])
          ;; FIXME: this is specific to renderer
          (if dest
              (content->port op
                             (strip-aux
                              (if (pair? dest) (cadr dest) (vector-ref dest 1)))
                             renderer sec ri)
              (display "???" op)))]
       [(element? c) (content->port op (element-content c) renderer sec ri)]
       [(multiarg-element? c) (content->port op (multiarg-element-contents c) renderer sec ri)]
       [(list? c) (for-each (lambda (e)
                              (content->port op e renderer sec ri))
                            c)]
       [(delayed-element? c)
        (content->port op (delayed-element-content c ri) renderer sec ri)]
       [(part-relative-element? c)
        (content->port op (part-relative-element-content c ri) renderer sec ri)]
       [else (content->port op c)])]))

(define (simple-content->string c)
  ;; `content->string' is commonly used on a list containing a single string
  (cond
    [(string? c) c]
    [(and (pair? c)
          (string? (car c))
          (null? (cdr c)))
     (car c)]
    [else #f]))

(define content->string
  (case-lambda
    [(c)
     (or (simple-content->string c)
         (let ([op (open-output-string)])
           (content->port op c)
           (get-output-string op)))]
    [(c renderer sec ri)
     (or (simple-content->string c)
         (let ([op (open-output-string)])
           (content->port op c renderer sec ri)
           (get-output-string op)))]))


(define (aux-element? e)
  (and (element? e)
       (let ([s (element-style e)])
         (and (style? s)
              (memq 'aux (style-properties s))))))

(define (strip-aux content)
  (cond
    [(null? content) null]
    [(aux-element? content) null]
    [(element? content)
     (define c (element-content content))
     (define p (strip-aux c))
     (if (equal? c p)
         content
         (struct-copy element content [content p]))]
    [(list? content) 
     (define p (map strip-aux content))
     (if (equal? p content)
         content
         p)]
    [else content]))

;; ----------------------------------------

(provide block-width
         content-width)

(define (content-width s)
  (cond
    [(string? s) (string-length s)]
    [(list? s) (for/fold ([v 0]) ([s (in-list s)]) (+ v (content-width s)))]
    [(element? s) (content-width (element-content s))]
    [(multiarg-element? s) (content-width (multiarg-element-contents s))]
    [(delayed-element? s) (content-width ((delayed-element-sizer s)))]
    [(part-relative-element? s) (content-width ((part-relative-element-sizer s)))]
    [else 1]))

(define (paragraph-width s)
  (content-width (paragraph-content s)))

(define (flow-width f)
  (apply max 0 (map block-width f)))

(define (block-width p)
  (cond
    [(paragraph? p) (paragraph-width p)]
    [(table? p) (table-width p)]
    [(itemization? p) (itemization-width p)]
    [(nested-flow? p) (nested-flow-width p)]
    [(compound-paragraph? p) (compound-paragraph-width p)]
    [(delayed-block? p) 1]
    [(eq? p 'cont) 0]))

(define (table-width p)
  (let ([blocks (table-blockss p)])
    (if (null? blocks)
        0
        (let loop ([blocks blocks])
          (if (null? (car blocks))
              0
              (+ (apply max 0 (map block-width (map car blocks)))
                 (loop (map cdr blocks))))))))

(define (itemization-width p)
  (apply max 0 (map flow-width (itemization-blockss p))))

(define (nested-flow-width p)
  (+ 4 (apply max 0 (map block-width (nested-flow-blocks p)))))

(define (compound-paragraph-width p)
  (apply max 0 (map block-width (compound-paragraph-blocks p))))

;; ----------------------------------------

(define (info-key? l)
  (and (pair? l)
       (symbol? (car l))
       (pair? (cdr l))))

(provide info-key?)
(provide
 part-collected-info
 collect-put!
 resolve-get
 resolve-get/tentative
 resolve-get/ext?
 resolve-get/ext-id
 resolve-search
 resolve-get-keys)
