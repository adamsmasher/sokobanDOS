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

; NOTE: makes ES point to video memory!
InitVideo:	; set video mode 0x13
		MOV	AX, 0x13
		INT	0x10
		; make ES point to the VGA memory
		MOV	AX, 0xA000
		MOV	ES, AX
		RET

RestoreVideo:	; return to text mode 0x03
		MOV	AX, 0x03
		INT	0x10
		RET
