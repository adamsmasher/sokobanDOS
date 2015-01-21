		BITS	16
		ORG	0x100				; DOS loads us here
Start:		; backup old KB interrupt
		XOR	AX, AX
		MOV	ES, AX				; ES = 0
		MOV	AX, [ES:0x24]
		MOV	[OldKBHandler], AX
		MOV	AX, [ES:0x26]
		MOV	[OldKBHandler + 2], AX
;		; install new KB interrupt
		MOV	WORD [ES:0x24], KBHandler
		MOV	WORD [ES:0x26], CS
		; set video mode 0x13
		MOV	AX, 0x13
		INT	0x10
		; make ES point to the VGA memory
		MOV	AX, 0xA000
		MOV	ES, AX
.gameLoop:	; check for exit
		TEST	BYTE [Keys], 1			; 0 if esc not pressed
		JZ	.gameLoop
		; restore text mode 0x03
		MOV	AX, 0x03
		INT	0x10
		; restore old KB interrupt
		XOR	AX, AX
		MOV	ES, AX
		MOV	AX, [OldKBHandler]
		MOV	[ES:0x24], AX
		MOV	AX, [OldKBHandler + 2]
		MOV	[ES:0x26], AX
		; exit
		MOV	AX, 0x4C00			; return code 0
		INT	0x21

KBHandler:	PUSH	AX
		IN	AL, 0x60			; get key event
		CMP	AL, 0x01			; ESC pressed?
		JNE	.testEscRel
		OR	[Keys], AL			; set bit 0
.testEscRel:	CMP	AL, 0x81
		JNE	.done
		MOV	AL, 0xFE
		AND	[Keys], AL			; unset bit 0
.done:		MOV	AL, 0x20			; ACK
		OUT	0x20, AL			; send ACK
		POP	AX
		IRET

OldKBHandler:	DD	0

Keys:		DB	0
