; --- Program prevede int32 na float ---
; ---
; --- Autor: Lesia Dudchuk
; ---


	      .h8300s
        .equ    syscall,0x1FF00    ; simulovany vstup/vystup
        .equ    PUTS,0x0114	  	   ; kod PUTS
		.equ	GETS,0x0113        ; kod GETS
		.equ    PUTC,0x0112        ; kod PUTC
;-------datovy segment------------------------------------------------------------        
        .data
        
buffer: .space 100		   ;vstupni buffer
text:	.asciz  "Zadejte cislo:\n"                 
out:    .space 20		   ;vystupni buffer
		.align  2                  ;zarovnani parametrickeho bloku
p_buffer: .long buffer             ;parametricky blok pro vstup dekadickeho cisla
p_vt:     .long text               ;parametricky blok pro vystup textu
p_out:	  .long out                ;parametricky blok pro vystup cisla float

          .align 1                  ;zarovnani adresy
          .space 100                ;stack

stck:
;---------kodovy segment-----------------------------------------------------------	
         .text
         .global _start
		
;---------hlavni algoritm programu, prevede int32 na float--------------------------
		
result_0: 
	mov.l #0x0, ER6            ;vysledek = 0

count_result: 
	shal.l #2, ER1             ;bitovy posun doleva(23 bity) 
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l #2, ER1 
	shal.l #2, ER1
	shal.l #2, ER1
	shal.l  ER1
	
	mov.l #0x7FFFFF, ER2      
	and.l ER0, ER2
	or.l ER1, ER2	
	mov.l ER2, ER6	
	
exit:                             ; navrat z podprogramu
 	rts		
declare_var: 
	shal.l	 ER0
	dec.l #1, ER1
	jmp @continue_for_cyklus

convert_positive:
	mov.l #0x7FFF, ER0
	and.l ER4, ER0		     ;fraction = input & I2F_MAX_INPUT
	mov.l #0x0, ER1 
	cmp.l ER0, ER1
	beq result_0
			
	mov.l #141, ER1	         ;exponent
		
	shal.l #2, ER0 
	shal.l #2, ER0 
	shal.l #2, ER0 
	shal.l #2, ER0 
	shal.l ER0 
			
	mov.l #15, ER2
	mov.l #0, ER3	
	
for_cyklus:
	mov.l #0x800000, ER5 
	and.l ER0, ER5
	cmp.l ER5, ER3 				;if ER5 is 0
	beq declare_var 
	jmp @count_result

continue_for_cyklus:	
	cmp.l ER2, ER3
	beq exit 
	dec.l #1, ER2
	jmp @for_cyklus
	
convert_negative: 
	xor.l ER5, ER4	
	jsr @convert_positive
	mov.l #0x80000000, ER1
	or.l ER1, ER6
	jmp @print_result
				
convert:	
	xor.l ER5, ER4
	mov.l #0, ER6             ;kontroluje jestli je vstup < 0
	cmp.l ER6, ER4
	bmi convert_negative      ;pokud vstup je < 0, skok na "convert_negative"
	jsr @convert_positive     ;jinak provede funkci "convert_positive"
	jmp @print_result
 
negative_num:
	mov.l #0xFFFFFFFF, ER5	 
	inc.l #1, ER0
	jmp @loop_asci2decimal	
;----------zacatek programu------------------------------------------------------								
_start:     
	mov.l #stck, ER7
	mov.w #PUTS,R0		  ; 24bitovy PUTS
	mov.l #p_vt,ER1	          ; adr. param. bloku do ER1
	jsr @syscall
;———cteni cisla————————————————————————————————————————————————————
	mov.w #GETS,R0		  ;24bitovy GETS
	mov.l #p_buffer,ER1	  ;adr. param. bloku do ER1
	jsr @syscall
	
	mov.l @p_buffer, ER0
	mov.l #0, ER4		      ;vynulovani
	mov.l #0, ER5             ;vynulovani
;----------prevede ascii na decimalni cislo------------------------------------
loop_asci2decimal:			
	mov.b @ER0, R1L              
	mov.b #0x2D, R2L
	cmp.b R1L, R2L
	beq negative_num
	mov.b #0x0A, R2L
	cmp.b R1L, R2L
	beq convert		  ;skok na prevod cisla 
	mov.b #0x30, R1H
	sub.b R1H, R1L
	mov.l #0x000000FF, ER3
	and.l ER1, ER3
	mov.w #0xA, E2
	mulxs.w E2, ER4
	add.l ER3, ER4
	inc.l #1, ER0
	jmp @loop_asci2decimal
;--------funkce prevodu do ascii kodu-----------------------------------------	
print_char:
	add.b #0x37, R0H
	mov.b #0, R0L
	push.w R0
	jmp @print_end
print_number:
	add.b #0x30, R0H
	mov.b #0, R0L
	push.w R0
	jmp @print_end
print_result:
	mov.b #8, R1L
	mov.b #0, R1H
print_loop:
	cmp.b R1L, R1H
	beq outprint_preloop
	mov.l #0x0000000F, ER0
	and.l ER6, ER0        	  ;maska na posledni 4 bity 
	mov.b R0L, R0H
	mov.b #9, R0L
	cmp.b R0L, R0H
	ble print_number
	jmp @print_char
print_end:	
	shlr.l #2, ER6
	shlr.l #2, ER6
	inc.b R1H
	jmp @print_loop
;---------vypis do konzole-----------------------------------------------------------
outprint_preloop:
	mov.b #8, R1L
	mov.b #0, R1H
	mov.l #out, ER3
	
outprint_loop:
	cmp.b R1L, R1H
	beq outprint
	pop.w R2
	mov.b R2H, @ER3
	inc.l #1, ER3
	inc.b R1H
	jmp @outprint_loop 
outprint: 
	mov.l #p_out, ER1
	mov.w #PUTS, R0
	jsr @syscall	
;------konak programu-----------------------------------------------------------
 konec: jmp @konec
       .end      
