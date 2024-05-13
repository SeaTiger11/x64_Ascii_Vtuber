;--------------------------------------------------------------------
;	x86 Ascii Vtuber coded and designed by Riley Tiger Page - 2024	
;--------------------------------------------------------------------

global _start

section .data
	formatting: db 27, "[H", 27, "[2J"
	formattingLength: equ $-formatting

	output: times 10100 db " "
	outputLength equ $-output

	screenSize: dd 101d
	total: dd 10099

	;	3 numbers for position, 3 numbers for colour
	vertices: dd 50, 10, 0, 255, 0, 0,		80, 80, 0, 0, 255, 0,		20, 40, 0, 0, 0, 255
	verticesLength equ $-vertices

	timeval:
    tv_sec  dd 0
    tv_usec dd 30000000						; 20fps

	;	27 = ESC, 91 = [, 51 = 3, 48 = 0, 109 = m		Does an ascii escape sequence to change the colour to 30 (black)
	colours: db 27, 91, 51, 48, 109
	coloursLength equ $-colours

	triangleLayers: times 800 db -1

section .text

;	Line Drawing Algorithm
;	r8d		-	x0
;	r9d		-	y0
;	r10d	-	dx
;	r11d	-	sx
;	r12d	-	dy
;	r13d	-	sy
;	r14d	-	e

;	eax		-	math and e2
;	ebx		-	math
;	ecx		-	vertex1 buffer
;	edx		-	vertex2 buffer
;	edi		-	if line has been flipped

;	bh, bl	-	partial checks for flip check
DrawLine:
	;	Flip and reversing of the line for Bresenham
	mov edi, 0

	mov eax, [vertices + ecx]					; if (x0 > x1 and y1 > y0) or (x0 < x1 and y1 < y0) 
	cmp eax, [vertices + edx]
	setg bh

	mov eax, [vertices + edx + 4]
	cmp eax, [vertices + ecx + 4]
	setg bl

	cmp bh, bl
	jne NoSwap
		mov eax, [vertices + ecx]
		mov dword [vertices + ecx], 99
		sub [vertices + ecx], eax

		mov eax, [vertices + edx]
		mov dword [vertices + edx], 99
		sub [vertices + edx], eax

		mov edi, 1
	NoSwap:

	mov eax, [vertices + ecx]					; if x0 > x1 then reverse directions
	cmp eax, [vertices + edx]								
	jle NoReverse
		mov eax, ecx
		mov ecx, edx
		mov edx, eax
	NoReverse:

	;	Bresenhams Algorithm

	mov r8d, [vertices + ecx]					; x0
	mov r9d, [vertices + ecx + 4]				; y0
	
	mov r10d, [vertices + edx]					; dx = x1 - x0
	sub r10d, r8d

	cmp r8d, [vertices + edx]					; if x0 < x1 then sx = 1 else sx = -1
	jge HigherX
	mov r11d, 1
	jmp Skip2

	HigherX:
	mov r11d, -1

	Skip2:

	mov r12d, [vertices + edx + 4]				; dy = -(y1 - y0)
	sub r12d, r9d
	neg r12d

	cmp r9d, [vertices + edx + 4]				; if y0 < y1 then sy = 1 else sy = -1
	jge HigherY
	mov r13d, 1
	jmp Skip3

	HigherY:
	mov r13d, -1

	Skip3:

	mov r14d, r10d								; e = dx + dy
	add r14d, r12d

	Loop2:
		mov eax, r9d							; y offset in screen buffer
		imul eax, dword [screenSize]

		test edi, edi
		jnz FlippedOutput
			mov ebx, r8d
			jmp FlippedOutputEnd
		FlippedOutput:
			mov ebx, 99
			sub ebx, r8d
		FlippedOutputEnd:

		mov byte [output + eax + ebx], "@"		; Draw "pixel"

		;	Updating the triangle layer array for filling in later

		mov eax, r9d							; The appropriate row in the triangle layers array
		imul eax, 8

		cmp byte [triangleLayers + eax], -1		; If the layer is empty, set the current x position to the lowest and highest value
		je TriLayEmpty

		cmp [triangleLayers + eax], ebx			; If the current x is lower than the previously stored lowest x then replace
		jg TriLayLow	
		
		cmp [triangleLayers + eax + 4], ebx		; If the current x is higher than the previously stored highest x then replace
		jge Skip4

		mov [triangleLayers + eax + 4], ebx		; Replace the higher x
		jmp Skip4

		TriLayLow:								; Replace the lower x
		mov [triangleLayers + eax], ebx
		jmp Skip4

		TriLayEmpty:							; Replace the lower and higher x
		mov [triangleLayers + eax], ebx
		mov [triangleLayers + eax + 4], ebx

		Skip4:

		;	End of filling triangle layer array

		cmp r8d, [vertices + edx]				; if x0 == x1 and y0 == y1 then Break
		jne Skip5
			cmp r9d, [vertices + edx + 4]
			je Break

		Skip5:

		mov eax, r14d							; e2 = 2e
		imul eax, 2

		cmp eax, r12d							; if e2 >= dy
		jl Skip6

			cmp r8d, [vertices + edx]			; if x0 == x1 then Break
			je Break

			add r14d, r12d						; e = e + dy
			add r8d, r11d						; x0 = x0 + sx

		Skip6:

		cmp eax, r10d							; if e2 <= dx
		jg Skip7

			cmp r9d, [vertices + edx + 4]		; if y0 == y1 then Break
			je Break

			add r14d, r10d						; e = e + dx
			add r9d, r13d						; y0 = y0 + sy

		Skip7:

		jmp Loop2
	Break:
		test edi, edi							; If x0 and x1 were flipped, flip them back
		jz NotFlipped
			mov eax, [vertices + ecx]
			mov dword [vertices + ecx], 99
			sub [vertices + ecx], eax

			mov eax, [vertices + edx]
			mov dword [vertices + edx], 99
			sub [vertices + edx], eax
		NotFlipped:
		ret






;	Code entry point and main sequence
_start:
	;	Screen "Buffer" Formatting
	mov eax, 0									; Total counter
	mov ebx, 1									; Counter in current line
	Loop1:
		cmp ebx, [screenSize]
		je Skip1
		mov byte [output + eax],	" "

		inc eax
		inc ebx
		jmp Loop1

		Skip1:
		mov byte [output + eax],	0xA

		inc eax
		mov ebx, 1

		cmp eax, dword [total]
		jl Loop1

	;	Triangle rasterizer
	DrawTriangle:

	mov eax, -1									; Reset the triangle layer array
	lea edi, triangleLayers
	mov ecx, 800
	cld
	rep stosb

	mov ecx, 0
	mov edx, 24

	call DrawLine

	mov ecx, 0
	mov edx, 48

	call DrawLine

	mov ecx, 24
	mov edx, 48

	call DrawLine

	;	Fill the triangle
	mov ebx, 0									; Row buffer		
	mov esi, 0
	NextRow:
	add ebx, 8
	cmp ebx, 800
	je Filled
	mov ecx, [triangleLayers + ebx]				; Start of filled row
	mov edx, [triangleLayers + ebx + 4]			; End of filled row
	mov edi, ecx								; Coloumn counter
	inc esi										; Row counter
	NextColumn:
	cmp edi, edx
	je NextRow

	mov eax, esi								; y offset in screen buffer
	imul eax, dword [screenSize]

	mov byte [output + edi + eax], "@"			; draw pixel at (x0, y0)

	inc edi

	jmp NextColumn

	Filled:

	;	End of triangle rasterizer

	;	Screen clearing
	mov	eax, 4									; Specify sys_write call
	mov ebx, 1									; Specify File Descriptor 1: Stdout
	mov ecx, formatting							; Pass message string
	mov edx, formattingLength					; Pass the length of the message string
	int 0x80


	;	Output
	mov	eax, 4									; Specify sys_write call
	mov ebx, 1									; Specify File Descriptor 1: Stdout
	mov ecx, output								; Pass message string
	mov edx, outputLength						; Pass the length of the message string
	int 0x80


	;	Project exit
	mov eax, 1									; Exits the program
	mov ebx, 0
	int 0x80