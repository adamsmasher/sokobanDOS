OldKBHandler:	DD	0

InstallKB:	PUSH	ES
		; backup old KB interrupt
		XOR	AX, AX
		MOV	ES, AX				; ES = 0
		MOV	AX, [ES:0x24]
		MOV	[OldKBHandler], AX
		MOV	AX, [ES:0x26]
		MOV	[OldKBHandler + 2], AX
		; install new KB interrupt
		MOV	WORD [ES:0x24], KBHandler
		MOV	WORD [ES:0x26], CS
		POP	ES
		RET

RestoreKB:	PUSH	ES
		XOR	AX, AX
		MOV	ES, AX
		MOV	AX, [OldKBHandler]
		MOV	[ES:0x24], AX
		MOV	AX, [OldKBHandler + 2]
		MOV	[ES:0x26], AX
		POP	ES
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
