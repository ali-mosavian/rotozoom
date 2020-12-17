What's this?
-----
Yet another evening project to code up old-schoold rotozoomer in x86 assembly with 
real mode DOS as target. The assembled binary code is around 340 bytes, the included 
image is 17,408 bytes.

How to run
------
For convenience [rotozoom](src/rotzoom.asm) is written in [MASM](https://en.wikipedia.org/wiki/Microsoft_Macro_Assembler) 
syntax but is easy to port to NASM/FASM. 

To compile (using MASM 6.11 or higher)

`ml src/rotozoom.asm`

The most convenient way to run is through [DOSBox](https://www.dosbox.com/). To launch
in the DOS command prompt, type

`rotozoom.com` 

You should see the following output

![B&W](docs/screenshoot.png)


