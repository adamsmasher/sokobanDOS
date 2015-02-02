		BITS	16
		ORG	0x100				; DOS loads us here
Start:		; backup old KB interrupt
		XOR	AX, AX
		MOV	ES, AX				; ES = 0
		MOV	AX, [ES:0x24]
		MOV	[OldKBHandler], AX
		MOV	AX, [ES:0x26]
		MOV	[OldKBHandler + 2], AX
		; install new KB interrupt
		MOV	WORD [ES:0x24], KBHandler
		MOV	WORD [ES:0x26], CS
		; set video mode 0x13
		MOV	AX, 0x13
		INT	0x10
		; make ES point to the VGA memory
		MOV	AX, 0xA000
		MOV	ES, AX
		CALL	DrawBoard
		CALL	DrawPlayer
.gameLoop:	CALL	WaitFrame
		CALL	UpdatePlayer
		; check for exit
		CMP	BYTE [Quit], 1
		JNZ	.gameLoop
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

; CX = box to find
; sets E if the box was found
; returns a pointer in AX if the box is found
FindBox:	PUSH	ES
		PUSH	DI
		MOV	AX, DS
		MOV	ES, AX
		MOV	AX, CX
		MOV	CX, [BoxCnt]
		; iterate through until we find a matching box or run out of
		; boxes
		MOV	DI, Boxes
		REPNE	SCASW
		MOV	CX, AX				; restore CX
		MOV	AX, DI				; return pointer in AX
		POP	DI
		POP	ES
		RET


ScrBase:	DW	0

START_ROW	EQU	2
START_COL	EQU	2

PlayerPos:
PlayerRow:	DB	START_ROW
PlayerCol:	DB	START_COL

MoveDir:	DW	0

PlayerScrBase:	DW	START_ROW * 320 * 16 + START_COL * 16
UnderTile:	DB	0

BOARD_WIDTH	EQU	8
BOARD_HEIGHT	EQU	9
Board:		INCBIN	"board.dat"

BoxCnt:		DW	7
Boxes:		DW	0x0203
		DW	0x0304
		DW	0x0404
		DW	0x0604
		DW	0x0605
		DW	0x0603
		DW	0x0601

PlayerTile:	INCBIN	"player.dat"

Tiles:		INCBIN	"wall.dat"
		INCBIN	"box.dat"

OldKBHandler:	DD	0

Quit:		DB	0

%include "board.asm"
%include "draw.asm"
%include "kb.asm"
%include "player.asm"
%include "video.asm"
