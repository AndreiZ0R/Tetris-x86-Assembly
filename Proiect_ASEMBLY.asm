.586
.model flat, stdcall


includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc



public start


; poz in matrice: (y * area_width + x) * 4
.data
format_debug db "Rand plin ",13,10, 0


window_title DB "Tetris by Andrei Borza", 0
area_width EQU 600
area_height EQU 700
area DD 0

counter DD 0 ; numara evenimentele de tip timer
score DD 0
clicks DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24

symbol_width EQU 10
symbol_height EQU 20


game_frame_width EQU 311	; 300 -> sa incapa 10 patrate + 9 pt spatii intre ele + 2 pt pixelii de margine
game_frame_heigth EQU 550


currentX DD 132
currentY DD 114

startPositionX EQU 132
startPositionY EQU 114


falling_rate EQU 3
len_of_a_piece EQU 30
moving_rate EQU len_of_a_piece
new_piece_flag DD 0

game_over_flag DD 0
game_over_color1 EQU 0FF0000h
game_over_color2 EQU 0f05454h


right_squareX DD 465
right_squareY DD 200



include digits.inc
include letters.inc
include shapes.inc


color_white 	EQU 0FFFFFFh
color_red 		EQU 0FF4354h
color_purple 	EQU 0b226aah
color_green 	EQU 00bba58h
color_yellow	EQU 0c1ca20h
color_blue		EQU 00362fch
color_hotBlue   EQU 072f2e7h
color_orange 	EQU 0fc7f03h

randomNumber dd 0
colorsCount dw 8



bigBox_height EQU 60
bigBox_width  EQU 60

bigLine_height EQU 30
bigLine_width  EQU 150

middleShape_height EQU 60
middleShape_width  EQU 90

Lshape_heigth EQU 90
Lshape_width  EQU 60

currentShape_height DD 0
currentShape_width  DD 0
currentShape_number DD 0

randomShapeNumber DD 0
shapeCounter dw 16


canMoveLeft DD 1 
canMoveRight DD 1 
doneMoving DD 0


lastLine_isFull dd 0
.code


check_full_line proc
push ebp
mov ebp, esp
pusha

	; x = 130
	; y = 110 + game_frame_heigth - len_of_a_piece/2
	mov eax, 110+game_frame_heigth - len_of_a_piece/2
	mov ebx, area_width
	mul ebx
	add eax, 130
	shl eax,2
	add eax, area
	
	mov ecx, game_frame_width
	check_last_line:
		cmp dword ptr[eax], 1
		jne notFull
		
	loop check_last_line
	mov lastLine_isFull, 1
	jmp endd
	
	notFull:
	mov lastLine_isFull, 0
	
endd:
popa
mov esp, ebp
pop ebp
ret
check_full_line endp


;-----------function for returning a random value between 0 - shapeCounter--------------
giveRandomShape proc
	push ebp
	mov ebp, esp
	pusha

	rdtsc
	xor edx, edx
	div shapeCounter
	
	mov randomShapeNumber, edx
	
	popa
	mov esp, ebp
	pop ebp
	ret
giveRandomShape endp
;---------------------------------------------------------------------------------------

;----------------------------boundaries checking---------------------------------------
checkBoundaries_macro macro x, y
local boxCase,middleCase,elCase,lineCase,stopChecking

	push y
	push x
	
	cmp currentShape_number, 0
	je boxCase
	
	cmp currentShape_number, 1
	je middleCase
	
	cmp currentShape_number, 2
	je elCase
	
	cmp currentShape_number, 3
	je lineCase
	
	
boxCase:
	call checkBoxBoundary
	add esp, 8
	jmp stopChecking
	
middleCase:
	call checkMiddleBoundary
	add esp, 8
	jmp stopChecking
	
elCase:
	call checkElBoundary
	add esp, 8
	jmp stopChecking

lineCase:
	call checkLineBoundary
	add esp, 8
	jmp stopChecking
	
	
stopChecking:	
endm


;---------------------------------------------------------------------------------------------




