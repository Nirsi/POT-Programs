;   prevod malych pismen na zacatku slov na velka a vice versa
               .h8300s

               .equ syscall,0x1FF00              				 	; simulated IO area
               .equ PUTS,0x0114                   					; kod PUTS
               .equ GETS,0x0113                   					; kod GETS
			   
; ------ registry segment ----------------------------
;				ER0			-	obsahuje informaci o tom jestli se bude provadet zapis nebo cteni	   
;				ER1			-	obsahuje pointer na adresu zacatku pametoveho bloku odkud se bude zapisovat
;				ER2			-	obsahuje pointer na adresu zacatku pametoveho bloku, ktery se potom prevede na skutecnou adresu zacatku
;				ER3(R3L)		-	obsahuje aktualni byte ktery se zpracovava
;				ER4			-	obsahuje hodnotu konce radku(new line) a mezery v ascii
;				ER5			-	obsahuje hranice velkych pismen 
;				ER6			-	obsahuje hranice malych pismen
;				ER7			-	obsahuje pointer na stack

; ------ datovy segment ----------------------------

               .data
buffer: 	   .space 100                         					; vstupni buffer

; parametricke bloky musi byt zarovnane na dword
               .align 2                           					; zarovnani adresy
			     
textt:     	   .long buffer                       					; parametricky blok 2

; stack musi byt zarovnany na word
               .align 1                           					; zarovnani adresy
          	   .space 100                        					; stack
stck:                                        	  					; konec stacku + 1

; ------ kodovy segment ----------------------------

               .text
               .global _start
			   
			   
			   
clear:											;Subrutina pro vycisteni registru
				mov.l	#0,	ER0
				mov.l	#0, ER1
				mov.l	#0, ER2
				mov.l	#0, ER3
				mov.l	#0, ER4
				mov.l	#0, ER5
				mov.l	#0, ER6
				rts
		
print:	
				mov.w 	#PUTS,R0                  		   	 ; 24bitovy PUTS
              	mov.l 	#textt,ER1                  					 ; adr. param. bloku do ER1
               	jsr 	@syscall
				rts

	
change_low:										; zmena maleho znaku na velkyy
				subx.b	#32,R3L
				mov.b	R3L,@ER2
				mov.w	#0,	E4
				jmp		end_change	
			
change_high:										; zmena velkeho znaku ma maly
				addx.b	#32,R3L
				mov.b	R3L,@ER2
				mov.w	#0,	E4
				jmp		end_change	
	
letter_low:										; podminka pro maly znak
				cmp.b	R3L, R6H
				bpl		change_low
				jmp		end_change	
			
letter_high:										; podminka pro velky znak
				cmp.b	R3L, R5H
				bpl		change_high
				jmp		end_change	

check_letters:										; hlavni podminka pro znaky
				cmp.b	R3L, R6L
				bmi		letter_low
				cmp.b	R3L, R5L
				bmi		letter_high
			
cycle:											; hlavní cyklus(subrutina) programu
			
				mov.b	@ER2,R3L
				cmp.b	R3L, R4L
				beq		print
				cmp.b	R3L, R4H
				beq		end_set_space
				cmp.w	E4, E3
				beq		check_letters
			
			
end_change:										; ukonceni zmeny(konec cyklu)
				inc.l	#1,	ER2
				mov.w	#0,	E4
				jmp		cycle
			
end_set_space:										; ukonceni cyklu s nastavenim mezery
				inc.l	#1,	ER2
				mov.w	#1, E4
				jmp		cycle
				rts
				

_start:			jsr		@clear
				mov.l	#stck,ER7
				mov.l	#textt,ER2

				
				
				
               	mov.w 	#GETS,R0                    ; 24bitovy GETS
               	mov.l 	#textt,ER1                  ; adr. param. bloku do ER1
               	jsr 	@syscall
				
				mov.l	@ER2,ER2					;ziskani adresy bufferu z "pointeru"
				mov.w	#1,	 E3
			
				mov.b	#10, R4L					;indikace konce zadavaneho textu (NL line feed)
				mov.b	#32, R4H					;mezera pro oddeleni slov
				mov.w	#1,  E4						;"boolean" jestli byla nalezena mezera
				mov.b	#64, R5L					;dolni hranice velkych pismen (@)
				mov.b	#91, R5H					;horni hranice velkych pismen ([)
				mov.b	#96, R6L					;dolni hranice malych pismen (´)
				mov.b	#123,R6H					;horni hranice malych pismen ({)
				
				
				jsr	@cycle



			   
			   

loop:    		jmp @loop                          				; konec vypoctu
               .end
	       
