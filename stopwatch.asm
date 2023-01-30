.global _start
.equ ARM_TIM_LOAD_MEMORY, 0xFFFEC600
.equ ARM_TIM_CURRVAL_MEMORY, 0xFFFEC604
.equ ARM_TIME_CONTROL_MEMORY, 0xFFFEC608
.equ ARM_TIM_INTERRUPT_MEMORY, 0xFFFEC60C

.equ PB_MEMORY, 0xFF200050
.equ PB_EDGE_MEMORY, 0xFF20005C
.equ PB_INTMASK_MEMORY, 0xFF200058

.equ HEX_MEMORY, 0xFF200020
_start:
	
	mov A1, #63 //63 to binary corresponds to HEX0-5
	PUSH {LR}
	mov A2, #0
	bl HEX_write_ASM //write 0 to HEX4, 5
	POP {LR}       
	
	PUSH  {V1-V6}//use V1 for counter (milliseconds -> HEX0)
	mov V1, #0
	mov V2, #0
	mov V3, #0
	mov V4, #0
	mov V5, #0
	mov V6, #0
	//V1 -> HEX0; V2 -> HEX1; V3 -> HEX2, ... V6 -> HEX5
	//We want V1-6 to have vals between 0 and 9
	//HEX0: milliseconds
	//HEX1-2: seconds
	//HEX3-4: minutes
	//HEX5: hours
	ldr A1, =#20000000 //WAS 20parameter for ARM_TIM_config_ASM
	bl ARM_TIM_config_ASM
	bl ARM_TIM_start
	//bl ARM_TIM_clear_INT_ASM
loop:
	//bl ARM_TIM_get_val
	bl ARM_TIM_read_INT_ASM
	cmp A1, #1
	beq incrementMilliseconds
	bne endLoop
incrementMilliseconds:
	cmp V1, #9
	beq incrementSeconds
	add V1, #1
	mov A1, #1 //HEX0
	mov A2, V1
	bl HEX_write_ASM
	bl ARM_TIM_clear_INT_ASM
	bl ARM_TIM_set_val
	bl ARM_TIM_start
	b endLoop
incrementSeconds:
	//HEX0 should be set to 0
	mov V1, #0	//if seconds have to be incremented than HEX0 should be set back to 0
	mov A1, #1 //HEX0
	mov A2, #0
	bl HEX_write_ASM //write 0 to HEX0
	

	mov A1, #2 //HEX1
	
	cmp V2, #9
	blt firstDigitSecondsLessThanNine
	b firstDigitSecondsEqualNine
firstDigitSecondsLessThanNine:
	add V2, #1
	mov A2, V2
	bl HEX_write_ASM //update HEX1
	b endLoop
firstDigitSecondsEqualNine:	
	//if code gets to here than V2 is >= 9
	mov A1, #2 //HEX1, might not need this line if HEX_write_ASM doesnt modify A1
	mov V2, #0
	mov A2, V2
	bl HEX_write_ASM //update HEX1
	
	
	cmp V3, #5 //V3 is biggest digit of seconds so max it can be is 5
	//NEED toincrement V3 or put it back to 0 and increment V4
	mov A1, #4 //HEX2
	blt secondDigitSecondsLess5
	b secondDigitSecondsEqual5
secondDigitSecondsLess5:
	add V3, #1
	mov A2, V3
	bl HEX_write_ASM //update HEX2
	b endLoop
secondDigitSecondsEqual5:
	//if code gets to here than V3 is >=5
	//need to set V3 to 0 and increment minutes
	mov A1, #4 //might not need this line
	mov V3, #0
	mov A2, V3
	bl HEX_write_ASM //update HEX2
	//need to increment minutes here
increment_minutes:
	//same thing here V4, V5 treated like V2, V3, max val of 59
	//might have to increment hour (V6)
	cmp V4, #9
	blt firstDigitMinutesLess9
	b firstDigitMinutesEqual9
	
firstDigitMinutesLess9:
	add V4, #1
	mov A1, #8//HEX3
	mov A2, V4
	bl HEX_write_ASM //update HEX3
	b endLoop
firstDigitMinutesEqual9:
	mov A1, #8//HEX3
	mov V4, #0
	mov A2, V4
	bl HEX_write_ASM //update HEX3
	//need to increment second digit of minute
	
	cmp V5, #5 //V5 is biggest digit for minute so highest val is 5
	mov A1, #16//HEX4
	blt secondDigitMinutesLess5
	b secondDigitMinutesEqual5 
secondDigitMinutesLess5:
	add V5, #1
	mov A2, V5
	bl HEX_write_ASM //update HEX4
	b endLoop