;-----------------individual boundaries checking----------------------------------------------
;;;;box shape check
;arg1 - x
;arg2 - y
checkBoxBoundary proc ;box
push ebp
mov ebp, esp
pusha

	;;;;;;;;;;;
	mov eax, [ebp+arg2] ;y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1] ;x
	shl eax, 2
	add eax, area
	;;;;;;;;;;;


	mov edi, eax
	sub edi, 3
	mov ecx, bigBox_height
	leftBox:
		cmp dword ptr[edi], 0
		jne cantMoveBoxLeft
		add edi, 4*area_width
	loop leftBox
	mov canMoveLeft, 1
	
	mov ecx, bigBox_height
	mov edi, eax
	add edi, 4*bigBox_width+4
	rightBox:
		cmp dword ptr[edi], 0
		jne cantMoveBoxRight
		add edi, 4*area_width
	loop rightBox
	mov canMoveRight, 1
	
	jmp checkStopBox
	
	cantMoveBoxLeft:	
		mov canMoveLeft, 0
		jmp checkStopBox
	
	cantMoveBoxRight:
		mov canMoveRight, 0
		jmp checkStopBox
	
	
	checkStopBox:
		mov edi, eax
		mov ecx, bigBox_width
		add edi, 4*area_width*bigBox_height
		add edi, 3*area_width
		bottomBox:
			cmp dword ptr[edi], 0
			jne stopMoving
			add edi, 4
		loop bottomBox
		jmp finishh
	
		
	
stopMoving:
	mov doneMoving, 1

finishh:
popa
mov esp, ebp
pop ebp
ret
checkBoxBoundary endp

;;;;;;;;;;middle shape check
;arg1 - x
;arg2 - y
checkMiddleBoundary proc ;middleShape
push ebp
mov ebp, esp
pusha

;;;;;;;;;;;
	mov eax, [ebp+arg2] ;y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1] ;x
	shl eax, 2
	add eax, area
;;;;;;;;;;;


	mov edi, eax
	add edi, 4*area_width*len_of_a_piece
	sub edi, 3
	mov ecx, len_of_a_piece
	leftMiddle:
		cmp dword ptr[edi], 0
		jne cantMoveMiddleLeft
		add edi, 4*area_width
	loop leftMiddle
	mov canMoveLeft, 1
	
	mov edi, eax
	add edi, 4*area_width*len_of_a_piece
	add edi, 4*middleShape_width
	add edi, 3
	mov ecx, len_of_a_piece
	rightMiddle:
		cmp dword ptr[edi], 0
		jne cantMoveMiddleRight
		add edi, 4*area_width
	loop rightMiddle
	mov canMoveRight, 1
	
	jmp checkStopMiddle
	
	cantMoveMiddleLeft:
		mov canMoveLeft, 0
		jmp checkStopMiddle
	
	cantMoveMiddleRight:
		mov canMoveRight, 0
		jmp checkStopMiddle
	
	checkStopMiddle:
		mov edi, eax
		add edi, 4*area_width*middleShape_height
		add edi, 4*area_width+4
		mov ecx, middleShape_width
		bottomMiddle:
			cmp dword ptr[edi], 0
			jne stopMovingMiddle
			add edi, 4
		loop bottomMiddle
		jmp finishMiddle
	
stopMovingMiddle:
	mov doneMoving, 1
	
finishMiddle:
popa
mov esp, ebp
pop ebp
ret
checkMiddleBoundary endp



;;;;check L shape
;arg1 - x
;arg2 - y
checkElBoundary proc
push ebp
mov ebp, esp
pusha

;;;;;;;;;;;
	mov eax, [ebp+arg2] ;y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1] ;x
	shl eax, 2
	add eax, area
