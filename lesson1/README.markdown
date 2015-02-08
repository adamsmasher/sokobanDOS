# Writing a DOS Game in 16-bit Assembly Language

## Intro

Over the next few weeks I'll be posting tutorials here that show the
step-by-step construction of a simple, DOS
[Sokoban](http://en.wikipedia.org/wiki/Sokoban) clone in 16-bit
x86 assembly language.

The use of 16-bit assembly language is for a couple of reasons, one sentimental
and one technical. The sentimental one is that it's satisfying to have some
sense of how your favourite classic DOS games were made and the restrictions
they were made under; to feel, in a way, that you could've been part of that
scene too. The technical one is that modern operating systems, in abstracting
away the hardware, actually make it substantially more complicated to just
get started banging away at the screen. You can't just immediately switch
screen modes with two lines of assembly code in Windows or Linux and then
draw directly to a memory-mapped frame buffer. And under DOS, if we wanted
full use of the 32-bit CPU, we'd need to switch manually to protected mode, a
brutal undertaking. 16-bit x86 has its own complications, too, but to my mind
this might be the easiest way to get started with this sort of coding, and
one of the most rewarding, in terms of how it can help you understand how
a PC works.

I'll assume a fair amount of programming knowledge, although no pre-existing
x86 assembly language knowledge. To assemble our programs, we'll be using
the freely available [NASM](http://www.nasm.us/) assembler.

README files (like this one) under each lesson will include a line-by-line
walkthrough of any new or modified code. For maximum learning, it is
recommended that you download the actual code yourself, assemble it,
modify it, experiment with it.

For this first lesson, we'll simply switch to graphics mode, wait a certain
number of frames, then switch back to text mode and exit.

If you have any questions, comments, concerns, or suggestions, don't hesitate
to use one of GitHub's many features to send them my way. Or, if you'd prefer,
reach me on [Twitter](http://www.twitter.com/wk_end).

## Code Walkthrough

### boxshv.asm

```
                ; tell NASM we want 16-bit assembly language
                BITS    16
```

A semicolon denotes a comment until the end of the line.

`BITS` isn't an instruction executed by the processor, but rather a directive
to NASM that tells it that we want traditional 16-bit assembly language,
rather than a modern 32 or 64-bit one (the motivation for imposing this
limitation on ourself is explained in the intro).

```
                ORG     0x100                           ; DOS loads us here
```

This is also a NASM directive. When we run our program from DOS, the operating
system loads it to address 0x100 in memory. We tell NASM this so that it can
correctly compute the addresses in our program we want to access or jump to.

```
Start:          CALL    InitVideo
```

Here we have our first actual exectued instruction, `CALL`.
`CALL` is how we invoke functions in assembly language - it pushes the address
of the next instruction onto the stack and then jumps to a different location
in the code. When the called function executes a `RET` instruction, this
address is then popped off the stack and jumped to, resuming execution in
the calling function.

On the left, `Start` defines a *label*. This is used by NASM to identify this
line of code so that it can be referred to later. In this case, we don't
actually use it later; it's here for a technical reason (if you're curious,
try removing it).


`InitVideo` is a function defined later, in `video.asm`.

```
                MOV     CX, REFRESH_RATE * WAIT_SECS    ; init counter
```

The `MOV` instruction is a general-purpose instruction for shunting data
around. Here, we're loading an *immediate value* (i.e. a constant stored in our
program code) into the 16-bit CX *register*. Registers are processor-internal
memory; many operations on data the CPU can only do once it's loaded from
memory into a CPU register. There are many registers in an x86 CPU that
we'll encounter in due time; some have specific uses, others can be used
for many or most things. By convention, although not necessity, CX is the
register used to store loop Counters.

After this instruction is executed, the CX register will contain the number
of frames we want to wait. `REFRESH_RATE` and `WAIT_SECS` are defined
elsewhere; note that it's NASM that's computing their product, *not* the CPU.
`REFRESH_RATE` defines the number of frames per second that will be drawn;
`WAIT_SECS` defines how many seconds we want to wait. Their product is thus
how many frames to wait in order to wait for `WAIT_SECS`.

```
.gameLoop:      CALL    WaitFrame
                DEC     CX                              ; dec counter
                JNZ     .gameLoop                       ; loop if counter > 0
```

Here we have the core loop of our program, which waits for the desired
number of frames.

`.gameLoop:` defines a *local label*. Note the `.` in front, which is what
makes this local. The next time NASM encounters a label *without* a
`.` in front (like Start, above), it forgets all local labels. This allows you
to reuse labels in different functions.

`WaitFrame` is again a function defined in `video.asm`.

The `DEC` instruction subtracts 1 from its operand, here the counter CX.
If the result of the decrement is 0, it sets the *Z(ero) flag* on the CPU (if
not, it turns the Z flag off). The next instruction, `JNZ` (Jump if Not Zero),
then checks the status of the Z flag; if it's not up (i.e., CX does not equal
zero yet), it loops back to .gameLoop. Otherwise, execution continues on the
next line.

```
                ; exit
                MOV     AH, 0x4C
                MOV     AL, 0                           ; return code 0
                INT     0x21
```

Finally, we need to return control to DOS. We do this by invoking a
*system call*. DOS provides a number of software services which we can call
by triggering an *interrupt* using the `INT` instruction.

