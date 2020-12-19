addi t0, zero, 0x2F0A 	;0010 1111 0000 1010
addi t1, zero, 0x4F47 	;0100 1111 0100 0111
and t3, t0, t1	      	;0000 1111 0000 0010
stw t3, 0x2004(zero)
ldw t4, 0x2004(zero)
addi t5, zero, 0x7FF0 	;0111 1111 1111 0000
or t6, t4, t5			;0111 1111 1111 0010

addi t7, zero, 0x0001	;0000 0000 0000 0001
srl t6, t6, t7			;0011 1111 1111 1001
stw t6, 0x2008(zero)
break