;;;;;;;;;;;
	
	
	mov edi, eax
	sub edi, 2
	mov ecx, len_of_a_piece
	leftEl:
		cmp dword ptr[edi], 0
		jne cantMoveElLeft
		add edi, 4*area_width
	loop leftEl
	mov canMoveLeft, 1

	mov edi, eax
	add edi, 4*Lshape_width
	add edi, 2
	mov ecx, Lshape_heigth
	rightEl:
		cmp dword ptr [edi], 0
		jne cantMoveElRight
		add edi,4*area_width
	loop rightEl
	mov canMoveRight, 1
	
	jmp checkStopEl
	
	cantMoveElLeft:
		mov canMoveLeft, 0
		jmp checkStopEl
		
	cantMoveElRight:
		mov canMoveRight, 0
		jmp checkStopEl
		
	checkStopEl:
		mov edi, eax ;check small square first
		add edi,4*area_width*len_of_a_piece
		add edi, 4
		mov ecx, len_of_a_piece
		smallSquareEl:
			cmp dword ptr[edi], 0
			jne stopMovingEl
			add edi, 4
		loop smallSquareEl
		
		mov edi, eax	;check bottom square of L shape
		add edi, 4*len_of_a_piece
		add edi, 4*area_width*Lshape_heigth
		add edi, 2 +4
		mov ecx, len_of_a_piece
		bottomSquareEl:
			cmp dword ptr [edi], 0
			jne stopMovingEl
			add edi, 4
		loop bottomSquareEl
		jmp finishEl
		
stopMovingEl:
	mov doneMoving, 1
	

finishEl:
popa
mov esp, ebp
pop ebp
ret
checkElBoundary endp


;;;;check line boundary
;arg1 - x
;arg2 - y
checkLineBoundary proc
push ebp
mov ebp, esp
pusha

;;;;;;;;;;;
	mov eax, [ebp+arg2] ;y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1] ;x
	shl eax, 2
	add eax, area
;;;;;;;;;;;

	mov edi, eax
	sub edi, 2
	mov ecx, len_of_a_piece
	leftLine:
		cmp dword ptr[edi], 0
		jne cantMoveLineLeft
		add edi, 4*area_width
	loop leftLine
	mov canMoveLeft, 1
	
	
	mov edi, eax
	add edi, 4*len_of_a_piece
	add edi, 2
	mov ecx, len_of_a_piece
	rightLine:
		cmp dword ptr[edi], 0
		jne cantMoveLineRight
		add edi, 4*area_width
	loop rightLine
	mov canMoveRight, 1
	
	jmp checkStopLine
	
	cantMoveLineLeft:
		mov canMoveLeft, 0
		jmp checkStopLine

	cantMoveLineRight:
		mov canMoveRight, 0
		jmp checkStopLine
		
		
	checkStopLine:
		mov edi, eax
		add edi, 4*area_width*len_of_a_piece
		add edi, 2*area_width+4
		
		mov ecx, 4*len_of_a_piece
		bottomLine:
			cmp dword ptr[edi], 0
			jne stopMovingLine
			add edi, 4
		loop bottomLine
		jmp finishLine
		
stopMovingLine:
	mov doneMoving, 1

finishLine:
popa
mov esp, ebp
pop ebp
ret
checkLineBoundary endp
;---------------------------------------------------------------------------------------------





;---------------------------macros for manipulating the current shape---------------------------
drawCurrentShape_macro macro x, y
local bLine, stop, mShape, bBox, shpL	
	
	
	cmp randomShapeNumber, 3
	jle bBox
	
	cmp randomShapeNumber, 7
	jle mShape
	
	cmp randomShapeNumber, 11
	jle shpL
	
	cmp randomShapeNumber, 15
	jle bLine
	
bLine:
	draw_bigLine x,y
	mov currentShape_height, bigLine_height
	mov currentShape_width, bigLine_width
	mov currentShape_number, 3
	jmp stop

bBox:
	draw_bigBox x,y
	mov currentShape_height, bigBox_height
	mov currentShape_width, bigBox_width
	mov currentShape_number, 0
	jmp stop
	
mShape:
	draw_middleShape x,y
	mov currentShape_height, middleShape_height
	mov currentShape_width, middleShape_width
	mov currentShape_number, 1
	jmp stop
	
shpL:
	draw_Lshape x,y
	mov currentShape_height, Lshape_heigth
	mov currentShape_width, Lshape_width
	mov currentShape_number, 2
	jmp stop

