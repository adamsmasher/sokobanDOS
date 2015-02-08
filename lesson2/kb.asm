OldKBHandler:	DW	0
OldKBSeg:	DW	0

InstallKB:	PUSH	ES
		PUSH	BX
		PUSH	DX
		; backup old KB interrupt
		MOV	AX, 0x3509			; get interrupt 9
		INT	0x21
		MOV	[OldKBHandler], BX
		MOV	[OldKBSeg], ES
		; install new KB interrupt
		MOV	AH, 0x25
		MOV	DX, KBHandler
		INT	0x21
		POP	DX
		POP	BX
		POP	ES
		RET

RestoreKB:	PUSH	DX
		PUSH	DS
		MOV	AX, 0x2509
		MOV	DX, [OldKBHandler]
		MOV	DS, [OldKBSeg]
		INT	0x21
		POP	DS
		POP	DX
		RET

KBHandler:	PUSH	AX
		IN	AL, 0x60			; get key event
		CMP	AL, 0x01			; ESC pressed?
		JNE	.done
		MOV	[Quit], AL
.done:		MOV	AL, 0x20			; ACK
		OUT	0x20, AL			; send ACK
		POP	AX
		IRET
