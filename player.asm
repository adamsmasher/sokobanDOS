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
