		BITS	16
		ORG	0x100				; DOS loads us here
Start:		; backup old KB interrupt
		XOR	AX, AX
		MOV	ES, AX				; ES = 0
		MOV	AX, [ES:0x24]
		MOV	[OldKBHandler], AX
		MOV	AX, [ES:0x26]
		MOV	[OldKBHandler + 2], AX
		; install new KB interrupt
		MOV	WORD [ES:0x24], KBHandler
		MOV	WORD [ES:0x26], CS
		; set video mode 0x13
		MOV	AX, 0x13
		INT	0x10
		; make ES point to the VGA memory
		MOV	AX, 0xA000
		MOV	ES, AX
		CALL	DrawBoard
		CALL	DrawPlayer
.gameLoop:	CALL	WaitFrame
		CALL	UpdatePlayer
		; check for exit
		CMP	BYTE [Quit], 1
		JNZ	.gameLoop
		; restore text mode 0x03
		MOV	AX, 0x03
		INT	0x10
		; restore old KB interrupt
		XOR	AX, AX
		MOV	ES, AX
		MOV	AX, [OldKBHandler]
		MOV	[ES:0x24], AX
		MOV	AX, [OldKBHandler + 2]
		MOV	[ES:0x26], AX
		; exit
		MOV	AX, 0x4C00			; return code 0
		INT	0x21

OldKBHandler:	DD	0

Quit:		DB	0

%include "board.asm"
%include "boxes.asm"
%include "draw.asm"
%include "kb.asm"
%include "player.asm"
%include "video.asm"
