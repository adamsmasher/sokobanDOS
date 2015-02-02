		BITS	16
		ORG	0x100				; DOS loads us here
Start:		CALL	InstallKB
		CALL	InitVideo
		CALL	DrawBoard
		CALL	DrawPlayer
.gameLoop:	CALL	WaitFrame
		CALL	UpdatePlayer
		; check for exit
		CMP	BYTE [Quit], 1
		JNZ	.gameLoop
		CALL	RestoreVideo
		CALL	RestoreKB
		; exit
		MOV	AX, 0x4C00			; return code 0
		INT	0x21

Quit:		DB	0

%include "board.asm"
%include "boxes.asm"
%include "draw.asm"
%include "kb.asm"
%include "player.asm"
%include "video.asm"
