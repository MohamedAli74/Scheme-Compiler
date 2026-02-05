;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 2015:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2029:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2043:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2055:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2070:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2086:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2104:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2119:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2138:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2148:
	db T_interned_symbol	; +
	dq L_constants + 2138
	; L_constants + 2157:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2198:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2232:
	db T_integer	; 0
	dq 0
	; L_constants + 2241:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2251:
	db T_interned_symbol	; -
	dq L_constants + 2241
	; L_constants + 2260:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2273:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2283:
	db T_interned_symbol	; *
	dq L_constants + 2273
	; L_constants + 2292:
	db T_integer	; 1
	dq 1
	; L_constants + 2301:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2311:
	db T_interned_symbol	; /
	dq L_constants + 2301
	; L_constants + 2320:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2333:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2343:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2354:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2364:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2375:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2385:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2412:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2385
	; L_constants + 2421:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2463:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2478:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2494:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2509:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2524:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2540:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2562:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2582:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2591:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2643:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 2652:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2704:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2725:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2746:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2761:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2782:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2803:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 2818:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2836:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2854:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 2868:
	db T_integer	; 2
	dq 2
	; L_constants + 2877:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 2890:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 2902:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 2917:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2934:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 2948:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2970:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2992:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3015:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3038:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3062:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3086:
	db T_string	; "make-list-generator...
	dq 19
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x67, 0x65, 0x6E, 0x65, 0x72, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 3114:
	db T_string	; "make-string-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3144:
	db T_string	; "make-vector-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3174:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3192:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3201:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3217:
	db T_char, 0x0A	; #\newline
	; L_constants + 3219:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
	; L_constants + 3232:
	db T_integer	; 10
	dq 10
	; L_constants + 3241:
	db T_integer	; 3
	dq 3
	; L_constants + 3250:
	db T_integer	; 4
	dq 4
	; L_constants + 3259:
	db T_pair	; (4)
	dq L_constants + 3250, L_constants + 1
	; L_constants + 3276:
	db T_pair	; (3 4)
	dq L_constants + 3241, L_constants + 3259
	; L_constants + 3293:
	db T_pair	; (2 3 4)
	dq L_constants + 2868, L_constants + 3276
	; L_constants + 3310:
	db T_pair	; (1 2 3 4)
	dq L_constants + 2292, L_constants + 3293
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2273

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2138

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2241

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2301

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2333

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2343

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2375

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2354

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2364

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2198

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2890

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2055

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2104

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2015

free_var_34:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2934

free_var_35:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_36:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_37:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_38:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_39:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_40:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_41:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_42:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_43:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_44:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_45:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_46:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_47:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_48:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_49:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_50:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_51:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_52:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_53:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_54:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_55:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_56:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_57:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_58:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_59:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_60:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_61:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_62:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_63:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_64:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_65:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_66:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2540

free_var_67:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2562

free_var_68:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2478

free_var_69:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2463

free_var_70:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2494

free_var_71:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2524

free_var_72:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2509

free_var_73:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_74:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_75:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_76:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2902

free_var_77:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_78:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2854

free_var_79:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2320

free_var_80:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2086

free_var_81:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2119

free_var_82:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_83:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_84:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_85:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_86:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_87:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_88:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2725

free_var_89:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2704

free_var_90:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_91:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3174

free_var_92:	; location of make-list-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3086

free_var_93:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_94:	; location of make-string-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3114

free_var_95:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_96:	; location of make-vector-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3144

free_var_97:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2043

free_var_98:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2836

free_var_99:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3201

free_var_100:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_101:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_102:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_103:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2877

free_var_104:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2029

free_var_105:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_106:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2818

free_var_107:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2803

free_var_108:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_109:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2260

free_var_110:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_111:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_112:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2070

free_var_113:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2761

free_var_114:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2948

free_var_115:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_116:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_117:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2992

free_var_118:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3038

free_var_119:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_120:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2917

free_var_121:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_122:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_123:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2746

free_var_124:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2782

free_var_125:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2970

free_var_126:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_127:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_128:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3015

free_var_129:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3062

free_var_130:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_131:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_132:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3219

free_var_133:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_134:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_135:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_101
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_105
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_73
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_121
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_131
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_110
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_83
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_102
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_74
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_134
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_49
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_64
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_115
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_126
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_84
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_82
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_122
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_135
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_85
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_77
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_111
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_116
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_127
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_130
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_119
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_95
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_93
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_75
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ab
	jmp .L_lambda_simple_end_01ab
.L_lambda_simple_code_01ab:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ab:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0262:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0262
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0262
.L_tc_recycle_frame_done_0262:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ab:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ac
	jmp .L_lambda_simple_end_01ac
.L_lambda_simple_code_01ac:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ac:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0263:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0263
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0263
.L_tc_recycle_frame_done_0263:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ac:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ad
	jmp .L_lambda_simple_end_01ad
.L_lambda_simple_code_01ad:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ad:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0264:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0264
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0264
.L_tc_recycle_frame_done_0264:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ad:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ae
	jmp .L_lambda_simple_end_01ae
.L_lambda_simple_code_01ae:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ae:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0265:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0265
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0265
.L_tc_recycle_frame_done_0265:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ae:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01af
	jmp .L_lambda_simple_end_01af
.L_lambda_simple_code_01af:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01af
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01af:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0266:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0266
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0266
.L_tc_recycle_frame_done_0266:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01af:	; new closure is in rax
	mov qword [free_var_37], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b0
	jmp .L_lambda_simple_end_01b0
.L_lambda_simple_code_01b0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0267:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0267
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0267
.L_tc_recycle_frame_done_0267:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b0:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b1
	jmp .L_lambda_simple_end_01b1
.L_lambda_simple_code_01b1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0268:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0268
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0268
.L_tc_recycle_frame_done_0268:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b1:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b2
	jmp .L_lambda_simple_end_01b2
.L_lambda_simple_code_01b2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0269:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0269
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0269
.L_tc_recycle_frame_done_0269:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b2:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b3
	jmp .L_lambda_simple_end_01b3
.L_lambda_simple_code_01b3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b3:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026a
.L_tc_recycle_frame_done_026a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b3:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b4
	jmp .L_lambda_simple_end_01b4
.L_lambda_simple_code_01b4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026b
.L_tc_recycle_frame_done_026b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b4:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b5
	jmp .L_lambda_simple_end_01b5
.L_lambda_simple_code_01b5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b5:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026c
.L_tc_recycle_frame_done_026c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b5:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b6
	jmp .L_lambda_simple_end_01b6
.L_lambda_simple_code_01b6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026d
.L_tc_recycle_frame_done_026d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b6:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b7
	jmp .L_lambda_simple_end_01b7
.L_lambda_simple_code_01b7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b7:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026e
.L_tc_recycle_frame_done_026e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b7:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b8
	jmp .L_lambda_simple_end_01b8
.L_lambda_simple_code_01b8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b8:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_026f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_026f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_026f
.L_tc_recycle_frame_done_026f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b8:	; new closure is in rax
	mov qword [free_var_36], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01b9
	jmp .L_lambda_simple_end_01b9
.L_lambda_simple_code_01b9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01b9:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0270:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0270
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0270
.L_tc_recycle_frame_done_0270:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01b9:	; new closure is in rax
	mov qword [free_var_38], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ba
	jmp .L_lambda_simple_end_01ba
.L_lambda_simple_code_01ba:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ba:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0271:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0271
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0271
.L_tc_recycle_frame_done_0271:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ba:	; new closure is in rax
	mov qword [free_var_39], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01bb
	jmp .L_lambda_simple_end_01bb
.L_lambda_simple_code_01bb:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bb:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0272:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0272
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0272
.L_tc_recycle_frame_done_0272:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01bb:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01bc
	jmp .L_lambda_simple_end_01bc
.L_lambda_simple_code_01bc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bc:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0273:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0273
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0273
.L_tc_recycle_frame_done_0273:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01bc:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01bd
	jmp .L_lambda_simple_end_01bd
.L_lambda_simple_code_01bd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bd:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0274:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0274
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0274
.L_tc_recycle_frame_done_0274:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01bd:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01be
	jmp .L_lambda_simple_end_01be
.L_lambda_simple_code_01be:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01be:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0275:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0275
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0275
.L_tc_recycle_frame_done_0275:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01be:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01bf
	jmp .L_lambda_simple_end_01bf
.L_lambda_simple_code_01bf:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01bf:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0276:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0276
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0276
.L_tc_recycle_frame_done_0276:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01bf:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c0
	jmp .L_lambda_simple_end_01c0
.L_lambda_simple_code_01c0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0277:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0277
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0277
.L_tc_recycle_frame_done_0277:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c0:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c1
	jmp .L_lambda_simple_end_01c1
.L_lambda_simple_code_01c1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0278:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0278
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0278
.L_tc_recycle_frame_done_0278:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c1:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c2
	jmp .L_lambda_simple_end_01c2
.L_lambda_simple_code_01c2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0279:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0279
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0279
.L_tc_recycle_frame_done_0279:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c2:	; new closure is in rax
	mov qword [free_var_54], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c3
	jmp .L_lambda_simple_end_01c3
.L_lambda_simple_code_01c3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c3:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027a
.L_tc_recycle_frame_done_027a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c3:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c4
	jmp .L_lambda_simple_end_01c4
.L_lambda_simple_code_01c4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027b
.L_tc_recycle_frame_done_027b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c4:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c5
	jmp .L_lambda_simple_end_01c5
.L_lambda_simple_code_01c5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c5:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027c
.L_tc_recycle_frame_done_027c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c5:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c6
	jmp .L_lambda_simple_end_01c6
.L_lambda_simple_code_01c6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027d
.L_tc_recycle_frame_done_027d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c6:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c7
	jmp .L_lambda_simple_end_01c7
.L_lambda_simple_code_01c7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c7:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_0016
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_016c
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027e
.L_tc_recycle_frame_done_027e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_016c
.L_if_else_016c:
	mov rax, L_constants + 2
.L_if_end_016c:
.L_or_end_0016:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c7:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_003d
	jmp .L_lambda_opt_end_003d
.L_lambda_opt_code_003d:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_003d:	; new closure is in rax
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c8
	jmp .L_lambda_simple_end_01c8
.L_lambda_simple_code_01c8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c8:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_016d
	mov rax, L_constants + 2
	jmp .L_if_end_016d
.L_if_else_016d:
	mov rax, L_constants + 3
.L_if_end_016d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c8:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01c9
	jmp .L_lambda_simple_end_01c9
.L_lambda_simple_code_01c9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01c9:
	enter 0, 0
	mov rax, PARAM(0)	; param q
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_0017
	mov rax, PARAM(0)	; param q
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_027f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_027f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_027f
.L_tc_recycle_frame_done_027f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_or_end_0017:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01c9:	; new closure is in rax
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ca
	jmp .L_lambda_simple_end_01ca
.L_lambda_simple_code_01ca:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ca:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01cb
	jmp .L_lambda_simple_end_01cb
.L_lambda_simple_code_01cb:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01cb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cb:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_016e
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_016e
.L_if_else_016e:
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0280:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0280
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0280
.L_tc_recycle_frame_done_0280:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_016e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01cb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_003e
	jmp .L_lambda_opt_end_003e
.L_lambda_opt_code_003e:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0281:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0281
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0281
.L_tc_recycle_frame_done_0281:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_003e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ca:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01cc
	jmp .L_lambda_simple_end_01cc
.L_lambda_simple_code_01cc:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01cc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cc:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, PARAM(1)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0282:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0282
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0282
.L_tc_recycle_frame_done_0282:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01cc:	; new closure is in rax
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01cd
	jmp .L_lambda_simple_end_01cd
.L_lambda_simple_code_01cd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cd:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ce
	jmp .L_lambda_simple_end_01ce
.L_lambda_simple_code_01ce:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01ce
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ce:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_016f
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0283:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0283
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0283
.L_tc_recycle_frame_done_0283:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_016f
.L_if_else_016f:
	mov rax, PARAM(0)	; param a
.L_if_end_016f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01ce:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_003f
	jmp .L_lambda_opt_end_003f
.L_lambda_opt_code_003f:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0284:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0284
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0284
.L_tc_recycle_frame_done_0284:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_003f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01cd:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0040
	jmp .L_lambda_opt_end_0040
.L_lambda_opt_code_0040:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01cf
	jmp .L_lambda_simple_end_01cf
.L_lambda_simple_code_01cf:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01cf:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d0
	jmp .L_lambda_simple_end_01d0
.L_lambda_simple_code_01d0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d0:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0170
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_0018
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0285:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0285
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0285
.L_tc_recycle_frame_done_0285:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_or_end_0018:
	jmp .L_if_end_0170
.L_if_else_0170:
	mov rax, L_constants + 2
.L_if_end_0170:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0171
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0286:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0286
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0286
.L_tc_recycle_frame_done_0286:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0171
.L_if_else_0171:
	mov rax, L_constants + 2
.L_if_end_0171:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01cf:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0287:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0287
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0287
.L_tc_recycle_frame_done_0287:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0040:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0041
	jmp .L_lambda_opt_end_0041
.L_lambda_opt_code_0041:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d1
	jmp .L_lambda_simple_end_01d1
.L_lambda_simple_code_01d1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d1:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d2
	jmp .L_lambda_simple_end_01d2
.L_lambda_simple_code_01d2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d2:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_0019
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0172
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0288:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0288
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0288
.L_tc_recycle_frame_done_0288:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0172
.L_if_else_0172:
	mov rax, L_constants + 2
.L_if_end_0172:
.L_or_end_0019:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_001a
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0173
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0289:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0289
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0289
.L_tc_recycle_frame_done_0289:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0173
.L_if_else_0173:
	mov rax, L_constants + 2
.L_if_end_0173:
.L_or_end_001a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d1:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028a
.L_tc_recycle_frame_done_028a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0041:	; new closure is in rax
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d3
	jmp .L_lambda_simple_end_01d3
.L_lambda_simple_code_01d3:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d3:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing map1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing map-list
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d4
	jmp .L_lambda_simple_end_01d4
.L_lambda_simple_code_01d4:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d4:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0174
	mov rax, L_constants + 1
	jmp .L_if_end_0174
.L_if_else_0174:
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, PARAM(0)	; param f
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028b
.L_tc_recycle_frame_done_028b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0174:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d4:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d5
	jmp .L_lambda_simple_end_01d5
.L_lambda_simple_code_01d5:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d5:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0175
	mov rax, L_constants + 1
	jmp .L_if_end_0175
.L_if_else_0175:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028c
.L_tc_recycle_frame_done_028c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0175:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d5:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0042
	jmp .L_lambda_opt_end_0042
.L_lambda_opt_code_0042:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0176
	mov rax, L_constants + 1
	jmp .L_if_end_0176
.L_if_else_0176:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028d
.L_tc_recycle_frame_done_028d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0176:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0042:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d3:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d6
	jmp .L_lambda_simple_end_01d6
.L_lambda_simple_code_01d6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d6:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d7
	jmp .L_lambda_simple_end_01d7
.L_lambda_simple_code_01d7:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d7:
	enter 0, 0
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028e
.L_tc_recycle_frame_done_028e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d7:	; new closure is in rax
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_028f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_028f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_028f
.L_tc_recycle_frame_done_028f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01d6:	; new closure is in rax
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d8
	jmp .L_lambda_simple_end_01d8
.L_lambda_simple_code_01d8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d8:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run-1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing run-2
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01d9
	jmp .L_lambda_simple_end_01d9
.L_lambda_simple_code_01d9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01d9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01d9:
	enter 0, 0
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0177
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_0177
.L_if_else_0177:
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param sr
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0290:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0290
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0290
.L_tc_recycle_frame_done_0290:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0177:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d9:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01da
	jmp .L_lambda_simple_end_01da
.L_lambda_simple_code_01da:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01da
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01da:
	enter 0, 0
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0178
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_0178
.L_if_else_0178:
	mov rax, PARAM(1)	; param s2
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0291:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0291
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0291
.L_tc_recycle_frame_done_0291:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0178:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01da:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0043
	jmp .L_lambda_opt_end_0043
.L_lambda_opt_code_0043:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0179
	mov rax, L_constants + 1
	jmp .L_if_end_0179
.L_if_else_0179:
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0292:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0292
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0292
.L_tc_recycle_frame_done_0292:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0179:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0043:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01d8:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01db
	jmp .L_lambda_simple_end_01db
.L_lambda_simple_code_01db:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01db
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01db:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01dc
	jmp .L_lambda_simple_end_01dc
.L_lambda_simple_code_01dc:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_01dc
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01dc:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017a
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_017a
.L_if_else_017a:
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0293:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0293
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0293
.L_tc_recycle_frame_done_0293:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_017a:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01dc:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0044
	jmp .L_lambda_opt_end_0044
.L_lambda_opt_code_0044:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0294:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0294
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0294
.L_tc_recycle_frame_done_0294:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0044:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01db:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01dd
	jmp .L_lambda_simple_end_01dd
.L_lambda_simple_code_01dd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01dd:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01de
	jmp .L_lambda_simple_end_01de
.L_lambda_simple_code_01de:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_01de
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01de:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017b
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_017b
.L_if_else_017b:
	mov rax, L_constants + 1
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0295:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0295
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0295
.L_tc_recycle_frame_done_0295:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_017b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01de:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0045
	jmp .L_lambda_opt_end_0045
.L_lambda_opt_code_0045:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0296:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0296
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0296
.L_tc_recycle_frame_done_0296:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0045:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01dd:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01df
	jmp .L_lambda_simple_end_01df
.L_lambda_simple_code_01df:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01df
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01df:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin+
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e0
	jmp .L_lambda_simple_end_01e0
.L_lambda_simple_code_01e0:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01e0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e0:
	enter 0, 0
	mov rax, L_constants + 2157
	push rax
	mov rax, L_constants + 2148
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0297:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0297
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0297
.L_tc_recycle_frame_done_0297:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01e0:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e1
	jmp .L_lambda_simple_end_01e1
.L_lambda_simple_code_01e1:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e1:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0187
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017e
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0298:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0298
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0298
.L_tc_recycle_frame_done_0298:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_017e
.L_if_else_017e:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017d
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0299:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0299
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0299
.L_tc_recycle_frame_done_0299:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_017d
.L_if_else_017d:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017c
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029a
.L_tc_recycle_frame_done_029a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_017c
.L_if_else_017c:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029b
.L_tc_recycle_frame_done_029b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_017c:
.L_if_end_017d:
.L_if_end_017e:
	jmp .L_if_end_0187
.L_if_else_0187:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0186
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0181
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029c
.L_tc_recycle_frame_done_029c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0181
.L_if_else_0181:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0180
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029d
.L_tc_recycle_frame_done_029d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0180
.L_if_else_0180:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_017f
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029e
.L_tc_recycle_frame_done_029e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_017f
.L_if_else_017f:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_029f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_029f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_029f
.L_tc_recycle_frame_done_029f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_017f:
.L_if_end_0180:
.L_if_end_0181:
	jmp .L_if_end_0186
.L_if_else_0186:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0185
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0184
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a0
.L_tc_recycle_frame_done_02a0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0184
.L_if_else_0184:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0183
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a1
.L_tc_recycle_frame_done_02a1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0183
.L_if_else_0183:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0182
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a2
.L_tc_recycle_frame_done_02a2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0182
.L_if_else_0182:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a3
.L_tc_recycle_frame_done_02a3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0182:
.L_if_end_0183:
.L_if_end_0184:
	jmp .L_if_end_0185
.L_if_else_0185:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a4
.L_tc_recycle_frame_done_02a4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0185:
.L_if_end_0186:
.L_if_end_0187:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e1:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin+
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0046
	jmp .L_lambda_opt_end_0046
.L_lambda_opt_code_0046:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	mov rax, qword [rax]
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a5
.L_tc_recycle_frame_done_02a5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0046:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01df:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e2
	jmp .L_lambda_simple_end_01e2
.L_lambda_simple_code_01e2:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e2:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin-
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e3
	jmp .L_lambda_simple_end_01e3
.L_lambda_simple_code_01e3:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01e3
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e3:
	enter 0, 0
	mov rax, L_constants + 2157
	push rax
	mov rax, L_constants + 2251
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a6
.L_tc_recycle_frame_done_02a6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01e3:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e4
	jmp .L_lambda_simple_end_01e4
.L_lambda_simple_code_01e4:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e4:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0193
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018a
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a7
.L_tc_recycle_frame_done_02a7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018a
.L_if_else_018a:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0189
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a8
.L_tc_recycle_frame_done_02a8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0189
.L_if_else_0189:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_109]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0188
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02a9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02a9
.L_tc_recycle_frame_done_02a9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0188
.L_if_else_0188:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02aa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02aa
.L_tc_recycle_frame_done_02aa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0188:
.L_if_end_0189:
.L_if_end_018a:
	jmp .L_if_end_0193
.L_if_else_0193:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0192
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018d
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ab
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ab
.L_tc_recycle_frame_done_02ab:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018d
.L_if_else_018d:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018c
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ac
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ac
.L_tc_recycle_frame_done_02ac:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018c
.L_if_else_018c:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018b
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ad
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ad
.L_tc_recycle_frame_done_02ad:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018b
.L_if_else_018b:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ae
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ae
.L_tc_recycle_frame_done_02ae:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_018b:
.L_if_end_018c:
.L_if_end_018d:
	jmp .L_if_end_0192
.L_if_else_0192:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0191
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0190
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02af:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02af
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02af
.L_tc_recycle_frame_done_02af:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0190
.L_if_else_0190:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018f
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b0
.L_tc_recycle_frame_done_02b0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018f
.L_if_else_018f:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_018e
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b1
.L_tc_recycle_frame_done_02b1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_018e
.L_if_else_018e:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b2
.L_tc_recycle_frame_done_02b2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_018e:
.L_if_end_018f:
.L_if_end_0190:
	jmp .L_if_end_0191
.L_if_else_0191:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b3
.L_tc_recycle_frame_done_02b3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0191:
.L_if_end_0192:
.L_if_end_0193:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e4:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin-
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0047
	jmp .L_lambda_opt_end_0047
.L_lambda_opt_code_0047:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0194
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2232
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b4
.L_tc_recycle_frame_done_02b4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0194
.L_if_else_0194:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e5
	jmp .L_lambda_simple_end_01e5
.L_lambda_simple_code_01e5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e5:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b5
.L_tc_recycle_frame_done_02b5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01e5:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b6
.L_tc_recycle_frame_done_02b6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0194:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0047:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e2:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e6
	jmp .L_lambda_simple_end_01e6
.L_lambda_simple_code_01e6:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e6:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin*
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e7
	jmp .L_lambda_simple_end_01e7
.L_lambda_simple_code_01e7:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01e7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e7:
	enter 0, 0
	mov rax, L_constants + 2157
	push rax
	mov rax, L_constants + 2283
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b7
.L_tc_recycle_frame_done_02b7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01e7:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e8
	jmp .L_lambda_simple_end_01e8
.L_lambda_simple_code_01e8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e8:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a0
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0197
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b8
.L_tc_recycle_frame_done_02b8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0197
.L_if_else_0197:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0196
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02b9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02b9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02b9
.L_tc_recycle_frame_done_02b9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0196
.L_if_else_0196:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0195
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ba
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ba
.L_tc_recycle_frame_done_02ba:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0195
.L_if_else_0195:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02bb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02bb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02bb
.L_tc_recycle_frame_done_02bb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0195:
.L_if_end_0196:
.L_if_end_0197:
	jmp .L_if_end_01a0
.L_if_else_01a0:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019f
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019a
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02bc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02bc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02bc
.L_tc_recycle_frame_done_02bc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_019a
.L_if_else_019a:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0199
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02bd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02bd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02bd
.L_tc_recycle_frame_done_02bd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0199
.L_if_else_0199:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_0198
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02be:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02be
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02be
.L_tc_recycle_frame_done_02be:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_0198
.L_if_else_0198:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02bf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02bf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02bf
.L_tc_recycle_frame_done_02bf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_0198:
.L_if_end_0199:
.L_if_end_019a:
	jmp .L_if_end_019f
.L_if_else_019f:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019e
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019d
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c0
.L_tc_recycle_frame_done_02c0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_019d
.L_if_else_019d:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019c
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c1
.L_tc_recycle_frame_done_02c1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_019c
.L_if_else_019c:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_019b
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c2
.L_tc_recycle_frame_done_02c2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_019b
.L_if_else_019b:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c3
.L_tc_recycle_frame_done_02c3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_019b:
.L_if_end_019c:
.L_if_end_019d:
	jmp .L_if_end_019e
.L_if_else_019e:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c4
.L_tc_recycle_frame_done_02c4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_019e:
.L_if_end_019f:
.L_if_end_01a0:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin*
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0048
	jmp .L_lambda_opt_end_0048
.L_lambda_opt_code_0048:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	mov rax, qword [rax]
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c5
.L_tc_recycle_frame_done_02c5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0048:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e6:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01e9
	jmp .L_lambda_simple_end_01e9
.L_lambda_simple_code_01e9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01e9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01e9:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin/
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ea
	jmp .L_lambda_simple_end_01ea
.L_lambda_simple_code_01ea:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01ea
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ea:
	enter 0, 0
	mov rax, L_constants + 2157
	push rax
	mov rax, L_constants + 2311
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c6
.L_tc_recycle_frame_done_02c6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01ea:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01eb
	jmp .L_lambda_simple_end_01eb
.L_lambda_simple_code_01eb:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01eb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01eb:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ac
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a3
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c7
.L_tc_recycle_frame_done_02c7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a3
.L_if_else_01a3:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a2
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c8
.L_tc_recycle_frame_done_02c8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a2
.L_if_else_01a2:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a1
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02c9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02c9
.L_tc_recycle_frame_done_02c9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a1
.L_if_else_01a1:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ca
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ca
.L_tc_recycle_frame_done_02ca:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01a1:
.L_if_end_01a2:
.L_if_end_01a3:
	jmp .L_if_end_01ac
.L_if_else_01ac:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ab
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a6
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02cb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02cb
.L_tc_recycle_frame_done_02cb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a6
.L_if_else_01a6:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a5
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02cc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02cc
.L_tc_recycle_frame_done_02cc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a5
.L_if_else_01a5:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a4
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02cd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02cd
.L_tc_recycle_frame_done_02cd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a4
.L_if_else_01a4:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ce
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ce
.L_tc_recycle_frame_done_02ce:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01a4:
.L_if_end_01a5:
.L_if_end_01a6:
	jmp .L_if_end_01ab
.L_if_else_01ab:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01aa
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a9
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02cf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02cf
.L_tc_recycle_frame_done_02cf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a9
.L_if_else_01a9:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a8
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d0
.L_tc_recycle_frame_done_02d0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a8
.L_if_else_01a8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01a7
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d1
.L_tc_recycle_frame_done_02d1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01a7
.L_if_else_01a7:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d2
.L_tc_recycle_frame_done_02d2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01a7:
.L_if_end_01a8:
.L_if_end_01a9:
	jmp .L_if_end_01aa
.L_if_else_01aa:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d3
.L_tc_recycle_frame_done_02d3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01aa:
.L_if_end_01ab:
.L_if_end_01ac:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01eb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin/
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0049
	jmp .L_lambda_opt_end_0049
.L_lambda_opt_code_0049:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ad
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2292
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d4
.L_tc_recycle_frame_done_02d4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01ad
.L_if_else_01ad:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ec
	jmp .L_lambda_simple_end_01ec
.L_lambda_simple_code_01ec:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ec:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d5
.L_tc_recycle_frame_done_02d5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ec:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d6
.L_tc_recycle_frame_done_02d6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01ad:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0049:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01e9:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ed
	jmp .L_lambda_simple_end_01ed
.L_lambda_simple_code_01ed:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ed:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ae
	mov rax, L_constants + 2292
	jmp .L_if_end_01ae
.L_if_else_01ae:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_79]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d7
.L_tc_recycle_frame_done_02d7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01ae:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ed:	; new closure is in rax
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 7
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ee
	jmp .L_lambda_simple_end_01ee
.L_lambda_simple_code_01ee:	
	cmp qword [rsp + 8 * 2], 7
	je .L_lambda_simple_arity_check_ok_01ee
	push qword [rsp + 8 * 2]
	push 7
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ee:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin<=?
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing bin>?
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(2)	; boxing bin>=?
	mov qword [rax], rbx
	mov PARAM(2), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(3)	; boxing bin=?
	mov qword [rax], rbx
	mov PARAM(3), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(4)	; boxing bin<?
	mov qword [rax], rbx
	mov PARAM(4), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(6)	; boxing exit
	mov qword [rax], rbx
	mov PARAM(6), rax
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ef
	jmp .L_lambda_simple_end_01ef
.L_lambda_simple_code_01ef:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_01ef
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ef:
	enter 0, 0
	mov rax, L_constants + 2421
	push rax
	mov rax, L_constants + 2412
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d8
.L_tc_recycle_frame_done_02d8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_01ef:	; new closure is in rax
	push rax
	mov rax, PARAM(6)	; param exit
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f0
	jmp .L_lambda_simple_end_01f0
.L_lambda_simple_code_01f0:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_01f0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f0:
	enter 0, 0
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f1
	jmp .L_lambda_simple_end_01f1
.L_lambda_simple_code_01f1:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f1:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ba
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b1
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02d9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02d9
.L_tc_recycle_frame_done_02d9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b1
.L_if_else_01b1:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02da
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02da
.L_tc_recycle_frame_done_02da:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b0
.L_if_else_01b0:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01af
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02db
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02db
.L_tc_recycle_frame_done_02db:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01af
.L_if_else_01af:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02dc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02dc
.L_tc_recycle_frame_done_02dc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01af:
.L_if_end_01b0:
.L_if_end_01b1:
	jmp .L_if_end_01ba
.L_if_else_01ba:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b9
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b4
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02dd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02dd
.L_tc_recycle_frame_done_02dd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b4
.L_if_else_01b4:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b3
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02de
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02de
.L_tc_recycle_frame_done_02de:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b3
.L_if_else_01b3:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b2
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02df
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02df
.L_tc_recycle_frame_done_02df:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b2
.L_if_else_01b2:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e0
.L_tc_recycle_frame_done_02e0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01b2:
.L_if_end_01b3:
.L_if_end_01b4:
	jmp .L_if_end_01b9
.L_if_else_01b9:
	mov rax, PARAM(0)	; param a
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b8
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b7
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e1
.L_tc_recycle_frame_done_02e1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b7
.L_if_else_01b7:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b6
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e2
.L_tc_recycle_frame_done_02e2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b6
.L_if_else_01b6:
	mov rax, PARAM(1)	; param b
	push rax
	push 1
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01b5
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e3
.L_tc_recycle_frame_done_02e3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01b5
.L_if_else_01b5:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e4
.L_tc_recycle_frame_done_02e4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01b5:
.L_if_end_01b6:
.L_if_end_01b7:
	jmp .L_if_end_01b8
.L_if_else_01b8:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 0 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e5
.L_tc_recycle_frame_done_02e5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01b8:
.L_if_end_01b9:
.L_if_end_01ba:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_01f0:	; new closure is in rax
	mov PARAM(5), rax	; param (set! make-bin-comparator ... )
	mov rax, sob_void

	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, PARAM(5)	; param make-bin-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(4)	; param bin<?
	pop qword [rax]
	mov rax, sob_void

	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, PARAM(5)	; param make-bin-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(3)	; param bin=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f2
	jmp .L_lambda_simple_end_01f2
.L_lambda_simple_code_01f2:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f2:
	enter 0, 0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e6
.L_tc_recycle_frame_done_02e6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f2:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param bin>=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f3
	jmp .L_lambda_simple_end_01f3
.L_lambda_simple_code_01f3:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f3:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e7
.L_tc_recycle_frame_done_02e7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f3:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param bin>?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f4
	jmp .L_lambda_simple_end_01f4
.L_lambda_simple_code_01f4:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f4:
	enter 0, 0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var bin>?
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e8
.L_tc_recycle_frame_done_02e8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f4:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin<=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f5
	jmp .L_lambda_simple_end_01f5
.L_lambda_simple_code_01f5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f5:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f6
	jmp .L_lambda_simple_end_01f6
.L_lambda_simple_code_01f6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f6:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f7
	jmp .L_lambda_simple_end_01f7
.L_lambda_simple_code_01f7:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_01f7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f7:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_001b
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01bb
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02e9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02e9
.L_tc_recycle_frame_done_02e9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01bb
.L_if_else_01bb:
	mov rax, L_constants + 2
.L_if_end_01bb:
.L_or_end_001b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_01f7:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004a
	jmp .L_lambda_opt_end_004a
.L_lambda_opt_code_004a:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ea
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ea
.L_tc_recycle_frame_done_02ea:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_004a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f6:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02eb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02eb
.L_tc_recycle_frame_done_02eb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f5:	; new closure is in rax
	push rax
	push 1
	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f8
	jmp .L_lambda_simple_end_01f8
.L_lambda_simple_code_01f8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f8:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	mov rax, qword [rax]
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var bin>?
	mov rax, qword [rax]
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var bin>=?
	mov rax, qword [rax]
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var bin=?
	mov rax, qword [rax]
	push rax
	push 1
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f8:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ec
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ec
.L_tc_recycle_frame_done_02ec:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(7)
.L_lambda_simple_end_01ee:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01f9
	jmp .L_lambda_simple_end_01f9
.L_lambda_simple_code_01f9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01f9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01f9:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004b
	jmp .L_lambda_opt_end_004b
.L_lambda_opt_code_004b:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ed
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ed
.L_tc_recycle_frame_done_02ed:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_004b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01f9:	; new closure is in rax
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01fa
	jmp .L_lambda_simple_end_01fa
.L_lambda_simple_code_01fa:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fa:
	enter 0, 0
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_71], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fa:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01fb
	jmp .L_lambda_simple_end_01fb
.L_lambda_simple_code_01fb:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fb:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	jne .L_or_end_001c
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01bc
	mov rax, PARAM(0)	; param e
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ee
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ee
.L_tc_recycle_frame_done_02ee:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01bc
.L_if_else_01bc:
	mov rax, L_constants + 2
.L_if_end_01bc:
.L_or_end_001c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fb:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01fc
	jmp .L_lambda_simple_end_01fc
.L_lambda_simple_code_01fc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fc:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004c
	jmp .L_lambda_opt_end_004c
.L_lambda_opt_code_004c:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01bf
	mov rax, L_constants + 0
	jmp .L_if_end_01bf
.L_if_else_01bf:
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01bd
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01bd
.L_if_else_01bd:
	mov rax, L_constants + 2
.L_if_end_01bd:
	cmp rax, sob_boolean_false
	je .L_if_else_01be
	mov rax, PARAM(1)	; param xs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01be
.L_if_else_01be:
	mov rax, L_constants + 2591
	push rax
	mov rax, L_constants + 2582
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
.L_if_end_01be:
.L_if_end_01bf:
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01fd
	jmp .L_lambda_simple_end_01fd
.L_lambda_simple_code_01fd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fd:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ef
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ef
.L_tc_recycle_frame_done_02ef:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fd:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f0
.L_tc_recycle_frame_done_02f0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_004c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fc:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01fe
	jmp .L_lambda_simple_end_01fe
.L_lambda_simple_code_01fe:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01fe:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004d
	jmp .L_lambda_opt_end_004d
.L_lambda_opt_code_004d:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c2
	mov rax, L_constants + 4
	jmp .L_if_end_01c2
.L_if_else_01c2:
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c0
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01c0
.L_if_else_01c0:
	mov rax, L_constants + 2
.L_if_end_01c0:
	cmp rax, sob_boolean_false
	je .L_if_else_01c1
	mov rax, PARAM(1)	; param chs
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01c1
.L_if_else_01c1:
	mov rax, L_constants + 2652
	push rax
	mov rax, L_constants + 2643
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
.L_if_end_01c1:
.L_if_end_01c2:
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_01ff
	jmp .L_lambda_simple_end_01ff
.L_lambda_simple_code_01ff:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_01ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_01ff:
	enter 0, 0
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f1
.L_tc_recycle_frame_done_02f1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01ff:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f2
.L_tc_recycle_frame_done_02f2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_004d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_01fe:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0200
	jmp .L_lambda_simple_end_0200
.L_lambda_simple_code_0200:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0200
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0200:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0201
	jmp .L_lambda_simple_end_0201
.L_lambda_simple_code_0201:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0201
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0201:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c3
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f3
.L_tc_recycle_frame_done_02f3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c3
.L_if_else_01c3:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0202
	jmp .L_lambda_simple_end_0202
.L_lambda_simple_code_0202:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0202
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0202:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0202:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f4
.L_tc_recycle_frame_done_02f4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01c3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0201:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0203
	jmp .L_lambda_simple_end_0203
.L_lambda_simple_code_0203:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0203
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0203:
	enter 0, 0
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f5
.L_tc_recycle_frame_done_02f5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0203:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0200:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0204
	jmp .L_lambda_simple_end_0204
.L_lambda_simple_code_0204:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0204
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0204:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0205
	jmp .L_lambda_simple_end_0205
.L_lambda_simple_code_0205:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0205
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0205:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c4
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f6
.L_tc_recycle_frame_done_02f6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c4
.L_if_else_01c4:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0206
	jmp .L_lambda_simple_end_0206
.L_lambda_simple_code_0206:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0206
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0206:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0206:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f7
.L_tc_recycle_frame_done_02f7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01c4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0205:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0207
	jmp .L_lambda_simple_end_0207
.L_lambda_simple_code_0207:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0207
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0207:
	enter 0, 0
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f8
.L_tc_recycle_frame_done_02f8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0207:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0204:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_88], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004e
	jmp .L_lambda_opt_end_004e
.L_lambda_opt_code_004e:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02f9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02f9
.L_tc_recycle_frame_done_02f9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_004e:	; new closure is in rax
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0208
	jmp .L_lambda_simple_end_0208
.L_lambda_simple_code_0208:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0208
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0208:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0209
	jmp .L_lambda_simple_end_0209
.L_lambda_simple_code_0209:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0209
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0209:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c5
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02fa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02fa
.L_tc_recycle_frame_done_02fa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c5
.L_if_else_01c5:
	mov rax, L_constants + 1
.L_if_end_01c5:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0209:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020a
	jmp .L_lambda_simple_end_020a
.L_lambda_simple_code_020a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020a:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02fb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02fb
.L_tc_recycle_frame_done_02fb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0208:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020b
	jmp .L_lambda_simple_end_020b
.L_lambda_simple_code_020b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020b:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020c
	jmp .L_lambda_simple_end_020c
.L_lambda_simple_code_020c:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_020c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020c:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c6
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02fc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02fc
.L_tc_recycle_frame_done_02fc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c6
.L_if_else_01c6:
	mov rax, L_constants + 1
.L_if_end_01c6:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_020c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020d
	jmp .L_lambda_simple_end_020d
.L_lambda_simple_code_020d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020d:
	enter 0, 0
	mov rax, PARAM(0)	; param v
	push rax
	push 1
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02fd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02fd
.L_tc_recycle_frame_done_02fd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020b:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020e
	jmp .L_lambda_simple_end_020e
.L_lambda_simple_code_020e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020e:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 0
	mov rax, qword [free_var_122]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02fe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02fe
.L_tc_recycle_frame_done_02fe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020e:	; new closure is in rax
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_020f
	jmp .L_lambda_simple_end_020f
.L_lambda_simple_code_020f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_020f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_020f:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2232
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_02ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_02ff
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_02ff
.L_tc_recycle_frame_done_02ff:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_020f:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0210
	jmp .L_lambda_simple_end_0210
.L_lambda_simple_code_0210:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0210
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0210:
	enter 0, 0
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0300:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0300
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0300
.L_tc_recycle_frame_done_0300:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0210:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0211
	jmp .L_lambda_simple_end_0211
.L_lambda_simple_code_0211:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0211
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0211:
	enter 0, 0
	mov rax, L_constants + 2868
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0301:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0301
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0301
.L_tc_recycle_frame_done_0301:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0211:	; new closure is in rax
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0212
	jmp .L_lambda_simple_end_0212
.L_lambda_simple_code_0212:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0212
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0212:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_78]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0302:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0302
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0302
.L_tc_recycle_frame_done_0302:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0212:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0213
	jmp .L_lambda_simple_end_0213
.L_lambda_simple_code_0213:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0213
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0213:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_98]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c7
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0303:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0303
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0303
.L_tc_recycle_frame_done_0303:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c7
.L_if_else_01c7:
	mov rax, PARAM(0)	; param x
.L_if_end_01c7:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0213:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0214
	jmp .L_lambda_simple_end_0214
.L_lambda_simple_code_0214:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0214
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0214:
	enter 0, 0
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c8
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01c8
.L_if_else_01c8:
	mov rax, L_constants + 2
.L_if_end_01c8:
	cmp rax, sob_boolean_false
	je .L_if_else_01d4
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01c9
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0304:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0304
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0304
.L_tc_recycle_frame_done_0304:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01c9
.L_if_else_01c9:
	mov rax, L_constants + 2
.L_if_end_01c9:
	jmp .L_if_end_01d4
.L_if_else_01d4:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01cb
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ca
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01ca
.L_if_else_01ca:
	mov rax, L_constants + 2
.L_if_end_01ca:
	jmp .L_if_end_01cb
.L_if_else_01cb:
	mov rax, L_constants + 2
.L_if_end_01cb:
	cmp rax, sob_boolean_false
	je .L_if_else_01d3
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0305:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0305
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0305
.L_tc_recycle_frame_done_0305:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d3
.L_if_else_01d3:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01cd
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01cc
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01cc
.L_if_else_01cc:
	mov rax, L_constants + 2
.L_if_end_01cc:
	jmp .L_if_end_01cd
.L_if_else_01cd:
	mov rax, L_constants + 2
.L_if_end_01cd:
	cmp rax, sob_boolean_false
	je .L_if_else_01d2
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_120]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0306:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0306
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0306
.L_tc_recycle_frame_done_0306:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d2
.L_if_else_01d2:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01ce
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01ce
.L_if_else_01ce:
	mov rax, L_constants + 2
.L_if_end_01ce:
	cmp rax, sob_boolean_false
	je .L_if_else_01d1
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0307:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0307
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0307
.L_tc_recycle_frame_done_0307:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d1
.L_if_else_01d1:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01cf
	mov rax, PARAM(1)	; param e2
	push rax
	push 1
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	jmp .L_if_end_01cf
.L_if_else_01cf:
	mov rax, L_constants + 2
.L_if_end_01cf:
	cmp rax, sob_boolean_false
	je .L_if_else_01d0
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_70]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0308:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0308
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0308
.L_tc_recycle_frame_done_0308:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d0
.L_if_else_01d0:
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0309:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0309
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0309
.L_tc_recycle_frame_done_0309:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01d0:
.L_if_end_01d1:
.L_if_end_01d2:
.L_if_end_01d3:
.L_if_end_01d4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0214:	; new closure is in rax
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0215
	jmp .L_lambda_simple_end_0215
.L_lambda_simple_code_0215:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0215
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0215:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01d6
	mov rax, L_constants + 2
	jmp .L_if_end_01d6
.L_if_else_01d6:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01d5
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030a
.L_tc_recycle_frame_done_030a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d5
.L_if_else_01d5:
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_34]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030b
.L_tc_recycle_frame_done_030b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01d5:
.L_if_end_01d6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0215:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0216
	jmp .L_lambda_simple_end_0216
.L_lambda_simple_code_0216:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0216
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0216:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0217
	jmp .L_lambda_simple_end_0217
.L_lambda_simple_code_0217:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0217
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0217:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01d7
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_01d7
.L_if_else_01d7:
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0218
	jmp .L_lambda_simple_end_0218
.L_lambda_simple_code_0218:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0218
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0218:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030c
.L_tc_recycle_frame_done_030c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0218:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030d
.L_tc_recycle_frame_done_030d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01d7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0217:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0219
	jmp .L_lambda_simple_end_0219
.L_lambda_simple_code_0219:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0219
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0219:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01d8
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 5 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030e
.L_tc_recycle_frame_done_030e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01d8
.L_if_else_01d8:
	mov rax, PARAM(1)	; param i
.L_if_end_01d8:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0219:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_004f
	jmp .L_lambda_opt_end_004f
.L_lambda_opt_code_004f:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_030f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_030f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_030f
.L_tc_recycle_frame_done_030f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_004f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0216:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021a
	jmp .L_lambda_simple_end_021a
.L_lambda_simple_code_021a:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_021a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021a:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021b
	jmp .L_lambda_simple_end_021b
.L_lambda_simple_code_021b:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_021b
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021b:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01d9
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_01d9
.L_if_else_01d9:
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021c
	jmp .L_lambda_simple_end_021c
.L_lambda_simple_code_021c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021c:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0310:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0310
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0310
.L_tc_recycle_frame_done_0310:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021c:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0311:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0311
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0311
.L_tc_recycle_frame_done_0311:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01d9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_021b:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021d
	jmp .L_lambda_simple_end_021d
.L_lambda_simple_code_021d:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_021d
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021d:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01da
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 5 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0312:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0312
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0312
.L_tc_recycle_frame_done_0312:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01da
.L_if_else_01da:
	mov rax, PARAM(1)	; param i
.L_if_end_01da:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_021d:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0050
	jmp .L_lambda_opt_end_0050
.L_lambda_opt_code_0050:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0313:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0313
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0313
.L_tc_recycle_frame_done_0313:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0050:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_021a:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021e
	jmp .L_lambda_simple_end_021e
.L_lambda_simple_code_021e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021e:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_113]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0314:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0314
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0314
.L_tc_recycle_frame_done_0314:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021e:	; new closure is in rax
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_021f
	jmp .L_lambda_simple_end_021f
.L_lambda_simple_code_021f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_021f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_021f:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0315:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0315
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0315
.L_tc_recycle_frame_done_0315:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_021f:	; new closure is in rax
	mov qword [free_var_128], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0220
	jmp .L_lambda_simple_end_0220
.L_lambda_simple_code_0220:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0220
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0220:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0221
	jmp .L_lambda_simple_end_0221
.L_lambda_simple_code_0221:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0221
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0221:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01db
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0222
	jmp .L_lambda_simple_end_0222
.L_lambda_simple_code_0222:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0222
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0222:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0316:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0316
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0316
.L_tc_recycle_frame_done_0316:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0222:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0317:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0317
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0317
.L_tc_recycle_frame_done_0317:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01db
.L_if_else_01db:
	mov rax, PARAM(0)	; param str
.L_if_end_01db:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0221:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0223
	jmp .L_lambda_simple_end_0223
.L_lambda_simple_code_0223:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0223
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0223:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0224
	jmp .L_lambda_simple_end_0224
.L_lambda_simple_code_0224:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0224
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0224:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01dc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_01dc
.L_if_else_01dc:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0318:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0318
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0318
.L_tc_recycle_frame_done_0318:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01dc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0224:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0319:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0319
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0319
.L_tc_recycle_frame_done_0319:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0223:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0220:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0225
	jmp .L_lambda_simple_end_0225
.L_lambda_simple_code_0225:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0225
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0225:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0226
	jmp .L_lambda_simple_end_0226
.L_lambda_simple_code_0226:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0226
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0226:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01dd
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0227
	jmp .L_lambda_simple_end_0227
.L_lambda_simple_code_0227:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0227
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0227:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031a
.L_tc_recycle_frame_done_031a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0227:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031b
.L_tc_recycle_frame_done_031b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01dd
.L_if_else_01dd:
	mov rax, PARAM(0)	; param vec
.L_if_end_01dd:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0226:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0228
	jmp .L_lambda_simple_end_0228
.L_lambda_simple_code_0228:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0228
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0228:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push 1
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0229
	jmp .L_lambda_simple_end_0229
.L_lambda_simple_code_0229:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0229
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0229:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01de
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_01de
.L_if_else_01de:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 3 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031c
.L_tc_recycle_frame_done_031c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01de:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0229:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031d
.L_tc_recycle_frame_done_031d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0228:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0225:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022a
	jmp .L_lambda_simple_end_022a
.L_lambda_simple_code_022a:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_022a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022a:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022b
	jmp .L_lambda_simple_end_022b
.L_lambda_simple_code_022b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022b:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022c
	jmp .L_lambda_simple_end_022c
.L_lambda_simple_code_022c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022c:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01df
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031e
.L_tc_recycle_frame_done_031e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01df
.L_if_else_01df:
	mov rax, L_constants + 1
.L_if_end_01df:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022c:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_031f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_031f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_031f
.L_tc_recycle_frame_done_031f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022b:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0320:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0320
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0320
.L_tc_recycle_frame_done_0320:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_022a:	; new closure is in rax
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022d
	jmp .L_lambda_simple_end_022d
.L_lambda_simple_code_022d:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_022d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022d:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022e
	jmp .L_lambda_simple_end_022e
.L_lambda_simple_code_022e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022e:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_022f
	jmp .L_lambda_simple_end_022f
.L_lambda_simple_code_022f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_022f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_022f:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0230
	jmp .L_lambda_simple_end_0230
.L_lambda_simple_code_0230:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0230
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0230:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01e0
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0321:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0321
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0321
.L_tc_recycle_frame_done_0321:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01e0
.L_if_else_01e0:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_01e0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0230:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0322:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0322
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0322
.L_tc_recycle_frame_done_0322:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022f:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0323:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0323
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0323
.L_tc_recycle_frame_done_0323:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_022e:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0324:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0324
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0324
.L_tc_recycle_frame_done_0324:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_022d:	; new closure is in rax
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0231
	jmp .L_lambda_simple_end_0231
.L_lambda_simple_code_0231:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0231
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0231:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0232
	jmp .L_lambda_simple_end_0232
.L_lambda_simple_code_0232:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0232
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0232:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0233
	jmp .L_lambda_simple_end_0233
.L_lambda_simple_code_0233:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0233
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0233:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0234
	jmp .L_lambda_simple_end_0234
.L_lambda_simple_code_0234:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0234
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0234:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01e1
	mov rax, PARAM(0)	; param i
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]

	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0325:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0325
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0325
.L_tc_recycle_frame_done_0325:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01e1
.L_if_else_01e1:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_01e1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0234:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0326:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0326
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0326
.L_tc_recycle_frame_done_0326:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0233:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0327:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0327
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0327
.L_tc_recycle_frame_done_0327:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0232:	; new closure is in rax
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0328:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0328
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0328
.L_tc_recycle_frame_done_0328:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0231:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0235
	jmp .L_lambda_simple_end_0235
.L_lambda_simple_code_0235:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0235
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0235:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01e4
	mov rax, L_constants + 3192
	jmp .L_if_end_01e4
.L_if_else_01e4:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01e3
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 3192
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_0329:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0329
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0329
.L_tc_recycle_frame_done_0329:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	jmp .L_if_end_01e3
.L_if_else_01e3:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	cmp rax, sob_boolean_false
	je .L_if_else_01e2
	mov rax, L_constants + 3192
	jmp .L_if_end_01e2
.L_if_else_01e2:
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
	push rax
	mov rax, L_constants + 3192
	push rax
	push 2
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 2 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_032a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_032a
.L_tc_recycle_frame_done_032a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
.L_if_end_01e2:
.L_if_end_01e3:
.L_if_end_01e4:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0235:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0236
	jmp .L_lambda_simple_end_0236
.L_lambda_simple_code_0236:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0236
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0236:
	enter 0, 0
	mov rax, L_constants + 3217
	push rax
	push 1
	mov rax, qword [free_var_134]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	push qword [rbp + 8*1]
	push qword [rbp + 8*0]
	mov rcx, 1 + 4
	mov rbx, qword [rbp + 8 * 3]
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_032b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_032b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_032b
.L_tc_recycle_frame_done_032b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	;
	jmp [rax + 1 + 8 * 1]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0236:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0237
	jmp .L_lambda_simple_end_0237
.L_lambda_simple_code_0237:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0237
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0237:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0237:	; new closure is in rax
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 3310
	push rax
	mov rax, L_constants + 3232
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push qword [rax + 1]
	call qword [rax + 1 + 8]
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

;;; r8 : params
;;; r9 : | env |
extend_lexical_environment:
        mov rcx, r8
        lea rdi, [rcx * 8]
        call malloc
        lea rsi, [rbp + 8*4]    ;; source
        lea rdi, [rax]          ;; new Env pointer
        cld
        rep movsq               ;; copy old env into the new pointer
        mov r10, rax
        lea rdi, [r9*8 +8*1]     ;; size of new env
        call malloc
        mov qword [rax],  r10 ;; new env pointer
        mov rsi, qword [rbp + 8*2]
        lea rdi, [rax + 8] ;; new lexical env
        mov rcx, r9
        cld
        rep movsq
        ret

;;; fixing the stack
;;; R9 : List.length params'
opt_fix_stack:
        mov rcx, qword [rsp + 8*3] 	; count
        cmp rcx, r9
        jl L_error_arg_count_2
        jg .Lmore
        mov rsi, rsp
        sub rsp, 8*1
        mov rdi, rsp
        add rcx, 4
        cld
        rep movsq
        inc qword [rsp + 8*3] 		; ++count
        mov qword [rsp + 8*r9 + 8*4], sob_nil
        jmp .Ldone
.Lmore:
        mov rbx, [rsp + 8*3] 		; how many were pushed
        lea r11, [rsp + 8*rbx + 8*3] 	; ptr to top element in the frame
        mov r10, sob_nil     		; initial argl
        mov r12, r11			; backup ptr to top element
        sub rcx, r9			; size of list
.L0:
        cmp rcx, 0
        je .L0out
        mov rdi, 1 + 8 + 8 		; sizeof(pair)
        call malloc
        mov byte [rax], T_pair 		; rtti
        mov qword [rax + 1 + 8], r10 	; cdr
        mov rbx, qword [r11]
        mov qword [rax + 1], rbx 	; car
        mov r10, rax
        sub r11, 8*1
        dec rcx
        jmp .L0
.L0out:
        mov qword [r12], r10 		; set list
        lea rdi, [r12 - 8*1]
        lea rsi, [rsp + 8*r9 + 8*3]
        mov rcx, r9
        add rcx, 4
        std
        rep movsq
        cld
        lea rsp, [rdi + 8*1]
        lea rbx, [r9 + 1]
        mov qword [rsp + 8*3], rbx
.Ldone:
        ret

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        cmp qword [rsp + 8*2], 2
        jne L_error_arg_count_2
        mov r8, qword [rsp + 8*3]       ;; the procedure [arg 0]
        assert_closure(r8)
        lea r9, [rsp + 8*4]             ;; the address of the arg list [arg 1]
        mov r10, qword [r9]             ;; the arg list
        mov r11, [rsp]                  ;; the return address
        mov rcx, 0
        mov rsi, r10
    .L_list_length:
        cmp byte [rsi], T_nil
        je .L_list_length_done
        assert_pair(rsi)
        inc rcx
        mov rsi, SOB_PAIR_CDR(rsi)      ;;TODO: check if we need to move into rsi or rdi
        jmp .L_list_length
    .L_list_length_done:
        lea rbx, [8 * (rcx - 2)]     
        sub rsp, rbx                    ;; Move Stack Pointer DOWN to make room for N arguments
        mov rdi, rsp                    ;; rdi = dest (top of the stack)                   
        mov rax, r11                    ;; rax = src (the return address)
        cld
        stosq                           ;; copy the return address into the top of the stack and update the pointer
        mov rax, qword [r8+1]           ;; rax = src (lexical env)
        stosq                           ;; copy the lexical environment into the stack and update the pointer
        mov rax, rcx                    ;; rax = src (number of args)
        stosq                           ;; copy the number of args into the stack and update the pointer
    .L_copy_args:
        cmp rcx, 0
        je .L_args_copied
        mov rax, SOB_PAIR_CAR(r10)      ;; Load Value (e.g., 5) into RAX
        stosq                          ;; copy the argument into the stack and update the pointer     
        mov r10, SOB_PAIR_CDR(r10)      ;;the iteration step
        dec rcx
        jmp .L_copy_args
    .L_args_copied:
        jmp [r8 + 1 + 1 * 8 ]


L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`

section .note.GNU-stack
        
