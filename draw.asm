ScrBase:	DW	0

PlayerTile:	INCBIN	"player.dat"

Tiles:		INCBIN	"wall.dat"
		INCBIN	"box.dat"

DrawBoard:	PUSHA
		MOV	SI, 0				; index into board
		MOV	CH, 0				; row
		MOV	WORD [ScrBase], 0
.drawRow:	MOV	CL, 0				; col
.rowLoop:	MOV	AL, [Board + SI]		; get tile
		CMP	AL, 0				; is tile 0?
		JZ	.nextTile
		DEC	AL
.drawTile:	CALL	DrawTile
.nextTile:	ADD	WORD [ScrBase], 16
		INC	SI
		INC	CL
		CMP	CL, BOARD_WIDTH
		JNZ	.rowLoop
		ADD	WORD [ScrBase], 320 * 16 - 16 * BOARD_WIDTH
		INC	CH
		CMP	CH, BOARD_HEIGHT
		JNZ	.drawRow
		POPA
		RET

; AL = Tile #
DrawTile:	PUSH	SI
		PUSH	DI
		SHL	AX, 8				; get tile index
		ADD	AX, Tiles			; get pointer
		MOV	SI, AX
		MOV	DI, [ScrBase]
		CALL	BlitTile
		POP	DI
		POP	SI
		RET

EraseTile:	PUSH	DI
		PUSH	CX
		PUSH	DX
		MOV	DI, [ScrBase]
		XOR	AX, AX				; clear AX
		CLD					; increment
		MOV	CH, 0				; clear hi-counter
		MOV	DL, 0x10			; 16 rows
.row:		MOV	CL, 0x08			; 8 word writes
		REP	STOSW				; write 0000
		DEC	DL				; next row?
		JZ	.done
		ADD	DI, 304				; next row
		JMP	.row
.done:		POP	DX
		POP	CX
		POP	DI
		RET

ErasePlayer:	MOV	AX, [PlayerScrBase]
		MOV	[ScrBase], AX
		MOV	AL, [UnderTile]
		AND	AL, AL
		JZ	EraseTile
		DEC	AL
		JMP	DrawTile

DrawPlayer:	PUSH	SI
		PUSH	DI
		MOV	SI, PlayerTile
		MOV	DI, [PlayerScrBase]
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

