START_ROW	EQU	2
START_COL	EQU	2

BOARD_WIDTH	EQU	8
BOARD_HEIGHT	EQU	9
Board:		INCBIN	"board.dat"

; AX = packed tile coordinates (L = row, H = col)
; returns in AX the offset into the board
GetTileOffset:	SHL	AL, 3
		ADD	AL, AH
		XOR	AH, AH
		RET

; AX = tile we're checking
; sets E if we can walk
CanWalk:	PUSH	SI
		CALL	GetTileOffset
		MOV	SI, AX
		CMP	BYTE [Board + SI], 0
		POP	SI
		RET
