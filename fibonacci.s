; --- Vypocet a vypis 25 clenu fibonnaciho posloupnosti ---
; ---
; ---
		.h8300s
		
; ER0 - registr zabran pro vypis textu na obrazovku
; ER1 - registr zabran pro vypis textu na obrazovku
; ER2 - registr zabran pro vypis textu na obrazovku
; ER3 - citac pro opakovani vypoctu a vypisu fibonnaciho
; ER4 - hodnota A
; ER5 - hodnota B

; Tento program vykonava nasleduji algoritmus (java):
; promena tmp neni vyuzita v ASM (reseno zasobnikem)
;
;		int a = 0;
;		int b = 1;

;		System.out.println(0);
;		System.out.println(1);

;		for (int i = 1; i <= 25; i++) {
;
;			int tmp = a + b;
;			a = b;
;			b = tmp;
;
;			System.out.println(b);
;		}
;
 


; --- Definice symbolu ---
        .equ    syscall,0x1FF00
        .equ    PUTS,0x114
        
; --- Zacatek datoveho bloku ---
        .data
        .align  1		;zarovnani pro zasobnik
        .space  100     ;stack velky 100 byte
stck: 					;pocatek zasobniku

buffer: 
		.space  9       ;prevedeny text
radkovac:
		.asciz	"\n"	; asciz hodnota pro znak odradkovani
c0:		.byte 			; asciz hodnoty pro cisla 0-7

        .align  2		;zarovnani
par_radkovac: 
		.long	radkovac	; Parametricky block pro odradkovani (znaky \n)	
		
		.align	2
par_c0:	.long	c0			; parametricke blocky textove podoby cisel	


; --- Konec datoveho bloku ---
; --- Zacatek zdrojoveho kodu ---
        .text
        .global _start
        
; --- Definice vsech nutnych podprogramu/strukturs ---


; Podprogram pro odradkovani
odradkuj:
		push.l 	ER0			;ulozeni nepotrebnych hodnot do zasobniku
		push.l 	ER1			;pri zacatku podprogramu
		mov.w	#PUTS,R0	; 24bitovy PUTS
		mov.l	#par_radkovac,ER1	; adr. param. bloku do ER1
		jsr		@syscall
		pop.l 	ER1
		pop.l 	ER0
		rts

; Podprogram pro vypis jedne cislice z ascii
; VSTUP: R6
; VYSTUP: obrazovka
cislo_vypis:
        push.l ER4          ;ulozeni nepotrebnych hodnot do zasobniku 
        push.l ER5			;pri zacatku podprogramu
        push.l ER0
       
        mov.l #0,ER0        ;vlozeni hodnoty 0 do ER0 - nulovani registru
        mov.w R6,R0         ;presun hodnoty R6 do registru R0
       	nop
	   
	   	mov.w #48,R6		;vlozeni ascii hodnoty pro znak 0 do R6
		add.w R6,R0			;vypocet ascii hodnoty dle pozadovaneho znaku
		nop					;nope
		
		mov.b  R0L,@c0		;ulozeni ascii znaku na misto v pamaeti
		
		push.l ER0			;ulozeni puvodnich dat do zasobniku pred vypisem         
        push.l ER1
        mov.w   #PUTS,R0    ; 24bitovy PUTS
        mov.l   #par_c0,ER1 ; adr. param. bloku do ER1
        jsr     @syscall
        pop.l ER1
        pop.l ER0			;vyber puvodni dat ze zasobniku po vyposu
	   
        pop.l ER0			;vyber puvodnich dat po dokonceni podprogramu
        pop.l ER5
        pop.l ER4      
        rts

; Podprogram pro převod binárního čísla na dekadicke ascii
; VSTUP: ER0
; VYSTUP: Console
; REGISTRY:
;		ER3 - citac
;		ER4 - cim se bude delit hodnota
;		ER5 - pomocna pro deleni ER4
dec_ascii:	
		push.l	ER3			;ulozeni puvodnich hodnot registru do zasobniku		
		push.l 	ER4
		push.l	ER5
		push.l 	ER2
		
		mov.l 	#5,ER3		;provede se 5 deleni pro delitel ER4
		mov.l	#10000,ER4	;zarovnavani na 5 mist 
		mov.w	#10,R5		;aby se ER4 vzdy delilo 10
		
dec_ascii_if:				;navesti podminky


		mov.w	R4,R5		;registr R5 se bude delit hodnotou v R4
		divxu.w	R5,ER0		;vydeli registr ER0, do E0 vlozi zbytek, do R0 vlozi vysledek
		mov.w	E0,R6		;R6 zbytek
		push.w	R0			;ulozeni vysledku do zasobniku
		mov.l	ER6,ER0		;vratit zbytek pro dalsi vysledek
		pop.w	R6			;R6 vysledne cislo co vypsat na obrazovku - vyber ze zasobniku
			
		;vypsat R6
		jsr @cislo_vypis	;Vypise obsah registru R6 do ascii dekadicke podoby
		
		mov.w 	#10,R5		;zajisti ze se bude delit 10
		divxu.w	R5,ER4		;vydeli registr ER4 hodnotou 10	
		dec.l 	#1,ER3		;snizi obsah registru ER3 o 1
		
		
		bne dec_ascii_if
		
		pop.l	ER2
		pop.l 	ER5			;navraceni puvodnich hodnot do zasobniku
		pop.l 	ER4			
		pop.l 	ER3			
		
		rts
		
; Hlavni podprogram, vypocet a vypis fibonnaciho
fibbonaci:
		mov.l	#24,ER3		;nastaveni citace na 25
		
fib_if:						;if citac not 0

		push.l	ER5			;ulozeni B do zasobniku
		add.l 	ER4,ER5		;(B:ER5) = ER5 + ER4
		pop.l 	ER4			; A = B

		mov.l	ER5,ER0		;uloz hodnotu citace do ER0
		jsr 	@dec_ascii	;vypise cislo v dekadicke podobe
		jsr		@odradkuj	;odrakuje

		dec.l 	#1,ER3		;zmensi ER3 o 1 
		bne		fib_if		;pokud je ER3 vetsi jak 0, skoc na fib_if
		rts

; Hlavni vykonna cast programu
_start: mov.l 	#stck,ER7   ;inicializace SP
        mov.l   #buffer,ER2 ;adresa bufferu do ER2
        mov.b   #8,R1H      ;citac
        
		
		mov.l 	#0,ER4		;priprava pro fibonnaciho podprogram - promenna a
		mov.l	#1,ER5		;priprava pro fibonnaciho podprogram - promenna b
	
		mov.l	ER5,ER0		;priprava pro vypis druheho clenu fibonnaciho posloupnosti
		jsr 	@dec_ascii	;vypis prvniho druheho fibonnaciho posloupnosti
		jsr 	@odradkuj	;odrakuje
		
		jsr 	@fibbonaci	;zavolani podprogramu fibonacci
		
		
; Ukonceni programu dynamickym stopem
end:   jmp     @end       ;dynamicky stop