stop:
endm
;;;;;;;
deleteCurrentShape_macro macro x, y
local bLine, stop, mShape, bBox, shpL	
	
	
	cmp randomShapeNumber, 3
	jle bBox
	
	cmp randomShapeNumber, 7
	jle mShape
	
	cmp randomShapeNumber, 11
	jle shpL
	
	cmp randomShapeNumber, 15
	jle bLine
	
bLine:
	delete_bigLine x,y
	jmp stop

bBox:
	delete_bigBox x,y
	jmp stop
	
mShape:
	delete_middleShape x,y
	jmp stop
	
shpL:
	delete_Lshape x,y
	jmp stop

stop:
endm

;-----------------------------------------------------------------------------------




;--------------function for returning a random value between 0-colorsCount----------
giveRandomNumber proc
	push ebp
	mov ebp, esp
	pusha
	
	rdtsc
	xor edx, edx
	div colorsCount
	
	mov randomNumber, edx
	
	popa
	mov esp, ebp
	pop ebp
	ret
giveRandomNumber endp
;-----------------------------------------------------------------------------------


;--------------macros for manipulating a big square-------------------------------------
draw_bigBox macro x, y

;start at topLeft, end bottomRight
  draw_full_square_macro x, y, len_of_a_piece
  
  add x, len_of_a_piece + 1
  draw_full_square_macro x, y, len_of_a_piece
  sub x, len_of_a_piece + 1
  
  add y, len_of_a_piece + 1
  draw_full_square_macro x, y, len_of_a_piece
  sub y, len_of_a_piece + 1
  
  add x, len_of_a_piece + 1
  add y, len_of_a_piece + 1
  draw_full_square_macro x, y, len_of_a_piece
  sub x, len_of_a_piece + 1
  sub y, len_of_a_piece + 1
  
  
endm
;
delete_bigBox macro x,y

;start at topLeft, end at bottomRight
  delete_full_square_macro x, y, len_of_a_piece
  
  add x, len_of_a_piece + 1
  delete_full_square_macro x, y, len_of_a_piece
  sub x, len_of_a_piece + 1
  
  add y, len_of_a_piece + 1
  delete_full_square_macro x, y, len_of_a_piece
  sub y, len_of_a_piece + 1
  
  add x, len_of_a_piece + 1
  add y, len_of_a_piece + 1
  delete_full_square_macro x, y, len_of_a_piece
  sub x, len_of_a_piece + 1
  sub y, len_of_a_piece + 1
endm
;---------------------------------------------------------------------------------


;------------macros for manipulating a straight line------------------------------
draw_bigLine macro x, y

;start at left, end at right
	draw_full_square_macro x, y, len_of_a_piece
	
	add x,  len_of_a_piece + 1
	draw_full_square_macro x , y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add x, 2*len_of_a_piece + 2
	draw_full_square_macro x , y, len_of_a_piece
	sub x, 2*len_of_a_piece + 2
	
	add x, 3*len_of_a_piece + 3
	draw_full_square_macro x , y, len_of_a_piece
	sub x, 3*len_of_a_piece + 3
	
endm
;
delete_bigLine macro x, y
	
;start at left, end at right
	delete_full_square_macro x, y, len_of_a_piece
	
	add x,  len_of_a_piece + 1
	delete_full_square_macro x , y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add x, 2*len_of_a_piece + 2
	delete_full_square_macro x , y, len_of_a_piece
	sub x, 2*len_of_a_piece + 2
	
	add x, 3*len_of_a_piece + 3
	delete_full_square_macro x , y, len_of_a_piece
	sub x, 3*len_of_a_piece + 3
endm
;--------------------------------------------------------------------------


;---------------------macros for manipulating a middleShape----------------------
draw_middleShape macro x, y
	
;start at topMiddlePiece, continue at bottomLeftPiece, end at bottomRightPiece
	add x, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add y, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub y, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, len_of_a_piece + 1
	
	add x, 2*len_of_a_piece + 2
	add y, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub x, 2*len_of_a_piece + 2
	sub y, len_of_a_piece + 1
	
endm
;
delete_middleShape macro x, y

