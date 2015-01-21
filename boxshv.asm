		BITS	16
		ORG	0x100				; DOS loads us here
Start:		; backup old KB interrupt
		XOR	AX, AX
		MOV	ES, AX				; ES = 0
		MOV	AX, [ES:0x24]
		MOV	[OldKBHandler], AX
		MOV	AX, [ES:0x26]
		MOV	[OldKBHandler + 2], AX
;		; install new KB interrupt
		MOV	WORD [ES:0x24], KBHandler
		MOV	WORD [ES:0x26], CS
		; set video mode 0x13
		MOV	AX, 0x13
		INT	0x10
		; make ES point to the VGA memory
		MOV	AX, 0xA000
		MOV	ES, AX
		; draw a tile
		MOV	SI, Tiles
		MOV	DI, 0
		CALL	BlitTile
.gameLoop:	CALL	WaitFrame
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

KBHandler:	PUSH	AX
		IN	AL, 0x60			; get key event
		CMP	AL, 0x01			; ESC pressed?
		JNE	.done
		MOV	[Quit], AL
.done:		MOV	AL, 0x20			; ACK
		OUT	0x20, AL			; send ACK
		POP	AX
		IRET

WaitFrame:	PUSH	DX
		MOV	DX, 0x03DA
.waitRetrace:	IN	AL, DX
		TEST	AL, 0x08			; are we in retrace?
		JNZ	.waitRetrace
.endRefresh:	IN	AL, DX
		TEST	AL, 0x08			; are we in refresh?
		JZ	.endRefresh
		POP DX
		RET


; SI = Tile*, DI = Dest*
BlitTile:	PUSH	CX
		PUSH	DX
		CLD					; increment
		MOV	CH, 0				; clear hi-counter
		MOV	DL, 0x10			; 16 rows
.row:		MOV	CL, 0x08			; 8 word copies
		REP	MOVSW
		DEC	DL
		JZ	.done
		ADD	DI, 304				; move to next row
		JMP	.row
.done:		POP	DX
		POP	CX
		RET

Tiles:		INCBIN	"wall.dat"

OldKBHandler:	DD	0

Quit:		DB	0
