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
		CALL	DrawBoard
		CALL	DrawPlayer
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


DrawBoard:	PUSHA
		MOV	BX, Board
		MOV	SI, 0				; index into board
		MOV	CH, 0				; row
		MOV	WORD [RowBase], 0
.drawRow:	MOV	WORD [TileBase], 0
		MOV	CL, 0				; col
.rowLoop:	MOV	AL, [BX + SI]			; get tile
		CMP	AL, 0				; is tile 0?
		JZ	.nextTile
		DEC	AL
		CALL	DrawTile
.nextTile:	ADD	WORD [TileBase], 16
		INC	SI
		INC	CL
		CMP	CL, 8
		JNZ	.rowLoop
		ADD	WORD [RowBase], 5120
		INC	CH
		CMP	CH, 9
		JNZ	.drawRow
		POPA
		RET


; AL = Tile #
DrawTile:	PUSH	SI
		PUSH	DI
		MOV	AH, 0				; clear out high bits
		SHL	AX, 8				; get tile index
		ADD	AX, Tiles			; get pointer
		MOV	SI, AX
		MOV	DI, [RowBase]
		ADD	DI, [TileBase]
		CALL	BlitTile
		POP	DI
		POP	SI
		RET


DrawPlayer:	PUSH	SI
		PUSH	DI
		MOV	SI, PlayerTile
		MOV	DI, [PlayerRowBase]
		ADD	DI, [PlayerTileBase]
		CALL	BlitTile
		POP	DI
		POP	SI
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

RowBase:	DW	0
TileBase:	DW	0
PlayerRowBase:	DW	2 * 320 * 16
PlayerTileBase:	DW	2 * 16

Board:		INCBIN	"board.dat"

PlayerTile:	INCBIN	"player.dat"

Tiles:		INCBIN	"wall.dat"

OldKBHandler:	DD	0

Quit:		DB	0
