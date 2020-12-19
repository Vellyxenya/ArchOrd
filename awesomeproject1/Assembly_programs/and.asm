addi t0, zero, 0x2F0A ;0010 1111 0000 1010
addi t1, zero, 0x4F47 ;0100 1111 0100 0111
and t3, t0, t1	      ;0000 1111 0000 0010
stw t3, 0x2000(zero)
break