;start at topMiddlePiece, continue at bottomLeftPiece, end at bottomRightPiece
	add x, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add y, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub y, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, len_of_a_piece + 1
	
	add x, 2*len_of_a_piece + 2
	add y, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub x, 2*len_of_a_piece + 2
	sub y, len_of_a_piece + 1
	
endm
;---------------------------------------------------------------------------------


;---------------------macros for manipulating an Lshape-------------------------
draw_Lshape macro x, y
	
;start at (x,y), continuing to rightPiece from (x,y)
;drawing two more squares downwards	
	draw_full_square_macro x, y, len_of_a_piece
	
	add x, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, len_of_a_piece + 1
	draw_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, 2*len_of_a_piece + 2
	draw_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, 2*len_of_a_piece + 2
	
endm
;
delete_Lshape macro x,y

;start at (x,y), continuing to rightPiece from (x,y)
;drawing two more squares downwards
	delete_full_square_macro x, y, len_of_a_piece
	
	add x, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, len_of_a_piece + 1
	delete_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, len_of_a_piece + 1
	
	add x, len_of_a_piece + 1
	add y, 2*len_of_a_piece + 2
	delete_full_square_macro x, y, len_of_a_piece
	sub x, len_of_a_piece + 1
	sub y, 2*len_of_a_piece + 2

endm
;--------------------------------------------------------------------------------


;------macro for drawing a full square-----------
draw_full_square_macro macro x, y, len

local color0,color1,color2,color3,color4,color5,color6
local final_stuff
	
	cmp randomNumber, 0
	je color0
	
	cmp randomNumber, 1
	je color1
	
	cmp randomNumber, 2
	je color2
	
	cmp randomNumber, 3
	je color3
	
	cmp randomNumber, 4
	je color4
	
	cmp randomNumber, 5
	je color5
	
	cmp randomNumber, 6
	je color6
	
color0:
	push color_blue
	jmp final_stuff
color1:
	push color_green
	jmp final_stuff
color2:
	push color_purple
	jmp final_stuff
color3:
	push color_red
	jmp final_stuff
color4:
	push color_hotBlue
	jmp final_stuff
color5:
	push color_yellow
	jmp final_stuff
color6:
	push color_orange
	jmp final_stuff
	
final_stuff:	
	push len
	push y
	push x
	call draw_full_square
	add esp, 16

endm
;-----------------------------------------------


;------macro for deleting a full square----------
delete_full_square_macro macro x, y, len
	push len
	push y
	push x
	call delete_full_square
	add esp, 12

endm

;-----------------------------------------------




;------del char macro------
delete_character macro x, y
	make_text_macro ' ', area, x, y, 0
endm
;-------------------------

;------------------deletes a square at pos x,y of length len-------
delete_square macro x, y, len
	
	draw_empty_square x, y, len, 0
	
endm
;------------------------------------------------------------------






; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
; arg5 - color
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
	mov eax, [ebp+arg5]
	mov dword ptr [edi], eax	; culoare text 0 -> negru
	jmp simbol_pixel_next
	
simbol_pixel_alb:
	mov dword ptr [edi], 0; culoare fundal text
	
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
make_text_macro macro symbol, drawArea, x, y, color
	push color
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 20
endm

;-------------horizontal line macro---------------
draw_horizontal macro x, y, len, color
local for_loop
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	
	mov ecx, len
	for_loop:
		mov dword ptr[eax], color
		add eax, 4
	loop for_loop
endm
;------------------------------------------------

;-------------vertical line macro----------------
draw_vertical macro x, y, len, color
local for_loop
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	
	mov ecx, len
	for_loop:
		mov dword ptr[eax], color
		add eax, 4*area_width
	loop for_loop
endm
;------------------------------------------------

