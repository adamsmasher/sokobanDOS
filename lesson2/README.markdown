# Writing a DOS Game in 16-bit Assembly Language

## Part 2 - The Keyboard Handler

(click [here](lesson1/) for Part 1)

Games are by definition *interactive*, so in order to make our game we'll
need to provide some way of allowing the player to provide inputs to it.
While games do often make use of the mouse or a gamepad for control, 
we'll stick to the good old fashioned PC keyboard. This lesson will thus
cover the details of programming the PC hardware to notify our game when a key
event occurs. By the end of it, we'll have a program that loops forever until
the user presses Esc.

If you have any questions, comments, concerns, or suggestions, don't hesitate
to use one of GitHub's many features to send them my way. Or, if you'd prefer,
reach me on [Twitter](http://www.twitter.com/wk_end).

## Code Walkthrough

### boxshv.asm

```
                ; tell NASM we want 16-bit assembly language
                BITS    16
                ORG     0x100
Start:          CALL    InstallKB
```

The first thing our program will do is install a *keyboard handler*. When
the user presses a key on the keyboard, the PC will trigger a hardware
interrupt. The keyboard handler is the code that the CPU will start executing
once the interrupt occurs. All of the details of this will be covered once
we look at the code for `InstallKB` in `kb.asm`.

```
                CALL    InitVideo
.gameLoop:      CALL    WaitFrame
                CMP     BYTE [Quit], 1
                JNE     .gameLoop
```

In lesson 1, we simply waited for five seconds before exiting. Real games,
of course, should run as long as the player would like, so instead our
game loop simply runs forever until the value of a variable, Quit, is
set to 1, which we'll do in our keyboard handler once the user presses Esc.
The `CMP` instruction CoMPares its two operands and sets the
CPU flags accordingly. The following instruction, `JNE`, means Jump if Not
Equal; it is, in fact, just another name for `JNZ`, which we saw last time -
the CPU sets the Z flag when two values compare to the same thing (the CPU
technically subtracts the two values in order to compare them).

The notation for `CMP`'s operands is interesting. This particular format
or *addressing mode* means "compare the byte located at the address `Quit`
against the number 1". Note that `Quit` is an *address*, and that's *all*.
Later on we'll tell NASM where in memory we want `Quit` to point to, and
during the course of assembling it will just write that address number into
the binary. Thus we have to explicitly mention that the number stored at
`Quit` is a byte because, as far as NASM cares, all `Quit` is is an untyped
address. Sometimes we might want to compare 16-bit numbers given an untyped
address to them, in which case we'd write `CMP WORD [Some16BitVar], 1`.

```
                CALL    RestoreVideo
                CALL    RestoreKB
```

Note that just as we installed our keyboard handler above, we'll need to
uninstall it as well. Again, the details will be covered when we look at
`kb.asm`.

```
                ; exit
                MOV     AX, 0x4C00
                INT     0x21

Quit:           DB      0
```

Here's where we define `Quit`. The `DB` mnemonic means Define Byte, and it
simply instructs NASM to write the operand byte out into the binary file
it's generating. When DOS runs our program, the binary is simply copied to
address 0x100 in memory and then jumped to. Hence, this `DB` is allocating
space in memory, right after our program code, to store whether or not
the user has asked to quit yet.

Note that if we didn't invoke the exit syscall, the CPU wouldn't stop. It
has no understanding of the distinction between code and data, so it would
simply load the `Quit` byte and try to execute it as though it were an
instruction. In fact, the CPU would *keep* running even after that, executing
whatever happened to be in memory following our program - effectively,
random garbage - forever (or until the nonsense instructions cause it to
crash). This principle is true of our procedure calls, too - if we accidentally
omit a `RET` instruction at the end of them, the CPU will simply continue
executing whatever happens to follow the procedure in memory.

```
%include "kb.asm"
%include "video.asm"
```

We now include another module, `kb.asm`.

### kb.asm

```
OldKBHandler:   DW      0
OldKBSeg:       DW      0
```

Here we allocate a 16-bit *word* using the `DW`, Define Word,
pseudo-instruction. This double word is going store one part of the address of
the keyboard handler that DOS itself has installed. That way, when
our program quits, we'll be able to reinstall it so that DOS will continue
to operate the way it did before.

We give it a 0 value for now, but really it doesn't matter - we won't
read from it until after we've written to it.

The next word, OldKBSeg, will be used to the old keyboard handler's *segment*.

For the 16-bit x86 CPU, all memory addresses are actually *20 bits*. In order
to construct these 20-bit addresses, the CPU combines a 16-bit address that
we give in our code with *another* 16-bit value, the contents of a
*segment register*. A *segment* is basically a 64KB chunk of memory, and
the segment registers each hold a *segment base*, a pointer to the start
of that memory. To compute a full, 20-bit address from the segment base
and a 16-bit offset, we shift the segment base from one of the segment
registers left by four bits (which is just adding a 0 to the end, in hex) and
then add the offset. For example, segment 0x7000 starts at memory address
0x70000 and goes all the way to 0x70000 + 0xFFFF = 0x7FFFF.

Note that this means that there's a tremendous amount of overlap between
segments. For example, segment 0x1 starts at memory address 0x10 and segment
0x2 starts at memory address 0x20 - only 16 bytes after segment 0x1.
Thus, there's the whole 64KB, minus those 16 bytes, of overlap between the two
consecutive segments.


```
InstallKB:      PUSH    ES
```

The x86 has four segment registers: CS, DS, ES, and FS. CS is the Code Segment
register, and is used when fetching instructions. DS is the Data Segment
register, and is the *default* used when performing data accesses. ES and FS
are *extra segments*; if we want to, we can ask to use them explicitly to
access data in different segments without changing the default segment in DS.

The segmentation model was Intel's solution to technical restrictions of the
time when the x86 architecture was first being developed, and it's a bit tricky
to get your head around at first. Up until now we haven't worried about the
segment registers because we've been operating entirely within one segment, so
the way DOS has the segment registers set up when our program starts works
well. While I'll continue this model as much as possible for the remainder of
this tutorial, there will be times we'll need to play with segments,
so try to get comfortable with them.

```
                PUSH    BX
                PUSH    DX
                ; backup old KB interrupt
                MOV     AX, 0x3509                      ; get interrupt 9
                INT     0x21
                MOV     [OldKBHandler], BX
                MOV     [OldKBSeg], ES
```

Recall that when an interrupt happens, the CPU stops whatever it's doing
and passes control somewhere else. In the past, we've triggered interrupts
in software using the `INT` instruction to get the CPU to execute DOS
or BIOS syscalls.

How does the CPU know what code to execute for a given interrupt? The answer
is that it looks in a table stored at the very beginning of memory. Both
DOS and the BIOS configure this table so that certain interrupt numbers will
execute their code. We're going to reconfigure this table so that when
interrupt 9 is triggered, which happens whenever we press a key, it'll
execute our keyboard handler.

Before we rewrite this table, we need to backup the entry DOS had written in
this table beforehand. To do this, we'll date advantage of DOS syscall
0x35, Get Interrupt Vector. We set AH to 0x35 to specify this syscall and AL
to 9 as an argument to it, to state that we want the vector for interrupt 9.
After invoking the syscall, it returns the old interrupt handler's segment
in ES and offset in BX. The next two instructions copy these to memory.

```
                ; install new KB interrupt
                MOV     AH, 0x25
                MOV     DX, KBHandler
                INT     0x21
```

We now use DOS syscall 0x25 to install our new interrupt handler. As always,
we specify the syscall we want in AH. Note that AL is still set to 9,
the interrupt we want, from the previous operation. We're supposed to give
DOS the address of the syscall we want in DS:DX; DOS has already configured
DS to point to the segment our .COM file was loaded to, so we don't need to
make any changes to it, so we just set DX to point to the new handler and
invoke the interrupt

```
                POP     DX
                POP     BX
                POP     ES
                RET

RestoreKB:      PUSH    DX
                PUSH    DS
                MOV     AX, 0x2509
                MOV     DX, [OldKBHandler]
                MOV     DS, [OldKBSeg]
                INT     0x21
                POP     DS
                POP     DX
                RET
```

To restore the old interrupt at the end of our program, we use the exact
same syscall. Here we do need to DS to point to the old keyboard handler's
segment, however.

```
KBHandler:      PUSH    AX
```

Here we begin writing our interrupt handler. Because interrupts can happen at
any time, we *need* to preserve any registers we change, including AX.
Otherwise the rest of our code wouldn't be able to rely on register's
maintaining their value from one operation to the next, and programming
would be impossible. Note that the x86, when it jumps into an interrupt
handler, automatically stores the flags and CS on the stack, so we don't
need to worry about manually preserving them (we'll use a special Interrupt
Return instruction to restore them).

```
                IN      AL, 0x60                        ; get key event
```

When the keyboard triggers an interrupt, it places the *keycode* of the key
pressed on port 0x60. Thus, we read from port 0x60 to determine which
key was pressed.


```
                CMP     AL, 0x01                        ; ESC pressed?
                JNE     .done
                MOV     [Quit], AL
```

The keycode for the escape key is 1, so we check to see if that was the
key that the keyboard is reporting to us. If so, we write that 1 into the
[Quit] variable.

```
.done:          MOV     AL, 0x20                        ; ACK
                OUT     0x20, AL                        ; send ACK
```

Next, we need to *acknowledge* to keyboard that we've handled the key. To
do this, we write the value 0x20 out to port 0x20.


```
                POP     AX
                IRET
```

Finally, we need to return from our interrupt handler. We restore the old
value of AX and then invoke the `IRET` instruction to return from the
interrupt handler and restore the state of the CPU flags.
