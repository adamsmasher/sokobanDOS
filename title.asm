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
.waitLoop:	; check for exit
		CMP	BYTE [Quit], 1
		JNZ	.waitLoop
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
		JMP	LoadGame

KBHandler:	PUSH	AX
		IN	AL, 0x60			; get key event
		CMP	AL, 28				; enter?
		JNE	.done
		MOV	BYTE [Quit], 1
.done:		MOV	AL, 0x20			; ACK
		OUT	0x20, AL			; send ACK
		POP	AX
		IRET

OldKBHandler:	DD	0

Quit:		DB	0

		TIMES	0xFE2E DB 0

GameFile:	DB	'boxshv.com',0
Error:		DB	'Could not load BOXSHV.COM$'
LoadGame:	; open file
		MOV	AX, 0x3D00			; open for reading
		MOV	DX, GameFile
		INT	0x21
		JC	.error
		; read file
		MOV	BX, AX				; file handle
		MOV	AH, 0x3F			; read file
		MOV	CX, 0xFFFF			; 64KB
		MOV	DX, 0x0100			; .COM start space
		INT	0x21
		; start game!
		JMP	0x100
.error:		MOV	AH, 9				; print string
		MOV	DX, Error
		INT	0x21
		MOV	AX, 0x4CFF			; error code 0xFF
		INT	0x21