;-----------procedure to draw a full len*len square at (x,y) of a color--------------------------------------
;arg1 - x
;arg2 - y
;arg3 - len
;arg4 - color
draw_full_square proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg2]	; y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1]	; x
	shl eax, 2
	add eax, area
	
	
	
	mov edi, [ebp+arg4]
	mov ecx, [ebp+arg3]
	
	
	mov edx, ecx
	mov ebx, ecx
	for_i:
		push eax
		push ecx
		mov edx, 0
			for_j:
			mov dword ptr [eax], edi
			
			add eax, 4
			inc edx
			cmp edx, ebx
			jl for_j
			
		pop ecx
		pop eax
		add eax, 4*area_width
		loop for_i
	
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw_full_square endp
;-------------------------------------------------------------------------------------------------------------------

;---------------------delete full square----------------------------------------------------------------------------
;arg1 - x
;arg2 - y
;arg3 - len

delete_full_square proc
push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg2]	; y
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1]	; x
	shl eax, 2
	add eax, area
	
	
	mov ecx, [ebp+arg3]
	
	
	mov edx, ecx
	mov ebx, ecx
	for_i:
		push eax
		push ecx
		mov edx, 0
			for_j:
			mov dword ptr [eax], 0
			
			add eax, 4
			inc edx
			cmp edx, ebx
			jl for_j
			
		pop ecx
		pop eax
		add eax, 4*area_width
		loop for_i
	
	
	popa
	mov esp, ebp
	pop ebp
	ret
delete_full_square endp
;-------------------------------------------------------------------------------------------------------------------


;----------------------------drawing game frame macro------------------------------
draw_game_frame macro x, y														  ;
																				  ;
	draw_horizontal x, y, game_frame_width, 0FFFFFFh							  ;
	draw_horizontal x, y + game_frame_heigth, game_frame_width, 0FFFFFFh		  ;
																				  ;
	draw_vertical x, y, game_frame_heigth, 0FFFFFFh								  ;
	draw_vertical x + game_frame_width, y, game_frame_heigth, 0FFFFFFh			  ;
endm																			  ;
;----------------------------------------------------------------------------------

;------------draw an empty square of len*len at (x,y)------------------------------
draw_empty_square macro x, y, len, color
	
	draw_horizontal x, y, len, color
	add y, len
	draw_horizontal x, y, len, color
	sub y, len
	
	draw_vertical x, y, len, color
	add x, len
	draw_vertical x, y, len, color
	sub x, len
	
endm
;----------------------------------------------------------------------------------


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	;;;;;
	cmp game_over_flag, 1
	je game_over
	;;;;;
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	jg evt_key

	
	;mai jos e codul care intializeaza fereastra cu pixeli negri
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0		; culoarea fundalului: negru
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	
evt_key:
	mov eax, [ebp+arg2]		; eax = codul ascii al key-ului
	; cmp eax, 'X'
	; je draw_x
	
	cmp eax, 'A'
	je move_left
	
	cmp eax, 'D'
	je move_right
	
	cmp new_piece_flag, 1
	jne afisare_litere
	
	mov new_piece_flag, 0
	jmp afisare_litere
	
		
	
	move_right:	;;moves right
		mov edx, 439
		sub edx, currentShape_width
		cmp currentX, edx
		jge afisare_litere
		
		; checkBoundaries_macro currentX, currentY
		; cmp canMoveRight, 1
		; jne afisare_litere
		
		
		;------verificare margina dreapta-----	
		deleteCurrentShape_macro currentX, currentY
		add currentX, moving_rate + 1
		drawCurrentShape_macro currentX,currentY
		jmp afisare_litere
		
		
	move_left:	;;moves left
		cmp currentX, 133
		jle afisare_litere
		; checkBoundaries_macro currentx, currentY
		; cmp canMoveLeft, 1
		; jne afisare_litere
		
		;------verificare margina stanga------
		deleteCurrentShape_macro currentX, currentY
		sub currentX, moving_rate + 1
		drawCurrentShape_macro currentX, currentY
		jmp afisare_litere
		
	
	
evt_click:
	inc clicks
	jmp afisare_litere
	
	
evt_timer:
	;;;;
	
