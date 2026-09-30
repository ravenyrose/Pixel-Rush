del *.prg
REM [edit] PATH TO ACME CROSS ASSEMBLER
set assembler=c:\c64\tools\acme\acme.exe
REM [edit] PATH TO EXOMIZER
set cruncher=c:\c64\tools\exomizer\win32\exomizer.exe
REM [edit] PATH TO VICE
set emulator=c:\c64\tools\vice\x64sc.exe
@echo on
%assembler% racensmash.asm
if not exist racensmash.prg goto abort
%cruncher% sfx $5000 racensmash.prg -o racensmash.prg -x2
%emulator% racensmash.prg
goto finished
abort:
@echo ERROR: Unable to build project.
finished:

