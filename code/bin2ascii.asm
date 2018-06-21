;   prevod 32bitove bin. hodnoty na ASCII
		.h8300s

        .equ    syscall,0x1FF00
        .equ    PUTS,0x114
        
        .data
        .align  1
        .space  100     ;stack
stck:   
buffer: .space  9       ;prevedeny text

        .align  2
par1:   .long   buffer  ;parametricky blok

        .text
        .global _start
        
prevod: add.b   #'0',R1L
        cmp.b   #'9',R1L
        bls     lab1
        add.b   #(-'0'-0x0A+'A'),R1L
lab1:   rts

_start: mov.l   #stck,ER7   ;inicializace SP
        mov.l   #buffer,ER2 ;adresa bufferu do ER2
        mov.b   #8,R1H      ;citac

lab2:   rotl.l   #2,ER0     ;rotace doleva
        rotl.l   #2,ER0     ;rotace doleva
        mov.b   R0L,R1L
        and.b   #0x0F,R1L   ;nulovani hornich 4 bitu
        jsr     @prevod
        mov.b   R1L,@ER2    ;ulozeni do bufferu
        inc.l   #1,ER2      ;posun pointeru
        dec.b   R1H         ;nastavi priznaky
        bne     lab2        ;neni-li nastaven Z
		
		mov.b	#0x00,R1L
		mov.b	R1L,@ER2	;konec retezce
        
        mov.w   #PUTS,R0    ;kod sluzby PUTS
        mov.l   #par1,ER1   ;adresa par. bloku
        jsr     @syscall    ;vypis
        
lab3:   jmp     @lab3       ;dynamicky stop

        