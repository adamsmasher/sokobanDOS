		; tell NASM we want 16-bit assembly language
		BITS	16
		ORG	0x100				; DOS loads us here
Start:		CALL	InstallKB
		CALL	InitVideo
		CALL	DrawPixel
.gameLoop:	CALL	WaitFrame
		CMP	BYTE [Quit], 1
		JNE	.gameLoop			; loop if counter > 0
		CALL	RestoreVideo
		CALL	RestoreKB
		; exit
		MOV	AX, 0x4C00
		INT	0x21

Quit:		DB	0

%include "kb.asm"
%include "video.asm"
