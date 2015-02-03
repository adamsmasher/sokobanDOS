		; tell NASM we want 16-bit assembly language
		BITS	16
		ORG	0x100				; DOS loads us here
Start:		CALL	InstallKB
		CALL	InitVideo
		CALL	DrawBoard
		CALL	DrawPlayer
		CALL	DrawBoxes
.gameLoop:	CALL	WaitFrame
		CALL	EraseBoxes
		CALL	UpdatePlayer
		CALL	DrawBoxes
		CALL	CheckForWin
		; check for exit
		CMP	BYTE [Quit], 1
		JNZ	.gameLoop
		CALL	RestoreVideo
		CALL	RestoreKB
		; exit
		MOV	AX, 0x4C00			; return code 0
		INT	0x21

CheckForWin:	CMP	BYTE [BoxesOn], TARGET_CNT
		JNE	.done
		MOV	BYTE [Quit], 1
.done:		RET

Quit:		DB	0

%include "board.asm"
%include "boxes.asm"
%include "draw.asm"
%include "kb.asm"
%include "player.asm"
%include "video.asm"
