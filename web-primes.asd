;;;; web-primes.asd

(asdf:defsystem #:web-primes
  :description "A simple web app factorizing number into primes."
  :author "Martin Buchmann <Martin.Buchmann@gmail.com>"
  :license "Public Domain"
  :depends-on (#:cl-who
               #:parenscript
               #:hunchentoot
               #:lass)
  :defsystem-depends-on (#:lass)
  :serial t
  :components ((:file "package")
               (:file "web-primes")
               (:lass-file "primes" :output "static/primes.css")))
