START_ROW	EQU	2
START_COL	EQU	2

BOARD_WIDTH	EQU	8
BOARD_HEIGHT	EQU	9

WALL		EQU	1
TARGET		EQU	2

Board:		INCBIN	"board.dat"

BoxesOn:	DB	1

TARGET_CNT	EQU	7

; AX = packed tile coordinates (L = row, H = col)
; returns in AX the offset into the board
GetTileOffset:	SHL	AL, 3
		ADD	AL, AH
		XOR	AH, AH
		RET

; AX = packed tile coordinates
; sets E if the tile is a target
IsTarget:	PUSH	SI
		CALL	GetTileOffset
		MOV	SI, AX
		CMP	BYTE [Board + SI], TARGET
		POP	SI
		RET

; AX = tile we're checking
; sets NE if we can walk
CanWalk:	PUSH	BX
		MOV	BX, AX				; backup tile
		CALL	CanWalkBoard
		JE	.done				; space has a wall
		MOV	AX, BX				; get tile
		CALL	FindBox
.done:		POP	BX
		RET

; AX = tile we're checking
; sets NE if we can walk
CanWalkBoard:	PUSH	SI
		CALL	GetTileOffset
		MOV	SI, AX
		CMP	BYTE [Board + SI], WALL
		POP	SI
		RET
