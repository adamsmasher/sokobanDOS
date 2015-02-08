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
		MOV	AX, 0x2509
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

DirTable:	DB	72, 75, 77, 80			; up, left, right, down
KBHandler:	PUSH	AX
		PUSH	SI
		IN	AL, 0x60			; get key event
.testEsc:	CMP	AL, 0x01			; ESC pressed?
		JNE	.testDirs
		MOV	[Quit], AL
.testDirs:	MOV	SI, 0				; i = 0
		MOV	AH, 4				; 4 entries in table
.testLoop:	CMP	AL, [DirTable + SI]		; compare to keycode
		JE	.writeDir			; do we have a match?
		INC	SI				; next entry
		DEC	AH
		JNZ	.testLoop
		JMP	.done
.writeDir:	INC	SI
		MOV	WORD [MoveDir], SI		; write out table entry
.done:		MOV	AL, 0x20			; ACK
		OUT	0x20, AL			; send ACK
		POP	SI
		POP	AX
		IRET
