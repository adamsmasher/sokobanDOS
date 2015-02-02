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

; AX = packed tile coordinates (L = row, H = col)
; returns in AX the offset into the board
GetTileOffset:	SHL	AL, 3
		ADD	AL, AH
		XOR	AH, AH
		RET

DrawBoard:	PUSHA
		MOV	SI, 0				; index into board
		MOV	CH, 0				; row
		MOV	WORD [ScrBase], 0
.drawRow:	MOV	CL, 0				; col
.rowLoop:	CALL	FindBox
		JNE	.checkTile
		MOV	AL, 1				; box is tile 1
		JMP	.drawTile
.checkTile:	MOV	AL, [Board + SI]		; get tile
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


; how to update the player coordinates (board)
MoveTable:
.up:		DB	-1
		DB	0
.left:		DB	0
		DB	-1
.right:		DB	0
		DB	1
.down:		DB	1
		DB	0
; how to update the player coordinates (screen)
MoveTable2:
.up:		DW	-16 * 320
.left:		DW	-16
.right:		DW	16
.down:		DW	16 * 320
UpdatePlayer:	PUSH	SI
		PUSH	BX
		MOV	AL, [MoveDir]
		AND	AL, AL				; are we moving?
		JZ	.done
		; get index into move table into SI
		XOR	AH, AH				; clear hi bit
		MOV	[MoveDir], AH			; clear motion
		MOV	SI, AX
		DEC	SI
		SHL	SI, 1				; *2 for word addrs
		MOV	AX, [PlayerPos]
		ADD	AL, [MoveTable + SI]		; get new tile
		ADD	AH, [MoveTable + SI + 1]
		MOV	BX, AX				; backup new pos
		CALL	CanWalk				; is this tile clear?
		JNZ	.done
		CALL	ErasePlayer
		MOV	[PlayerPos], BX			; update new pos
		MOV	AX, [MoveTable2 + SI]
		ADD	[PlayerScrBase], AX
		CALL	UpdateUnder
		CALL	DrawPlayer			; draw the player
.done:		POP	BX
		POP	SI
		RET


; AX = tile we're checking
; sets E if we can walk
CanWalk:	PUSH	SI
		CALL	GetTileOffset
		MOV	SI, AX
		CMP	BYTE [Board + SI], 0
		POP	SI
		RET

; CX = box to find
; sets E if the box was found
; returns a pointer in AX if the box is found
FindBox:	PUSH	ES
		PUSH	DI
		MOV	AX, DS
		MOV	ES, AX
		MOV	AX, CX
		MOV	CX, [BoxCnt]
		; iterate through until we find a matching box or run out of
		; boxes
		MOV	DI, Boxes
		REPNE	SCASW
		MOV	CX, AX				; restore CX
		MOV	AX, DI				; return pointer in AX
		POP	DI
		POP	ES
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


UpdateUnder:	PUSH	SI
		XOR	AH, AH
		MOV	AL, [PlayerRow]
		SHL	AL, 3				; row * 8 bc 8 cols/row
		ADD	AL, BYTE [PlayerCol]
		MOV	SI, AX
		MOV	AL, [Board + SI]
		MOV	[UnderTile], AL
		POP SI
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

ScrBase:	DW	0

START_ROW	EQU	2
START_COL	EQU	2

PlayerPos:
PlayerRow:	DB	START_ROW
PlayerCol:	DB	START_COL

MoveDir:	DW	0

PlayerScrBase:	DW	START_ROW * 320 * 16 + START_COL * 16
UnderTile:	DB	0

BOARD_WIDTH	EQU	8
BOARD_HEIGHT	EQU	9
Board:		INCBIN	"board.dat"

BoxCnt:		DW	7
Boxes:		DW	0x0203
		DW	0x0304
		DW	0x0404
		DW	0x0604
		DW	0x0605
		DW	0x0603
		DW	0x0601

PlayerTile:	INCBIN	"player.dat"

Tiles:		INCBIN	"wall.dat"
		INCBIN	"box.dat"

OldKBHandler:	DD	0

Quit:		DB	0

%include "kb.asm"
