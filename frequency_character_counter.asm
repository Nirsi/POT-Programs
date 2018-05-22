; --- Vygenerování histogramu ze zadaného textu ---
; ---
; --- Autor: Patrik Janoušek - PapiCZ
; ---
		.h8300s

		.equ syscall,0x1FF00               ; simulated IO area
		.equ PUTS,0x0114                   ; kod PUTS
		.equ GETS,0x0113                   ; kod GETS

; ------ datovy segment ----------------------------

		.data
txt:	.asciz "Zadejte vstupni retezec:\n"       ; vypisovany text ukonceny \n
i_buffer:	.space 100                         ; vstupni buffer
o_buffer:	.space 8                         ; vystupni buffer
charcountbuff:	.space 62

; parametricke bloky musi byt zarovnane na dword
		.align 2                           ; zarovnani adresy
init_message:	.long txt                     
input:			.long i_buffer                    
output:			.long o_buffer

; stack musi byt zarovnany na word
		.align 1                           ; zarovnani adresy
		.space 100                         ; stack
stck:                                        ; konec stacku + 1

; ------ kodovy segment ----------------------------

		.text
		.global _start

clear:
		mov.l	#0,ER0
		mov.l	#0,ER1
		mov.l	#0,ER2
		mov.l	#0,ER3
		mov.l	#0,ER4
		mov.l	#0,ER5
		mov.l	#0,ER6
		rts
		
increment:
		mov.b	@ER1, R3H
		inc.b	R3H
		mov.b 	R3H, @ER1
		rts
		
is_big_character:
		add.b	#-54, R0L
		add.l	ER0, ER1
		
		jsr		@increment
		
		add.b	#54, R0L
		mov.b	#1, R2L
		
		rts	

is_small_character:
		add.b	#-60, R0L
		add.l	ER0, ER1
		
		jsr		@increment
		
		add.b	#60, R0L
		mov.b	#1, R2L
		
		rts
		
is_number:
		add.b	#-47, R0L
		add.l	ER0, ER1
		
		jsr		@increment
		
		add.b	#47, R0L
		mov.b	#1, R2L
		
		rts
		
is_other:
		jsr		@increment
		rts
		
other_subroutine:
		cmp		R2H, R2L
		bmi		is_other
		
exit_subroutine:
		rts
		
; IF R0L IS EQUAL OR LESS THAN R5L, THEN JUMP TO @ER6
is_greater:
		; R0L IS EQUAL OR GREATER THAN R4L
		cmp.b	R4L, R0L
	
		bgt 	exit_subroutine
		jmp		@ER6
	
	
; IF R0L IS BETWEEN R4L AND R5L, THEN JUMP TO @ER6	
is_between:
		cmp.b	R0L, R4H
		
		ble		is_greater
		rts

_start:   	
		;jsr		@clear
		mov.l	#stck, ER7
		
		; WRITE INITIAL MESSAGE
		mov.w #PUTS, R0
		mov.l #init_message, ER1
		jsr @syscall

		; READ INPUT
		mov.w #GETS, R0                     ; 24bitovy GETS
		mov.l #input, ER1                    ; adr. param. bloku do ER1
		jsr @syscall


		; MOVE FIRST CHAR to R0L
		mov.l	@input, ER5
		
loop:
		mov.b	@ER5, R0L
		mov.w	#0x0A, E0
		cmp.w	E0, R0
		beq		print_all
		
		mov.l	#0x000000FF, ER2
		and.l	ER2, ER0
		
		mov.l	#charcountbuff, ER1
		
		; CHARACTER RECOGNITION
		mov.b	#48, R4H
		mov.b	#57, R4L
		mov.l	#is_number, ER6
		jsr		@is_between
		
		mov.b	#65, R4H
		mov.b	#90, R4L
		mov.l	#is_big_character, ER6
		jsr		@is_between
		
		mov.b	#97, R4H
		mov.b	#122, R4L
		mov.l	#is_small_character, ER6
		jsr		@is_between
		
		jsr		@other_subroutine
		
		inc.l	#1, ER5
		jmp		@loop
		
print_all:
		mov.l	#charcountbuff, ER2
		mov.b	#0, R3L ; ORDER IN CURRENT OFFSET GROUP
		mov.b	#63, R4L ; ASCII TABLE OFFSET
		mov.w	#PUTS, R0
		
print_loop:
		mov.b	R3L, R4H
		add.b	R4L, R4H
		
		mov.b	R4H, R6H
		mov.b	#58, R6L
		
		mov.l	#o_buffer, ER5
		mov.w	R6, @ER5 ; MOV "{NUMBER}:" to output buffer
		
		inc.l	#2, ER5
		
		mov.b	@ER2, R6H
		
		; Skip print if R6H is zero (ASCII)
		mov.b	#0, R6L
		cmp.b	R6H, R6L
		beq		skipped_print
		
		; Free some registers...
		push.l	ER0
		push.l	ER1
		push.l	ER2
		
		mov.l	#0, ER0
		mov.l	#0, ER1
		mov.l	#0, ER2
		
		mov.b	#10, R0L
		mov.b	R6H, R1L
build_number_loop:
		divxu.w	R0, ER1
		add.w	#48, E1
		push.w	E1
		mov.w	#0, E1
		inc.b	R2L
		cmp.w	E1, R1
		beq		read_number_from_stack
		jmp		@build_number_loop
		
read_number_from_stack:
		pop.w	R0
		mov.b	R0L, @ER5
		inc.l	#1, ER5
		dec.b	R2L
		cmp.w	R2, E2
		bne		read_number_from_stack
		
continue_print_loop:
		; Return data back to registers...
		pop.l	ER2
		pop.l	ER1
		pop.l	ER0

		mov.b	#10, R6H
		mov.b	R6H, @ER5
		mov.l	#output, ER1
		jsr		@syscall
		
skipped_print:
		inc.l	#1, ER2
		inc.b	R3L
		
		; -- CHANGE ASCII OFFSET IF NEEDED --
		mov.b	R3L, R5H
		add.b	R4L, R5H

		mov.b	#64, R5L
		cmp.b	R5H, R5L
		beq		set_numeric_offset
		
		mov.b	#58, R5L
		cmp.b	R5H, R5L
		beq		set_big_alphabet_offset
		
		mov.b	#91, R5L
		cmp.b	R5H, R5L
		beq		set_small_alphabet_offset
		
		mov.b	#123, R5L
		cmp.b	R5H, R5L
		beq		end
		
		jmp		@print_loop
		
set_numeric_offset:
		mov.b	#48, R4L
		mov.b	#0, R3L
		jmp		@print_loop
		
set_big_alphabet_offset:
		mov.b	#65, R4L
		mov.b	#0, R3L
		jmp		@print_loop

set_small_alphabet_offset:
		mov.b	#97, R4L
		mov.b	#0, R3L
		jmp		@print_loop
				
end:
		jmp @end                          ; konec vypoctu
		
               .end
			   