;;;;;;;;;;;;;;;;;;;;
afisare_litere:
	
	mov eax, currentY
	add eax, currentShape_height	; add height of the current piece to check lower boundary
	add eax, 2
	mov ebx, area_width
	mul ebx		
	add eax, currentX
	shl eax, 2
	add eax, area
	
	add eax, 4*area_width

	falling:
		mov edx, 110
		add edx, game_frame_heigth
		sub edx, currentShape_height
		sub edx, falling_rate
	
		cmp currentY, edx;110 + game_frame_heigth - currentShape_height - falling_rate
		jge finished_falling
		
		cmp dword ptr[eax], 0
		jne finished_falling
		
		; checkBoundaries_macro currentX, currentY
		; cmp doneMoving, 1
		; je finished_falling
		
		deleteCurrentShape_macro currentX, currentY
		add currentY, 3
		drawCurrentShape_macro currentX, currentY
		jmp afisari


finished_falling:
	cmp currentY, startPositionY
	je game_over

	inc counter						;; counter for score, each piece -> +1 score
	mov currentX, startPositionX	;; reincep secventa de cadere
	mov currentY, startPositionY
	mov new_piece_flag, 1
	call giveRandomNumber
	call giveRandomShape
	
	
afisari:	
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 585, 10, 0FFFFFFh
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 575, 10, 0FFFFFFh
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 565, 10, 0FFFFFFh
	
	
	;titlul
	make_text_macro 'T', area, 255, 30, 03ef05fh
	make_text_macro 'E', area, 265, 30, 03ef05fh
	make_text_macro 'T', area, 275, 30, 03ef05fh	; turcuaz
	make_text_macro 'R', area, 285, 30, 03ef05fh
	make_text_macro 'I', area, 295, 30, 03ef05fh
	make_text_macro 'S', area, 305, 30, 03ef05fh
	
	
	;zona de scor
	make_text_macro 'S', area, 500, 10, 0EBAC1Ah
	make_text_macro 'C', area, 510, 10, 0EBAC1Ah	;PORTOCALIU
	make_text_macro 'O', area, 520, 10, 0EBAC1Ah
	make_text_macro 'R', area, 530, 10, 0EBAC1Ah
	make_text_macro 'E', area, 540, 10, 0EBAC1Ah
	
	
	;locul de deasupra patratului gol, unde se va afisam
	;urmatorul shape
	make_text_macro 'N', area, 470, 180, 0e324d9h
	make_text_macro 'E', area, 480, 180, 0e324d9h
	make_text_macro 'X', area, 490, 180, 0e324d9h	; roz->mov
	make_text_macro 'T', area, 500, 180, 0e324d9h
	
	make_text_macro 'S', area, 520, 180, 0b02ee8h
	make_text_macro 'H', area, 530, 180, 0b02ee8h
	make_text_macro 'A', area, 540, 180, 0b02ee8h	; MOV
	make_text_macro 'P', area, 550, 180, 0b02ee8h
	make_text_macro 'E', area, 560, 180, 0b02ee8h
	
	
	;draw game frame at (130,110) of size (game_frame_width * game_frame_heigth)
	draw_game_frame	130, 110
	
	
	
	;draws the empty square under the "Next shape" text
	draw_empty_square right_squareX, right_squareY, 110, 0FFFFFFh
	;call nextShape_draw
	jmp final_draw
	
	
	cmp lastLine_isFull, 1
	je print_t
	jmp final_draw
	
	print_t:
		push offset format_debug
		call printf
		add esp, 4
	
	game_over:
		mov game_over_flag, 1
	
		make_text_macro 'G', area, 240, 300, game_over_color1
		make_text_macro 'A', area, 250, 300, game_over_color2
		make_text_macro 'M', area, 260, 300, game_over_color1
		make_text_macro 'E', area, 270, 300, game_over_color2
		
		make_text_macro 'O', area, 290, 301, game_over_color1
		make_text_macro 'V', area, 300, 299, game_over_color2
		make_text_macro 'E', area, 310, 301, game_over_color1
		make_text_macro 'R', area, 320, 299, game_over_color2
		
		draw_horizontal 230, 298, 110, game_over_color1
		draw_horizontal 230, 298+25, 110, game_over_color2
		draw_vertical 230, 298, 25, game_over_color1
		draw_vertical 230 +110, 298, 25, game_over_color2
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp



start:
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
