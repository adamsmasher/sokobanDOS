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
