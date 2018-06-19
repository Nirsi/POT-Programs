; --- prevod binarni hodnoty na ASCII ---
; ---
; --- Autor: Unknown
; ---
   
   .h8300s
          .data
vstup:    .long  12345679   ; prevadena hodnota  
vystup:   .space 10 ;10 bytu pro retezce
mocniny:  .long 1 000 000 000
          .long 100 000 000
          .long 10 000 000
          .long 1 000 000
          .long 100 000
          .long 10 000
          .long 1000
          .long 100
          .long 10
          .long 1
          .align 1 ;zarovnani na 2^1
          .space 100
stck:     
          .text
_start:   mov.l #STCK, ER7 ;inicializace SP
          mov.l #mocniny, ER3
          mov.l #vystup, ER4
          mov.b #10,R2H
          mov.l #vstup,ER0 ;prevadene cislo do ER0
lab3:     mov.l @ER3, ER1  ;mocnina do ER1
          jsr @div10 ;deleni, podil je v R2L
          add.b #'0', R2L ; prevod na ASCII
          mov.b R2L, @ER4 ;ulozeni kodu do retezce
          inc.l #2, ER3 ;ER3 += 2
          inc.l #2, ER3 ;ER3 += 2, posun pointru na mocniny
          inc.l #1, ER4 ;posun pointru do retezce
          dec.b R2H
          bne lab3  ;skok zpet na lab3
lab4:     jmp @lab4
          
div10:  xor.b R2L,R2L ; 0 -> R2L
lab2:   cmp.l ER0,ER1 ; ER1 - ER0 -> void, nastavi priznakove byty
        bhi lab1      ; skok pri ER0 < ER1
        sub.l ER1,ER0 ; ER0 = ER0 - ER1
        inc.b R2L     ; R2L++
        jmp @lab2
        
lab1:   rts           ;navrat
