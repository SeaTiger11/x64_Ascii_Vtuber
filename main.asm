;--------------------------------------------------------------------
;	x86 Ascii Vtuber coded and designed by Riley Tiger Page - 2024	
;--------------------------------------------------------------------

global _start

section .data
	;density:	db	"$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\|()1{}[]?-_+~<>i!lI;:,^`'. "
	;densityLength equ $-density

	formatting: db 27, "[H", 27, "[2J"
	formattingLength: equ $-formatting

	output: times 10100 db " "
	outputLength equ $-output

	screenSize: dd 101d
	total: dd 10099

	;	3 numbers for position, 3 numbers for colour
	vertices: dd 0, 0, 100, 255, 0, 0,		99, 0, 100, 0, 255, 0,		-50, -50, 100, 0, 0, 255
	verticesLength equ $-vertices

	timeval:
    tv_sec  dd 0
    tv_usec dd 30000000						; 20fps

	sign: dd 1

	;	27 = ESC, 91 = [, 51 = 3, 48 = 0, 109 = m		Does an ascii escape sequence to change the colour to 30 (black)
	colours: db 27, 91, 51, 48, 109
	coloursLength equ $-colours

section .text

_start:
	;	Screen "Buffer" Formatting
	mov eax, 0								; Total counter
	mov ebx, 1								; Counter in current line
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


	;	Bresenham line drawing algorithm
	mov ebx, [vertices]						; x0
	mov ecx, [vertices + 4]					; y0
	
	mov esp, [vertices + 24]					; dx = x1 - x0
	sub esp, ebx

	cmp ebx, [vertices + 24]					; if x0 < x1 then sx = 1 else sx = -1
	jge HigherX
	mov ebp, 1
	jmp Skip2

	HigherX:
	mov ebp, -1

	Skip2:

	mov edi, [vertices + 28]					; dy = -(y1 - y0)
	sub edi, ecx
	neg edi

	cmp ecx, [vertices + 28]					; if y0 < y1 then sy = 1 else sy = -1
	jge HigherY
	mov esi, 1
	jmp Skip3

	HigherY:
	mov esi, -1

	Skip3:

	mov edx, esp								; e = dx + dy
	add edx, edi

	Loop2:
		mov eax, ecx							; y offset in screen buffer
		imul eax, dword [screenSize]

		mov byte [output + ebx + eax], "@"		; draw pixel at (x0, y0)

		cmp ebx, [vertices + 24]				; if x0 == x1 and y0 == y1 then break
		jne Skip4
			cmp ecx, [vertices + 28]
			je Break

		Skip4:

		mov eax, edx							; e2 = 2e
		imul eax, 2

		cmp eax, edi							; if e2 >= dy
		jl Skip5

			cmp ebx, [vertices + 24]			; if x0 == x1 then break
			je Break

			add edx, edi						; e = e + dy
			add ebx, ebp						; x0 = x0 + sx

		Skip5:

		cmp eax, esp							; if e2 <= dx
		jg Skip6

			cmp ecx, [vertices + 28]			; if y0 == y1 then break
			je Break

			add edx, esp						; e = e + dx
			add ecx, esi						; y0 = y0 + sy

		Skip6:

		jmp Loop2
	Break:


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


	;	Delay
	mov eax, 162
	mov ebx, timeval
	mov ecx, 0
	int 0x80

	mov eax, [sign]
	add dword [vertices + 28], eax

	cmp dword [vertices + 28], 100
	jge Flip
	cmp dword [vertices + 28], 0
	jle Flip

	jmp _start

	Flip:
	neg eax
	add dword [vertices + 28], eax
	mov [sign], eax

	;	Set new colour
	inc byte [colours + 3]
	cmp byte [colours + 3], 55
	jle Skip7
		mov byte [colours + 3], 49
	Skip7:

	mov eax, 4
	mov ebx, 1
	mov ecx, colours
	mov edx, coloursLength
	int 0x80

	jmp _start


	;	Project exit
	mov eax, 1									; Exits the program
	mov ebx, 0
	int 0x80