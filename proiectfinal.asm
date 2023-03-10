.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "VAPORASELE",0
area_width EQU 1000
area_height EQU 700
harta DD 16 dup (0)
ratari DD 0
succes DD 0
nedescoperite DD 6
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

horizontal_line macro x, y, len, color
local line_loop
pusha
   mov eax, y
   mov ebx, area_width
   mul ebx
   add eax, x
   shl eax, 2
   add eax, area
   mov ecx, len
   line_loop:
   mov dword ptr[eax], color
   add eax, 4
   loop line_loop
   popa
endm

vertical_line macro x, y, len, color
local line_loop, continue, stop
pusha
   mov eax, y
   add eax, len
   cmp eax, area_height
   jl continue
   jge stop
   continue:
   mov eax, y
   mov ebx, area_width
   mul ebx
   add eax, x
   shl eax, 2
   add eax, area
   mov ecx, len
   line_loop:
   mov dword ptr[eax], color
   add eax, area_width*4
   loop line_loop
   stop:
   popa
endm

square_line macro x, y, len, color
   local loopp
   pusha
   mov eax,x
   mov ebx,y
   mov ecx,len
   shl ecx,1
    loopp:
    horizontal_line x,ebx,len,color
	inc ebx
	dec ecx
	loop loopp
	popa
endm

generare_harta macro 
	local bucla1,bucla2
	pusha
	mov ecx,2
	mov ebx,16
	bucla1:
	rdtsc
	xor edx,edx
    div ebx
	cmp harta[edx*4],1
	je bucla1
	mov harta[edx*4],1
    loop bucla1
	
	mov ecx,2
	bucla2:
	rdtsc
	xor edx,edx
    div ebx
	cmp edx,3
	je bucla2
	cmp edx,7
	je bucla2
	cmp edx,11
	je bucla2
	cmp edx,15
	je bucla2
	cmp harta[edx*4],1
	je bucla2
	cmp harta[edx*4],2
	je bucla2
	cmp harta[edx*4+4],1
	je bucla2
	cmp harta[edx*4+4],2
	je bucla2
	mov harta[edx*4],2
	mov harta[edx*4+4],2
    loop bucla2
	popa
endm

pozitie_click macro x,y
	push ecx
	push edx
	
	mov eax,x
	sub eax,120
	mov ecx,51
	xor edx,edx
	div ecx
	mov ebx,eax
	
	mov eax,y
	sub eax,180
	mov ecx,51
	xor edx,edx
	div ecx       	
	
	pop edx
	pop ecx
endm

numar1 macro nr
pusha
mov ebx,10
mov eax,nr
xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,750,180

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,740,180

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,730,180
popa
endm

numar2 macro nr
pusha
mov ebx,10
mov eax,nr
xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,750,210

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,740,210

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,730,210
popa
endm

numar3 macro nr
pusha
mov ebx,10
mov eax,nr
xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,750,240

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,740,240

xor edx,edx
div ebx
add edx,'0'
make_text_macro edx,area,730,240
popa
endm

colorare_matrice macro 
local colorare_apa ,final
	pusha
	shl eax,2
	shl ebx,2
	
	mov ecx,harta[eax*4+ebx]
	shr eax,2
	shr ebx,2
	push eax
	mov eax,ebx
	mov esi,51
	mul esi
	add eax,121
	
	mov edi,eax
	pop eax
	mul esi
	add eax,181
	mov esi,eax
	
	cmp ecx,0
	je colorare_apa
	square_line edi,esi,50,0FF0000h
	inc succes
	numar1 succes
	dec nedescoperite
	numar2 nedescoperite
	jmp final
	colorare_apa:
	square_line edi,esi,50,00000FFh
	inc ratari
	numar3 ratari
	final: 
	popa	
endm


draw proc
push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	
	evt_click:
	cmp dword ptr [ebp+arg2],120
	jb evt_timer
	cmp dword ptr [ebp+arg2],324
	ja evt_timer
	cmp dword ptr [ebp+arg3],180
	jb evt_timer
	cmp dword ptr [ebp+arg3],384
	ja evt_timer
	pozitie_click [ebp+arg2],[ebp+arg3]
	colorare_matrice
	evt_timer:
	afisare_litere:
	;scriem un mesaj
	make_text_macro 'V', area, 450, 100
	make_text_macro 'A', area, 460, 100
	make_text_macro 'P', area, 470, 100
	make_text_macro '0', area, 480, 100
	make_text_macro 'R', area, 490, 100
	make_text_macro 'A', area, 500, 100
	make_text_macro 'S', area, 510, 100
	make_text_macro 'E', area, 520, 100
	make_text_macro 'L', area, 530, 100
	make_text_macro 'E', area, 540, 100


    horizontal_line 120, 180 , 205,  0878586h
	horizontal_line 120, 231 , 205,  0878586h
	horizontal_line 120, 282 , 205,  0878586h
	horizontal_line 120, 333 , 205,  0878586h
	horizontal_line 120, 384 , 205,  0878586h
	
	
	vertical_line 120, 180, 205, 0878586h
	vertical_line 171, 180, 205, 0878586h
	vertical_line 222, 180, 205, 0878586h
	vertical_line 273, 180, 205, 0878586h  ;fiecare patrat din joc are dimesniunea de 50*50 pixeli
	vertical_line 324, 180, 205, 0878586h
	
	make_text_macro 'L', area, 550, 180
	make_text_macro 'O', area, 560, 180
	make_text_macro 'V', area, 570, 180
	make_text_macro 'I', area, 580, 180
	make_text_macro 'T', area, 590, 180
	make_text_macro 'U', area, 600, 180
	make_text_macro 'R', area, 610, 180
	make_text_macro 'I', area, 620, 180
	
	make_text_macro 'R', area, 640, 180
	make_text_macro 'E', area, 650, 180
	make_text_macro 'U', area, 660, 180
	make_text_macro 'S', area, 670, 180
	make_text_macro 'I', area, 680, 180
	make_text_macro 'T', area, 690, 180
	make_text_macro 'E', area, 700, 180
	
	make_text_macro 'D', area, 550, 210
	make_text_macro 'E', area, 560, 210
	
	make_text_macro 'G', area, 580, 210
	make_text_macro 'A', area, 590, 210
	make_text_macro 'S', area, 600, 210
	make_text_macro 'I', area, 610, 210
	make_text_macro 'T', area, 620, 210
	
	make_text_macro 'R', area, 550, 240
	make_text_macro 'A', area, 560, 240
	make_text_macro 'T', area, 570, 240
	make_text_macro 'A', area, 580, 240
	make_text_macro 'T', area, 590, 240
	make_text_macro 'E', area, 600, 240

	numar1 succes
	numar2 nedescoperite
	numar3 ratari
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	generare_harta
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start