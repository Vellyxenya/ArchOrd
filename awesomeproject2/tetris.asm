  ;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
  .equ LEDS, 0x2000                 ; LED address
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ BUTTONS, 0x2030              ; Buttons addresses

  ;; type enumeration
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04

  ;; GSA type
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

  ;; orientation enumeration
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4

  ;; collision boundaries
  .equ COL_X, 4
  .equ COL_Y, 3

  ;; Rotation enumeration
  .equ CLOCKWISE, 0
  .equ COUNTERCLOCKWISE, 1

  ;; Button enumeration
  .equ moveL, 0x01
  .equ rotL, 0x02
  .equ reset, 0x04
  .equ rotR, 0x08
  .equ moveR, 0x10
  .equ moveD, 0x20

  ;; Collision return ENUM
  .equ W_COL, 0
  .equ E_COL, 1
  .equ So_COL, 2
  .equ OVERLAP, 3
  .equ NONE, 4

  ;; start location
  .equ START_X, 6
  .equ START_Y, 1

  ;; game rate of tetrominoe falling down (in terms of game loop iteration)
  .equ RATE, 5

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8 

; BEGIN:main
main:
	;init stack
	addi sp, zero, 0x2000
	start_game:
		addi s0, zero, RATE
		call reset_game
		start_descending:
			continue_falling:
				add s1, zero, zero				; i counter
				loop_over_rate:
					bge s1, s0, go_down			; if i >= RATE
					call draw_gsa
					call display_score
					addi a0, zero, NOTHING		; set erase mode
					call draw_tetromino			; remove tetromino from GSA
					call wait
					call get_input
					beq v0, zero, redraw		; if no action is required, simply redraw
					add a0, zero, v0			; else set arg of act
					call act					; and try to perform required action
					redraw:
					addi a0, zero, FALLING		; set falling mode
					call draw_tetromino			; re-add the tetromino to the GSA
					addi s1, s1, 1				; increment counter
					jmpi loop_over_rate
				go_down:
				addi a0, zero, NOTHING
				call draw_tetromino				; remove tetromino from GSA
				addi a0, zero, moveD
				call act						; try to move down
				bne v0, zero, bottom_reached	; zero is success, 1 is fail. If !0, we reached bottom
				addi a0, zero, FALLING			; else ...
				call draw_tetromino				; draw tetromino and ...
				jmpi continue_falling			; loop again.
			bottom_reached:
			addi a0, zero, PLACED
			call draw_tetromino					; once bottom reached, replace falling tetromino by PLACED one
			handle_full_lines:
			call detect_full_line
			addi s2, zero, 8
			beq v0, s2, next_tetromino			; if no more full lines continue by generating next tetromino
			add a0, zero, v0					; else set the line we want to remove
			call remove_full_line				; and remove it
			call increment_score
			jmpi handle_full_lines				; re-check if there is any more full lines
			next_tetromino:
			call generate_tetromino
			addi s3, zero, OVERLAP			
			add a0, zero, s3					; we want to check for overlap as it would imply Game Over
			call detect_collision				; check if there is an overlap collision

			beq v0, s3, start_game				; if there is, Game Over, restart the game
			addi a0, zero, FALLING
			call draw_tetromino					; else draw tetromino
			jmpi start_descending				; and start the descent
; END:main


; BEGIN:helper
direct_switch:
	; takes args a0, a1, and a2 and modifies them accordingly
	addi t0, zero, 0					; init s3 to 0
	beq a2, t0, west_adapt				; if collisionType = 0, we check west side
	addi t0, t0, 1
	beq a2, t0, east_adapt				; else if collisionType = 1, we check east side
	addi t0, t0, 1
	beq a2, t0, south_adapt				; else if collisionType = 2, we check south side
	jmpi end_direct_switch				; else the collisionType is an OVERLAP and we don't have to do any shifting
										; we will only check the current position
west_adapt:
	addi a0, a0, -1						; we check the cell on the left of current cell
	jmpi end_direct_switch
east_adapt:
	addi a0, a0, 1						; we check the cell on the right of current cell
	jmpi end_direct_switch
south_adapt:
	addi a1, a1, 1						; we check the cell below the current cell
	jmpi end_direct_switch

