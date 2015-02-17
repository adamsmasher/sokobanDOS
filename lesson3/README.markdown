# Writing a DOS Game in 16-bit Assembly Language

## Part 3 - Plotting Pixels

(click [here](/lesson2/) for Part 2)

A quick and short, but vitally important, lesson: here we're going to learn
how to draw on the screen. All I'll do is demonstrate how to write a
single pixel; that doesn't sound like much, but between keyboard input
(covered in the last lesson) and plotting pixels, you pretty much have 
the foundational building blocks required to make a game.

If you have any questions, comments, concerns, or suggestions, don't hesitate
to use one of GitHub's many features to send them my way. Or, if you'd prefer,
reach me on [Twitter](http://www.twitter.com/wk_end).

## Code Walkthrough

### boxshv.asm

The only change we're making to this file is a single procedure call, to
some code, defined in `video.asm`, that draws a pixel to the screen.

```
                CALL    DrawPixel
```

### video.asm

First, we extend `InitVideo`.

```
                ; make ES point to the VGA memory
                MOV     AX, 0xA000
                MOV     ES, AX
                RET
```

The VGA video mode we're using, the fondly remembered
[Mode 0x13](http://en.wikipedia.org/wiki/Mode_13h), uses a simple
*frame buffer* to represent the screen: each pixel corresponds to one
byte in memory, arranged *linearly* - the first row, followed by the second
row, and so on - in segment 0xA000. Thus, in order to get easy access to the
screen, for the entire duration of our program we're going to have ES
set to 0xA000. Note that, due to limitations of the x86 architecture, we can't
directly move an immediate into ES; we have to load it into AX first and then
transfer it over.

We don't bother making a corresponding change to `RestoreVideo` - DOS will take
care of restoring ES to whatever value it had before.

```
DrawPixel:      MOV     BYTE [ES:0x1234], 0x0F
                RET
```

Mode 0x13 makes it incredibly easy to put a pixel on the screen: we
just write a byte into memory in the video segment. Here we see the syntax for
this addressing mode: `MOV BYTE [ES:0x1234], 0x0F` means "copy the 8-bit
value 0x0F into memory at segment ES offset 0x1234" (I chose that
particular pixel arbitrarily; it corresponds to row 14, column 180, because
14 * 320 pixels across = 4480 + 180 = 4660 = 0x1234 in hex). The value 0x0F
corresponds to white in the default *VGA palette*.

A byte can only store 256 different values of course, which in the world of
colour isn't a whole lot; we'll need to cut corners somewhere.
If we used each byte to directly describe a colour -
say, by allocating three bits for the red intensity, three for the green
intensitiy, and two for the blue - we'd end up with a wide
range of colours with very large "gaps" in between them - they wouldn't
smoothly blend into each other.

Because most images have more shading than they do colour variety, the
VGA chooses a different approach, using a *palette*. Instead of enforcing that
the 256 colours in use are evenly distributed across the whole spectrum, it
lets the programmer *select* which 256 colours you want to use on screen,
out of a complete set of 262144 colours (18 bits per colour). Thus, if your
picture had a lot of different shades of green, let's say, you could stuff
your palette with those and get lots of smooth blending between the greens
instead of wasting precious bits on reds and blues you didn't care about.

Neater still, by modifying a colour in the palette you can instantly change the 
colour of every pixel on-screen pointing to that colour (much faster than
manually modifying each pixel). This can be used for fade-in/fade-outs or,
with some cleverness, very cool looking
[colour cycling](http://en.wikipedia.org/wiki/Color_cycling) effects.

I'll cover modifying the palette later; for now we'll stick to the default
one the VGA starts with. You can find a table of the first 16 colours at
David Brackeen's excellent 
"[256-Color VGA Programming in C](http://www.brackeen.com/vga/basics.html#5)
tutorial if you want to experiment. And if you're really curious,
[here](https://www.youtube.com/watch?v=-9QnckzyYvs)'s a very cool dissection of 
how the default VGA palette is constructed.
