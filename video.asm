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