end_direct_switch:
	ret
; END:helper


; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS+0(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
	ret
; END:clear_leds


; BEGIN:set_pixel
set_pixel:
	slli t0, a0, 3 						; x*8
	add  t0, a1, t0 					; +y
	srli t1, t0, 5  					; t1/32
	slli t1, t1, 2  					; t1*4
	andi t2, t0, 31 					; modulo 32 sur 8x+y
	ldw  t3, LEDS(t1) 					; charger led(0,1,2)
	addi t4, zero, 1 					; initialise mask à 1
	sll  t4, t4, t2 					; shift 1 de bits nécessaire
	or   t3, t4, t3 					; allumer le bit
	stw  t3, LEDS(t1) 					; enregistrer dans bon led
	ret
; END:set_pixel


; BEGIN:wait
wait:
	addi t0, zero, 1
	slli t0, t0, 20						; init t0 to 2 ^ 20
	loop:
		addi t0, t0, -1					; t--
		bne t0, zero, loop				; while t!=0 loop
	ret
; END:wait


; BEGIN:get_input
get_input:
	add v0, zero, zero					; default return value
	ldw t0, BUTTONS+4(zero)				; get edgecapture
	andi t0, t0, 0x1F					; get only 5 LSB from edgecapture
	beq t0, zero, end_get_input			; if no button pressed, return 0
	
	addi t1, zero, 1					; mask 1
	addi t3, zero, 5					; loop counter

loop_over_buttons:
	beq t3, zero, end_get_input			; checked all buttons, if none is pressed, return 0
	and t2, t0, t1						; edgecapture & mask
	slli t1, t1, 1						; shift the mask to the left
	addi t3, t3, -1						; decrement counter
	beq t2, zero, loop_over_buttons		; if current button not pressed, continue looping
		
	srli t1, t1, 1						; else reposition the mask
	add v0, zero, t1					; put the mask value in return value

end_get_input:
	stw zero, BUTTONS+4(zero)			; clear edgecapture
	ret
; END:get_input


; BEGIN:get_gsa
get_gsa:
	slli t0, a0, 3 						; x*8
	add  t0, a1, t0 					; +y
	slli t0, t0, 2  					; t0*4
	ldw  v0, GSA(t0) 					; charger GSA(0...95)
	ret
; END:get_gsa


; BEGIN:set_gsa
set_gsa:
	slli t0, a0, 3 						; x*8
	add  t0, a1, t0 					; +y
	slli t0, t0, 2  					; t0*4
	stw  a2, GSA(t0) 					; écrire dans GSA(0...95)
	ret
; END:set_gsa


; BEGIN:in_gsa
in_gsa:
	cmplti t0, a0, 0					; x<0
	cmplti t1, a1, 0					; y<0
	cmpgei t2, a0, X_LIMIT				; x>11
	cmpgei t3, a1, Y_LIMIT				; y>7	
	or v0, t0, t1
	or v0, v0, t2
	or v0, v0, t3
	ret
; END:in_gsa


; BEGIN:generate_tetromino
generate_tetromino:

loop_random:
	ldw t0, RANDOM_NUM(zero)			; get random int
	addi t1, zero, 7					; create a mask 0b0..0111
	and t0, t0, t1						; get 3 LSB bits
	cmplti t2, t0, 5					; t2 = 1 if t0 < 5
	beq t2, zero, loop_random			; if t2 >= 5, generate a new random number

	addi a0, zero, 6					; init position-x
	addi a1, zero, 1					; init position-y
	stw a0, T_X(zero)					; set x-position arg
	stw a1, T_Y(zero)					; set y-position arg
	addi t3, zero, N					
	stw t3, T_orientation(zero)			; set orientation to North
	stw t0, T_type(zero)				; set type to that obtained randomly

	ret
; END:generate_tetromino


; BEGIN:display_score
display_score:
	ldw t0, SCORE(zero)					; load score
	ldw t3, font_data(zero)
	add t1, zero, zero					; loop_counter
	addi t2, zero, 1000					; the decrement_amount
loop_thousands:
	sub t0, t0, t2						; t0 - amount
	addi t1, t1, 1						; increment counter
	bge t0, zero, loop_thousands		; if result is still bigger than 0, loop
	addi t1, t1, -1						; else adjust counter
	add t0, t0, t2						; adjust value so that it's bigger than 0 again
	slli t1, t1, 2						; t2 * 4 for word alignment
	ldw t3, font_data(t1)
	stw t3, SEVEN_SEGS(zero)			; store the hundreds
	add t1, zero, zero
	addi t2, zero, 100					; the decrement_amount
loop_hundreds:
	sub t0, t0, t2						; t0 - amount
	addi t1, t1, 1						; increment counter
	bge t0, zero, loop_hundreds			; if result is still bigger than 0, loop
	addi t1, t1, -1						; else adjust counter
	add t0, t0, t2						; adjust value so that it's bigger than 0 again
	slli t1, t1, 2						; t2 * 4 for word alignment
	ldw t3, font_data(t1)
	stw t3, SEVEN_SEGS+4(zero)			; store the hundreds
	add t1, zero, zero
	addi t2, zero, 10					; the decrement_amount
loop_tens:
	sub t0, t0, t2
	addi t1, t1, 1
	bge t0, zero, loop_tens
	addi t1, t1, -1
	add t0, t0, t2
	slli t1, t1, 2						; t2 * 4 for word alignment
	ldw t3, font_data(t1)
	stw t3, SEVEN_SEGS+8(zero)			; store the tens
	slli t0, t0, 2						; t0 * 4 for word alignment
	ldw t3, font_data(t0)
	stw t3, SEVEN_SEGS+12(zero)			; store the unities
	ret
; END:display_score


; BEGIN:reset_game
reset_game:
	addi sp, sp, -4
	stw ra, 0(sp)
	stw zero, SCORE(zero)				; init score to 0
	call display_score
	addi t0, zero, 384					; init counter to 96 * 4

loop_over_cells:						; reset all gsa locations
	addi t0, t0, -4
	stw zero, GSA(t0)
	bne t0, zero, loop_over_cells

	call generate_tetromino
	addi a0, zero, FALLING				; set type arg {NOTHING, PLACED or FALLING}
	call draw_tetromino					; draw the tetromino
	call draw_gsa

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:reset_game


; BEGIN:detect_full_line
detect_full_line:
	addi sp, sp, -12
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	add s0, zero, zero
	add s1, zero, zero

loop_df:
	add a0, s0, zero
	add a1, s1, zero
	call get_gsa
	cmpeqi t0, v0, PLACED
	bne t0, zero, next_x				; while gsa(x,y)=1, check next x
	cmpeqi t2, s1, 7					; case gsa(x,y)!=1, check if this is last y
	bne t2, zero, no_full				; if y=7, return v0=8
next_y:
	add s0, zero, zero					; initialize x to 0
	addi s1, s1, 1						; pass to next row
	jmpi loop_df
next_x:
	cmpeqi t1, s0, 11					; if x=11
	bne t1, zero, full_found
	addi s0, s0, 1						; increment x-coordinate
	jmpi loop_df

full_found:
	add v0, s1, zero					; return the coordinate of highest full line
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	addi sp, sp, 12
	ret
no_full:
	addi v0, zero, 8
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	addi sp, sp, 12
	ret
; END:detect_full_line


; BEGIN:remove_full_line
remove_full_line:
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	add s1, a0, zero					; stock coordinate y
	add s2, zero, zero					; counter on/off

	loop_blink:

		add s0, zero, zero					; initialize x
	
		loop_bx:

			add a0, s0, zero
			add a1, s1, zero
			andi a2, s2, 1					;extract lsb -> state of gsa

			call set_gsa

			addi s0, s0, 1
			cmpeqi t1, s0, X_LIMIT				; if x>11
			beq t1, zero, loop_bx
		call draw_gsa	
		call wait

		addi s2, s2, 1
		cmpeqi t0, s2, 5					; case off for the last time
		beq t0, zero, loop_blink			; not last time, continue blink

	; move down

	add s2, zero, s1						;start at y=s1 (s1 is full line)
	; loop over all 0 < y <= s1
	loop_dy:
		add s0, zero, zero
		
		loop_dx:
				
			; gsa(x,y) = gsa(x,y-1)
			add a0, s0, zero				; a0 contient la coordonnée x
			addi a1, s2, -1					
			call get_gsa
			add a2, v0, zero
			add a0, s0, zero
			add a1, s2, zero
			call set_gsa

			addi s0, s0, 1
			cmpeqi t0, s0, X_LIMIT
			beq t0, zero, loop_dx
			
		addi s2, s2, -1
		bne s2, zero, loop_dy

	; erase line 0
		
	addi s0, zero, X_LIMIT					 ;start at x=12
	loop_disappear:
		addi s0, s0, -1						

		add a0, zero, s0
		add a1, zero, zero
		addi a2, zero, NOTHING				;set state to 0
		call set_gsa

		bne s0, zero, loop_disappear
	
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	addi sp, sp, -16
	ret
; END:remove_full_line


; BEGIN:increment_score
increment_score:
	ldw t0, SCORE(zero)					; load score
	addi t0, t0, 1						; increment by 1
	stw t0, SCORE(zero)					; store score
	addi t1, zero, 10000
	bne t0, t1, end_increment			; if score >= 10000
	stw zero, SCORE(zero)				; reset score to 0
end_increment:
	ret
; END:increment_score


; BEGIN:act
act:
	addi sp, sp, -16
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	add s0, zero, a0					; put value of action in s0
	ldw s1, T_X(zero)					; save x location
	ldw s2, T_orientation(zero)			; save orientation

	andi t0, s0, 1
	bne t0, zero, move_left

	srli s0, s0, 1
	andi t0, s0, 1
	bne t0, zero, rotate_left

	srli s0, s0, 1
	andi t0, s0, 1
	bne t0, zero, reset_action

	srli s0, s0, 1
	andi t0, s0, 1
	bne t0, zero, rotate_right

	srli s0, s0, 1
	andi t0, s0, 1
	bne t0, zero, move_right

	srli s0, s0, 1
	andi t0, s0, 1

	;;move_down
	addi a0, zero, So_COL
	call detect_collision
	cmpeqi t0, v0, NONE						;if v0 =none, t0=1
	addi v0, zero, 1						;set v0=1
	beq t0, zero, end_act					;v0!=none -> collision
	addi v0, v0, -1							; no collision, set v0=0
	ldw t1, T_Y(zero)
	addi t1, t1, 1							; T_Y= T_Y+1
	stw t1, T_Y(zero)
	jmpi end_act

	move_left:
	addi a0, zero, W_COL
	call detect_collision
	cmpeqi t0, v0, NONE						;if v0 =none, t0=1
	addi v0, zero, 1						;set v0=1
	beq t0, zero, end_act					;v0!=none -> collision
	addi v0, v0, -1							; no collision, set v0=0
	ldw t1, T_X(zero)
	addi t1, t1, -1							; T_X= T_X-1
	stw t1, T_X(zero)
	jmpi end_act

	rotate_left:
	addi a0, zero, rotL
	br try_rotate

	reset_action:
	call reset_game
	jmpi end_act

	move_right:
	addi a0, zero, E_COL
	call detect_collision
	cmpeqi t0, v0, NONE						;if v0 =none, t0=1
	addi v0, zero, 1						;set v0=1
	beq t0, zero, end_act					;v0!=none -> collision
	addi v0, v0, -1							; no collision, set v0=0
	ldw t1, T_X(zero)
	addi t1, t1, 1							; T_X= T_X+1
	stw t1, T_X(zero)
	jmpi end_act

	rotate_right:
	addi a0, zero, rotR

	try_rotate:
	call rotate_tetromino
	addi a0, zero, OVERLAP
	call detect_collision
	addi t7, zero, NONE
	beq v0, t7, rotate_success
	
	addi t6, zero, START_X
	addi t5, zero, 1					; t5 = shift
	blt s1, t6, start_shift				; if initial x < 6
	addi t5, t5, -2						; else to the left

	start_shift:
	ldw t4, T_X(zero)
	add t4, t4, t5
	stw t4, T_X(zero)
	beq v0, t7, end_act

	addi a0, zero, OVERLAP
	call detect_collision
	addi t7, zero, NONE
	beq v0, t7, rotate_success

	addi t6, zero, START_X
	addi t5, zero, 1					; t5 = shift
	blt s1, t6, continue_shift			; if initial x < 6
	addi t5, t5, -2						; else to the left

	continue_shift:
	ldw t4, T_X(zero)
	add t4, t4, t5
	stw t4, T_X(zero)
	beq v0, t7, end_act

	addi a0, zero, OVERLAP
	call detect_collision
	addi t7, zero, NONE
	bne v0, t7, fail_rotation

	rotate_success:
	add v0, zero, zero
	br end_act

	;; if here, there is still collision, so reload
	fail_rotation:
	stw s1, T_X(zero)					; reset initial x-position
	stw s2, T_orientation(zero)			; reset initial rotation
	addi v0, zero, 1

	end_act:
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	addi sp, sp, 16
	ret
; END:act


; BEGIN:rotate_tetromino
rotate_tetromino:
	ldw t0, T_orientation(zero)
	addi t0, t0, 1
	addi t7, zero, rotR
	beq a0, t7, fin_rotate
	addi t0, t0, -2						; rotate counterclockwise
	fin_rotate:
	cmpeqi t1, t0, -1					; if orientation=-1
	bne t1, zero, make_positive
	andi t0, t0, 3
	jmpi store_rotate
	make_positive:
	addi t0, t0, 4
	store_rotate:
	stw t0, T_orientation(zero)
	ret
; END:rotate_tetromino


; BEGIN:detect_collision
detect_collision:
	addi sp, sp, -36
	stw ra, 0(sp)
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s3, 16(sp)
	stw s4, 20(sp)
	stw s5, 24(sp)
	stw s6, 28(sp)
	stw s7, 32(sp)

	ldw s6, T_X(zero)					; s6 = x-coordinate
	ldw s7, T_Y(zero)					; s7 = y-coordinate
	add s3, zero, a0					; s3 = type of collision inquired

	addi s4, zero, PLACED				; s4 contains the value "PLACED"

	ldw s5, T_type(zero)				; get type of tetromino
	slli s5, s5, 2						; s5 * 4
	ldw s1, T_orientation(zero) 	
	add s5, s5, s1						; s5 + T_orientation
	slli s5, s5, 2						; s5 * 4
	
	ldw s1, DRAW_Ax(s5)					; x-addresses array
	ldw s2, DRAW_Ay(s5) 				; y-addresses array
	
	add a0, zero, s6					; put in a0 the anchor's x-coo
	add a1, zero, s7					; put in a1 the anchor's y-coo
	add a2, zero, s3
	call direct_switch					; set le bon paramètre selon direction

	call in_gsa							; check of coordinate is in gsa
	bne v0, zero, end_check				; if coordinate is out of gsa, report a collision

	call get_gsa						; put the gsa value at coos "(a0, a1) + direction" in register v0
	beq v0, s4, end_check				; if value is "PLACED" we immediately report a collision

	ldw a0, 0(s1)						; get elem of x-addresses array
	add a0, a0, s6						; shift x
	ldw a1, 0(s2)						; get elem of y-addresses array
	add a1, a1, s7						; shift y
	add a2, zero, s3
	call direct_switch					; same as above

	call in_gsa
	bne v0, zero, end_check				; if coordinate is out of gsa, report a collision

	call get_gsa
	beq v0, s4, end_check			

	ldw a0, 4(s1)						; same as above for 2nd offset
	add a0, a0, s6
	ldw a1, 4(s2)
	add a1, a1, s7
	add a2, zero, s3
	call direct_switch

	call in_gsa
	bne v0, zero, end_check				; if coordinate is out of gsa, report a collision

	call get_gsa
	beq v0, s4, end_check

	ldw a0, 8(s1)						; same as above for 3rd offset
	add a0, a0, s6
	ldw a1, 8(s2)
	add a1, a1, s7
	add a2, zero, s3
	call direct_switch

	call in_gsa
	bne v0, zero, end_check				; if coordinate is out of gsa, report a collision

	call get_gsa
	beq v0, s4, end_check

	addi v0, zero, NONE					; if we get to this line, then no collision has been detected
	br end_detect_collision
	
;; Old placement of direct_switch, now moved in helper block ;;

end_check:
	add v0, zero, s3					; if we get here, a collision has been detected, so we return the collision type
end_detect_collision:
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s3, 16(sp)
	ldw s4, 20(sp)
	ldw s5, 24(sp)
	ldw s6, 28(sp)
	ldw s7, 32(sp)
	addi sp, sp, 36
	ret
; END:detect_collision


; BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -12	
	stw ra, 0(sp)						; store return address
	stw s0, 4(sp)
	stw s1, 8(sp)

	call clear_leds						; clears the leds before drawing

	addi s0, zero, X_LIMIT				; x counter

	outer:
		addi s0, s0, -1					; s0--
		blt s0, zero, done_drawing_gsa
		addi s1, zero, Y_LIMIT			; y counter

	inner:
		addi s1, s1, -1					; s1--
		blt s1, zero, outer				; if y counter is less than 0 go to outer loop
		add a0, zero, s0
		add a1, zero, s1
		call get_gsa					; get gsa at current a0 and a1
		
		beq v0, zero, inner				; if gsa at (a0, a1) is NOTHING, skip
		add a0, zero, s0
		add a1, zero, s1
		call set_pixel					; else set_pixel(a0, a1)
		
		jmpi inner

	done_drawing_gsa:
		ldw ra, 0(sp)					; load return address
		ldw s0, 4(sp)
		ldw s1, 8(sp)
		addi sp, sp, 12
	ret
; END:draw_gsa


; BEGIN:draw_tetromino
draw_tetromino:
	addi sp, sp, -28				
	stw ra, 0(sp)						; store return address for later
	stw s0, 4(sp)
	stw s1, 8(sp)
	stw s2, 12(sp)
	stw s5, 16(sp)
	stw s6, 20(sp)
	stw s7, 24(sp)

	add s0, zero, a0					; save a0 in s0

	;;draw anchor
	ldw s6, T_X(zero)					; save x coordinate
	ldw s7, T_Y(zero)					; save y coordinate 
	add a0, zero, s6					; set arg a0 for set_gsa
	add a1, zero, s7					; set arg a1 for set_gsa
	add a2, zero, s0					; set arg a2 for set_gsa
	call set_gsa

	;;find array position of given type and orientation
	ldw s5, T_type(zero)				; get type of tetromino
	slli s5, s5, 2						; t5 * 4
	ldw s1, T_orientation(zero) 	
	add s5, s5, s1						; t5 + T_orientation
	slli s5, s5, 2						; t5 * 4
	
	ldw s1, DRAW_Ax(s5)					; x-addresses array
	ldw s2, DRAW_Ay(s5) 				; y-addresses array

	ldw a0, 0(s1)						; get elem of x-addresses array
	add a0, a0, s6						; shift x
	ldw a1, 0(s2)						; get elem of y-addresses array
	add a1, a1, s7						; shift y
	add a2, zero, s0					; set arg a2 for set_gsa
	call set_gsa						; set corresponding GSA position

	ldw a0, 4(s1)						; same as above for 2nd offset
	add a0, a0, s6
	ldw a1, 4(s2)
	add a1, a1, s7
	add a2, zero, s0					; set arg a2 for set_gsa
	call set_gsa

	ldw a0, 8(s1)						; same as above for 3rd offset
	add a0, a0, s6
	ldw a1, 8(s2)
	add a1, a1, s7
	add a2, zero, s0					; set arg a2 for set_gsa
	call set_gsa

	ldw ra, 0(sp)						; reload return address
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s5, 16(sp)
	ldw s6, 20(sp)
	ldw s7, 24(sp)
	addi sp, sp, 28
	ret
; END:draw_tetromino


font_data:
  .word 0xFC  ; 0
  .word 0x60  ; 1
  .word 0xDA  ; 2
  .word 0xF2  ; 3
  .word 0x66  ; 4
  .word 0xB6  ; 5
  .word 0xBE  ; 6
  .word 0xE0  ; 7
  .word 0xFE  ; 8
  .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y