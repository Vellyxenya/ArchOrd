addi t0, zero, 0x0001 	;0000 0000 0000 0001
addi t1, zero, 0x0002   ;0000 0000 0000 0010
addi t5, zero, 0x0005	;0000 0000 0000 0101
addi t7, zero, 0x0007	;0000 0000 0000 0111

br main

addition:
add t0, t0, t0

main:
beq t0, t1, display_five
ble t0, t1, display_seven

display_five:			; should display 10 : 0000 0000 0000 1010
stw t5, 0x2000(zero)
break

display_seven:			; should display  7 : 0000 0000 0000 0111
stw t7, 0x2004(zero)
add t5, t5, t5
bgtu t5, t7, addition
