PlayerPos:
PlayerRow:	DB	START_ROW
PlayerCol:	DB	START_COL

MoveDir:	DW	0

PlayerScrBase:	DW	START_ROW * 320 * 16 + START_COL * 16
UnderTile:	DB	0

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
		MOV	AX, [MoveDir]
		AND	AX, AX				; are we moving?
		JZ	.done
		; get index into move table into SI
		MOV	SI, AX
		DEC	SI
		SHL	SI, 1				; *2 for word addrs
		MOV	AX, [PlayerPos]
		ADD	AL, [MoveTable + SI]		; get new tile
		ADD	AH, [MoveTable + SI + 1]
		MOV	BX, AX				; backup new pos
		CALL	Shove
		MOV	AX, BX
		CALL	CanWalk				; is this tile clear?
		JNZ	.clearMove
		MOV	AX, BX
.move:		CALL	ErasePlayer
		MOV	[PlayerPos], BX			; update new pos
		MOV	AX, [MoveTable2 + SI]
		ADD	[PlayerScrBase], AX
		CALL	UpdateUnder
		CALL	DrawPlayer			; draw the player
.clearMove:	MOV	BYTE [MoveDir], 0
.done:		POP	BX
		POP	SI
		RET

; AX - contains position to be shoved
; SI - contains index into move table
Shove:		PUSH	BX
		MOV	BX, AX				; backup pos
		CALL	FindBox
		JNE	.done
		SUB	AX, 2
		XCHG	AX, BX				; put box ptr into BX
		; check if the shove destination is clear
		ADD	AL, [MoveTable + SI]
		ADD	AH, [MoveTable + SI + 1]
		PUSH	AX				; backup shove dest
		CALL	CanWalk
		POP	AX				; get shove dest
		JNZ	.done
		MOV	[BX], AX			; update box data
.done:		POP	BX
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