Interrupts are one way execution can jump out of a linear flow. When one
happens, the CPU stops what it's doing, looks up an interrupt handler for the
given interrupt number in a table stored in memory and jumps to it. Some
interrupts are caused by hardware - keystrokes, for instance, trigger
interrupt 9 - but, as we're doing here, we can also trigger ones in
software ourselves.

DOS system calls are accessed by triggering interrupt 0x21 (this notation
means *the hex number 21*, which is 33 in base 10). DOS then uses the
contents of the 8-bit AH register to select which system call to execute -
in our case, 0x4C is the Exit Program system call. The value in the
8-bit AL register is used as the return code.

Note that the AL and AH registers combine to form a 16-bit AX register. In fact,
CX, which we encountered above, is also made from 8-bit CL and CH registers.
Thus we can - and in future lessons, will - combine these two instructions
into one:

```
                MOV     AX, 0x4C00
```

This would be (microscopically) smaller and faster.

```
REFRESH_RATE    EQU     70
WAIT_SECS       EQU     5
```

The `EQU` pseudo-instruction defines constants for NASM, used above.

```
%include "video.asm"
```

Here we include our program's other module, `video.asm`. This works much like
the C preprocessor - the text of `video.asm` gets pasted in verbatim.

### video.asm

```
; the VGA hardware is always in one of two states:
; * refresh, where the screen gets redrawn.
;            This is the state the VGA is in most of the time.
; * retrace, a relatively short period when the electron gun is returning to
;            the top left of the screen, from where it will begin drawing the
;            next frame to the monitor. Ideally, we write the next frame to
;            the video memory entirely during retrace, so each refresh is
;            only drawing one full frame
; The following procedure waits until the *next* retrace period begins.
; First it waits until the end of the current retrace, if we're in one
; (if we're in refresh this part of the procedure does nothing)
; Then it waits for the end of refresh.
WaitFrame:      PUSH    DX
```

The `PUSH` instruction pushes data onto the stack. Here, we do this to
backup or *preserve* the contents of the 16-bit DX register, which we'll
modify during the WaitFrame function. Once the function is over, we pop
the old value of DX back off the stack. This way, functions that call
WaitFrame don't need to worry about losing the contents of their DX register
during the call. Note that, in this case, we aren't using DX anywhere else
in the program, so we don't strictly *need* to backup its contents.
However, it's good practice to do so, to keep things from getting too
confusing and introducing strange bugs. The registers that get preserved
(or not) and whose responsibility it is to do so, caller or callee, is one
part of a *calling convention* that as an assembly language programmer, you're
responsible for choosing and maintaining. I generally like to preserve all
registers except for AX, but when writing your own code exactly how to
handle this is up to you.

```
                ; port 0x03DA contains VGA status
                MOV     DX, 0x03DA
.waitRetrace:   IN      AL, DX
```

Hardware generally communcates on the x86 over *ports*, which are accessed with
the `IN` and `OUT` instructions. Each piece of hardware is wired to one or
more *port numbers*. The VGA graphics hardware, for instance, sends status
information to the CPU over port 0x03DA. The `IN` instruction here reads
data from this port and places it in AL. We need to put the port number into
a register because of a quirk of the `IN` instruction; while you can use it
with 8-bit immediate port numbers (e.g. `IN AL, 0x60` is acceptable), 16-bit
port numbers need to come from a register. Moreover, we need to place
this number specifically in the DX register; while the DX register is
general-purpose and can do many things, one thing *only* it can do is store
a 16-bit port number for access with the `IN` and `OUT` instructions.

```
                ; bit 3 will be on if we're in retrace
                TEST    AL, 0x08                        ; are we in retrace?
                JNZ     .waitRetrace
```

The `TEST` instruction computes a logical AND and sets flags based on it,
without writing the result anywhere. Here, we AND the contents of the VGA
status byte against the number 0x08, because in binary that's 00001000; if
bit 3 is on in the status byte, the AND result will be 00001000 and the Z flag
will be lowered; otherwise, the result will be 00000000 and the Z flag will
be raised. Hence this loop will continue reading the VGA status and looping
until bit 3 is off, which means we're no longer in retrace.

```
.endRefresh:    IN      AL, DX
                TEST    AL, 0x08                        ; are we in refresh?
                JZ      .endRefresh
```

This loop works the same, but instead of testing for retrace, it tests for
refresh.

```
                POP DX
                RET
```

Here we restore the old value of DX and return.

```
InitVideo:      ; set video mode 0x13
                MOV     AX, 0x13
                INT     0x10
                RET

RestoreVideo:   ; return to text mode 0x03
                MOV     AX, 0x03
                INT     0x10
                RET
```

These two functions use a BIOS interrupt, 0x10, to set the video mode.
Interrupt 0x10 uses the contents of AH to select a function (here, it will be
0, which selects the Set Video Mode function) and the contents of AL to select
a video mode. Mode 0x13 is the classic DOS 320x200, 256-colour VGA video mode
used by most DOS games of the era. Mode 0x03 is the standard DOS text mode.

## Building and Testing

To build and test, I use NASM and DOSEMU on Linux. Here are the commands I
use:

```
$ nasm boxshv.asm -o boxshv.com
$ dosemu boxshv.com
```

If everything worked out well, DOSEMU should load our program, switch to
graphics mode, wait for five seconds, and then quit.

If you use a different environment (in particular, a different operating
system and/or DOSBox or Bochs to test) and can provide instructions for
setting them up, a pull request would be much appreciated.

(click [here](/lesson2/) for Part 2)