secondDigitMinutesEqual5:
	mov V5, #0
	mov A2, V5
	bl HEX_write_ASM //update HEX4
	//now need to increment hour (V6 -> HEX5)
	cmp V6, #9 //max val of hour is 9 -> max val of timer is 10 hours minus one millisecond (9:59:59:9)
	mov A1, #32 //HEX5
	blt hourLessThanNine
	b hourEqualNine
	
hourLessThanNine:
	add V6, #1
	mov A2, V6
	bl HEX_write_ASM //update HEX5
	b endLoop
hourEqualNine:
	mov V6, #0
	mov A2, V6
	bl HEX_write_ASM //update HEX5
endLoop:
	//MAKE PUSHING BUTTONS START, STOP, CLEAR STOPWATCH
	
	bl read_PB_edgecp_ASM
	cmp R0, #0
	bne PB_released
	beq loop
PB_released:
	//R0: 1, 2, 4, 8 -> PB0, 1, 2, 3
	//PB0: start
	//PB1: stop
	//PB2: reset
	//PB3: not used
	cmp R0, #1
	beq ARM_start
	cmp R0, #2
	beq ARM_stop 
	cmp R0, #4
	beq resetTimer
	b clearEdgeCp //if PB3 is pressed -> R0 == 8
ARM_start:
	bl ARM_TIM_start
	b clearEdgeCp
ARM_stop:	
	bl ARM_TIM_stop
	b clearEdgeCp
resetTimer:
	mov V1, #0
	mov V2, #0
	mov V3, #0
	mov V4, #0
	mov V5, #0
	mov V6, #0
	mov A1, #63 //63 to binary corresponds to HEX0-5
	mov A2, #0
	bl HEX_write_ASM
clearEdgeCp:
	bl PB_clear_edgecp_ASM
	b loop
	
	
	POP {V1-V6}
end:
	b end
	
	
	

	
	
	
	
ARM_TIM_start://set E bit to 1
	LDR A2, =ARM_TIME_CONTROL_MEMORY
	mov A3, #1 //should be #1 to set E to 1, #3 sets E and A to 1 (starts timer and it will automatically reload original value)
    ldr A1, [A2]
	orr A3, A3, A1
	str A3, [A2]
    BX  LR
	
	
ARM_TIM_stop://set E bit to 0
	LDR A2, =ARM_TIME_CONTROL_MEMORY
	mov A3, #4294967294 //all 1s except for 0 at E bit
    ldr A1, [A2]
	and A3, A3, A1
	str A3, [A2]
    BX  LR

ARM_TIM_config_ASM: //The subroutine is used to configure the timer. 
//Use the arguments discussed above to configure the timer.
	LDR A2, =ARM_TIM_LOAD_MEMORY
    STR A1, [A2]
    BX  LR
	
	
ARM_TIM_set_val:
	ldr A4, =#20000000//#500
	LDR A2, =ARM_TIM_CURRVAL_MEMORY
    str A4, [A2]
    BX  LR
	
ARM_TIM_get_val:
	LDR A2, =ARM_TIM_CURRVAL_MEMORY
    LDR A4, [A2]
	//"RETURNS" val using A4 register
    BX  LR

ARM_TIM_read_INT_ASM: //The subroutine returns the "F" value (0x00000000 or 0x00000001) from the ARM A9
//private timer Interrupt status register.
	LDR A2, =ARM_TIM_INTERRUPT_MEMORY
    LDR A1, [A2]
	//"RETURNS" val using A1 register
    BX  LR

ARM_TIM_clear_INT_ASM: //The subroutine clears the "F" value in the ARM A9 private timer Interrupt status register. 
//The F bit can be cleared to 0 by writing a 0x00000001 into the Interrupt status register.
	mov A1, #1
	LDR A2, =ARM_TIM_INTERRUPT_MEMORY
    STR A1, [A2]
	//"RETURNS" val using A1 register
    BX  LR
	
	
	
	
	
	
	
	
read_PB_data_ASM:
    LDR R1, =PB_MEMORY
    LDR R0, [R1] //R0 is 0001 if push button 0 is pushed, 1010 if p3 and p1 are pushed
    BX  LR


PB_data_is_pressed_ASM: //receives one pushbutton index as argument. 1, 2, 4, 8
	mov R2, #8 //in binary corresponds to PB 1 being pressed
	PUSH {LR}
	bl read_PB_data_ASM
	POP {LR}
	tst R0, R2
	movne R3, #1
	moveq R3, #0 //use R3 for the result, could also use the stack
	bx LR
	
read_PB_edgecp_ASM:
	LDR R1, =PB_EDGE_MEMORY
    LDR R0, [R1]
    BX  LR
	
	
