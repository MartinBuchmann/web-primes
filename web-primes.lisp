;;;; web-prime.lisp
;;; Time-stamp: <2017-03-30 12:28:27 Martin>
;;;
;;; A simple Web-App calculating prime factors
;;;
;;; Inspired by Adam Tornhill's tutorial (https://leanpub.com/lispweb)
;;; See README.org for more information.
;;;

(in-package #:web-primes)

;;; The basic calculation
(defun is-prime (n &optional (divisor 2))
  "Determine whether a given integer number is prime using a simple recursive way."
  (cond ((not (integerp n)) nil)
	((= 1 n) nil)
	((= 2 n) t)
	((> divisor (isqrt n)) t)
	((= (mod n divisor) 0) nil)
	(t (is-prime n (1+ divisor)))))

(defun prime-factors (n &optional (m 2))
  "Returns a flat list containing the prime factors of `n'."
  (cond ((or (not (integerp n)) (< n 0)) 0)
	((or (is-prime n) (= n 2)) (list n))
	((= (mod n m) 0) (cons m (prime-factors (/ n m) m)))
	(t (prime-factors n (1+ m)))))

;;; Web Server - Hunchentoot
;;; 
(defun start-server (port)
  "Provides a short cut to start the hunchentoot web server."
  (setf *acceptor* (make-instance 'easy-acceptor :port port))
  (start *acceptor*))

(defun publish-static-content ()
  "Pushing the static content."
  (push (create-static-file-dispatcher-and-handler
         "/primes.css" "static/primes.css") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/Factor_Tree_of_42.png" "static/Factor_Tree_of_42.png") *dispatch-table*)
  (push (create-static-file-dispatcher-and-handler
         "/lisplogo_fancy_256.png" "static/lisplogo_fancy_256.png") *dispatch-table*))


;;; Following Adam's example and creating a DSL for generating the web pages.

; Control the cl-who output format (default is XHTML, we
; want HTML5):
(setf (html-mode) :html5)

(defmacro standard-page ((&key title script) &body body)
  "All pages on the Retro Games site will use the following macro;
   less to type and a uniform look of the pages (defines the header
   and the stylesheet).
   The macro also accepts an optional script argument. When present, the
   script form is expected to expand into valid JavaScript."
  `(with-html-output-to-string
    (*standard-output* nil :prologue t :indent t)
    (:html :lang "en"
           (:head
            (:meta :charset "utf-8")
            (:title ,title)
            (:link :type "text/css"
                   :rel "stylesheet"
                   :href "/primes.css")
            ,(when script
               `(:script :type "text/javascript"
                         (str ,script))))
           (:body
            (:div :id "header"
                  (:img :src "/Factor_Tree_of_42.png"
                        :alt "Factor tree"
                        :height "100px"
                        :class "logo")
                  (:span :class "strapline"
                         "Wir berechnen Primfaktoren"))
            ,@body
            (:div :id "footer"
                  (:img :src "/lisplogo_fancy_256.png"
                        :alt "Made with Lisp"
                        :height "100px"
                        :class "logo")
                  (:span :class "strapline"
                         (:a :href "https://github.com/MartinBuchmann/web-primes" "The source code")
                         ))))))

;;; Generating the actual pages
;;
;; We will have to pages:
;; 1. The frist asking for a number, doing some basic validation using parenscript
;; 2. The second will present the results.
;;

(define-easy-handler (primfaktoren :uri "/primfaktoren") ()
  (standard-page (:title "Primfaktoren"
                  :script (ps  ; Validationg something was entered
                                  (defvar factor nil)
                                  (defun validate-game-name (evt)
                                    (when (= (@ factor zahl value) "")
                                      (chain evt (prevent-default))
                                      (alert "Bitte gib eine Zahl ein.")))
                                  (defun init ()
                                    (setf factor (chain document
                                                          (get-element-by-id "factor")))
                                    (chain factor
                                           (add-event-listener "submit" validate-game-name false)))
                                   (setf (chain window onload) init)))
    (:h1 "Primfaktorzerlegung")
    (:form :action "/faktorisieren" :method "post" :id "factor"
           (:p "Gib eine Zahl ein: " (:br)
               (:input :type "number" :name "zahl" :class "txt" :min "1"))
           (:p (:input :type "submit" :value "berechne" :class "btn")))))

(define-easy-handler (faktorisieren :uri "/faktorisieren") (zahl)
  (standard-page (:title "Primfaktoren")
    (:h1 "Primfaktorzerlegung")
    (let ((num (parse-integer zahl :junk-allowed t)))
      (if (integerp num)
          (htm (fmt "~D = ~{~D ~^* ~}" zahl (prime-factors num)))
          (htm (fmt "~S" num)))) (:br)
                 (:a :href "/primfaktoren" "Zurück") (:br)))

;;; Everything is set up and we can start the server.
(publish-static-content)
(start-server 8080)
