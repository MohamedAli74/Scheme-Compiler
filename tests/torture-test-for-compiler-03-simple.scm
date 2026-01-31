;;; torture-test-for-compiler-03.scm
;;; Testing lambda-opt and lambda-variadic; Should return #t
;;;
;;; Programmer: Mayer Goldberg, 2010

(define with (lambda (s f) (__bin-apply f s)))

(define crazy-ack
  (letrec ((ack3
	    (lambda (a b c)
	      (cond
	       ((and (zero? a) (zero? b)) (__bin-add-zz c 1))
	       ((and (zero? a) (zero? c)) (ack-x 0 (__bin-sub-zz b 1) 1))
	       ((zero? a) (ack-z 0 (__bin-sub-zz b 1) (ack-y 0 b (__bin-sub-zz c 1))))
	       ((and (zero? b) (zero? c)) (ack-x (__bin-sub-zz a 1) 1 0))
	       ((zero? b) (ack-z (__bin-sub-zz a 1) 1 (ack-y a 0 (__bin-sub-zz c 1))))
	       ((zero? c) (ack-x (__bin-sub-zz a 1) b (ack-y a (__bin-sub-zz b 1) 1)))
	       (else (ack-z (__bin-sub-zz a 1) b (ack-y a (__bin-sub-zz b 1) (ack-x a b (__bin-sub-zz c 1))))))))
	   (ack-x
	    (lambda (a . bcs)
	      (with bcs
		(lambda (b c)
		  (ack3 a b c)))))
	   (ack-y
	    (lambda (a b . cs)
	      (with cs
		(lambda (c)
		  (ack3 a b c)))))
	   (ack-z
	    (lambda abcs
	      (with abcs
		(lambda (a b c)
		  (ack3 a b c))))))
    (lambda ()
      (and (__bin-equal-zz 7 (ack3 0 2 2))
	   (__bin-equal-zz 61 (ack3 0 3 3))
	   (__bin-equal-zz 316 (ack3 1 1 5))
	   (__bin-equal-zz 636 (ack3 2 0 1))
	   ))))

(crazy-ack)