PB_edgecp_is_pressed_ASM: //receives one pushbutton index as argument. 1, 2, 4, 8
	mov R2, #8 //in binary corresponds to PB 1 being pressed
	PUSH {LR}
	bl read_PB_edgecp_ASM
	POP {LR}
	tst R0, R2
	movne R3, #1
	moveq R3, #0 //use R3 for the result, could also use the stack
	bx LR

PB_clear_edgecp_ASM: //read the edgecapture register and write what you just read back to the edgecapture register to clear it.
	PUSH {LR}
	bl read_PB_edgecp_ASM
	POP {LR}
	LDR R1, =PB_EDGE_MEMORY
	STR R0, [R1]
	bx LR

enable_PB_INT_ASM: //The subroutine receives pushbuttons indices as an argument. 1010 if p3 and p1 are pushed
//Then, it enables the interrupt function for the corresponding pushbuttons by setting the interrupt mask bits to '1'.
	//R0 is treated as the argument
	mov R0, #1 //10: 1010 in binary, p3 and p1 pressed
	LDR R1, =PB_INTMASK_MEMORY
	LDR R2, [R1]
	orr R0, R0, R2
    STR R0, [R1]
	bx LR
disable_PB_INT_ASM: 
	//R0 is treated as the argument
	mov R0, #10 //10: 1010 in binary, p3 and p1 pressed
	MVN R0, R0 //flips bits of R0
	LDR R1, =PB_INTMASK_MEMORY
	LDR R2, [R1]
	and R0, R0, R2 //and to put 0s where 1s were in R0 (before flipping its bits)
    STR R0, [R1]
	bx LR





/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

//need to do AND of i and A1 for each i = 1, 2, 4, 8, 16, 32
	//to determine which HEX0-5 need to be changed
	//A3 will be i
	//HEX0-3 are in word at HEX_MEMORY
	//HEX4-5 are in word at HEX_MEMORY+16	

HEX_write_ASM:
	mov A3, #1
	PUSH {V1, V2}
//if A2 comes as parameter, next line isnt needed
	//UNCOMMENTmov A2, #3 //val from 0-15
	//need to convert A2 to the val we want to store
	//example: if A2 is 8, we want to store 127 (all bits are 1s)
	cmp A2, #0
	beq zero
	cmp A2, #1
	beq one
	cmp A2, #2
	beq two
	cmp A2, #3
	beq three
	cmp A2, #4
	beq four
	cmp A2, #5
	beq five
	cmp A2, #6
	beq six
	cmp A2, #7
	beq seven
	cmp A2, #8
	beq eight
	cmp A2, #9
	beq nine
	cmp A2, #10
	beq a
	cmp A2, #11
	beq b
	cmp A2, #12
	beq c
	cmp A2, #13
	beq d
	cmp A2, #14
	beq e
	cmp A2, #15
	beq f
	//should never get to here as long as A2 is within 0-15
	POP {V1, V2}
	bx LR
zero:
	mov A2, #63
	b next
one:
	mov A2, #6
	b next
two:
	mov A2, #91
	b next
three:
	mov A2, #79
	b next
four:
	mov A2, #102
	b next
five:
	mov A2, #109
	b next
six:
	mov A2, #125
	b next
seven:
	mov A2, #7
	b next
eight:
	mov A2, #127
	b next
nine:
	mov A2, #111
	b next
a:
	mov A2, #119
	b next
b:
	mov A2, #124
	b next
c:
	mov A2, #57
	b next
d:
	mov A2, #94
	b next
e:
	mov A2, #123
	b next
f:
	mov A2, #113
	b next
	
next:
	//by now A2 has correct val to store (bits 0 to 6)
	//we want 1s instead of 0s for bits 7-32, need to add sum 2^x for x:7-31 = 4294967168
	add A2, #4294967168
	mov A4, A2 //need to store val of A2 to reset it later
	//need to use A4 to know how much val to be stored should be shifted (padded with 1s) do (lsl#1)+1
	//do like HEX_flood_ASM to put 1s where needed. then do AND with that and val to store and store it
	mov V2, #255 //this is all 0s except for bits 7-0 which are 1s	
write_loop:	
	tst A3, A1
	bne write_HEX_display//HEX display A3 should be changed
write_continue:	
	lsl A3, #1
	cmp A3, #32
	//UNCOMMENTbgt done
	POPgt {V1, V2}
	bxgt LR 
	mov V1, #0 //V1 is counter to loop updateStoreVal 8 times
