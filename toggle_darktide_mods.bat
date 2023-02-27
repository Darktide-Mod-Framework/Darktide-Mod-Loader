@echo off
echo Starting Darktide patcher...
.\tools\dtkit-patch --toggle .\bundle
if errorlevel 1 goto failure
pause
exit
:failure
echo Error patching the Darktide bundle database. See logs.
pause
exit