write_updateStoreVal:
	cmp V1, #7
	bgt write_restOfLoop
	lsl V2, #1 //logical shift left pads with 0s (shifting 1s over)
	lsl A2, #1
	add A2, #1 //lsl and add 1 shifts left and pads with 1s
	add V1, #1 //increment counter
	b write_updateStoreVal
write_restOfLoop:
	cmp A3, #16
	moveq A2, A4 //if R2 is 16, HEX4 is the next display to (maybe) modify. reset A2 to original val
	moveq V2, #255
	b write_loop
	
write_HEX_display:	
	//need to load, do the OR with V2 (to not modify other HEX displays), and then store, load and do AND with A2 and store 
	cmp A3, #16
	//V1 will hold memory offset to access HEX4 or 5
	movge V1, #16 //To access HEX_MEMORY+16
	movlt V1, #0//to access HEX_MEMORY+0
	PUSH {LR}
	bl write_HEX_display_write
	POP {LR}
	b write_continue

write_HEX_display_write:
	PUSH {V3, V4}
    LDR V3, =HEX_MEMORY
	ldr V4, [V3, V1]
	orr V4, V4, V2 //orr because V2 holds 1s wherever we want to update memory with 1s
    STR V4, [V3, V1]
	//added 1s where needed
	ldr V4, [V3, V1]
	and V4, V4, A2 //A2 has ones where we dont want to modify memory and V4 has ones where we do
	STR V4, [V3, V1]
	POP {V3, V4}
    BX  LR


HEX_flood_ASM:
	mov A3, #1
	PUSH {V1, V2}
	mov V2, #255 //this is all 0s except for bits 7-0 which are 1s	
flood_loop:	
	tst A3, A1
	bne flood_HEX_display//HEX display A3 should be changed
flood_continue:	
	lsl A3, #1
	cmp A3, #32
//UNCOMMENT	bgt done
	POPgt {V1, V2}
	bxgt LR 
	mov V1, #0 //V1 is counter to loop updateStoreVal 8 times
flood_updateStoreVal:
	cmp V1, #7
	bgt flood_restOfLoop
	lsl V2, #1 //logical shift left pads with 0s (shifting 1s over)
	add V1, #1 //increment counter
	b flood_updateStoreVal
flood_restOfLoop:
	cmp A3, #16
	moveq V2, #255
	b flood_loop
	
flood_HEX_display:	
	//need to load, do the OR with V2 (to not modify other HEX displays), and then store 
	cmp A3, #16
	//V1 will hold memory offset to access HEX4 or 5
	movge V1, #16 //To access HEX_MEMORY+16
	movlt V1, #0//to access HEX_MEMORY+0
	PUSH {LR}
	bl write_HEX_display_flood
	POP {LR}
	b flood_continue

write_HEX_display_flood:
	PUSH {V3, V4}
    LDR V3, =HEX_MEMORY
	ldr V4, [V3, V1]
	orr V4, V4, V2 //orr because V2 holds 1s wherever we want to update memory with 1s
    STR V4, [V3, V1]
	POP {V3, V4}
    BX  LR



HEX_clear_ASM:
	mov A3, #1
	//V2 is what to str (store)
	PUSH {V1, V2}
	mov V2, #0xFFFFFF00 //this is all 1s except for bits 7-0 which are 0s	
clear_loop:	
	tst A3, A1
	bne clear_HEX_display//HEX display A3 should be changed
clear_continue:	
	lsl A3, #1
	cmp A3, #32
	//UNCOMMENTbgt done
	POPgt {V1, V2}
	bxgt LR 
	mov V1, #0 //V1 is counter to loop updateStoreVal 8 times
clear_updateStoreVal:
	cmp V1, #7
	bgt clear_restOfLoop
	lsl V2, #1
	add V2, #1 //logical shift left plus add 1 is equal to shift left and pad with 1s
	add V1, #1 //increment counter
	b clear_updateStoreVal
clear_restOfLoop:
	cmp A3, #16
	moveq V2, #0xFFFFFF00
	b clear_loop
	
clear_HEX_display:	
	//need to load, do the AND with V2 (to not modify other HEX displays), and then store 
	cmp A3, #16
	//V1 will hold memory offset to access HEX4 or 5
	movge V1, #16 //To access HEX_MEMORY+16
	movlt V1, #0//to access HEX_MEMORY+0
	PUSH {LR}
	bl write_HEX_display_clear
	POP {LR}
	b clear_continue



write_HEX_display_clear:
	PUSH {V3, V4}
    LDR V3, =HEX_MEMORY
	ldr V4, [V3, V1]
	and V4, V4, V2 //and because V2 holds 0s wherever we want to update memory with 0s and 1s where we dont want to change memory
    STR V4, [V3, V1]
	POP {V3, V4}
    BX  LR




