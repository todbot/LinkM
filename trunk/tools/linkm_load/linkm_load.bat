
@ECHO OFF

:Start
ECHO ------------------------
linkmbootload.exe -r linkm.hex
ECHO To run another LinkBoot load,
PAUSE
GOTO Start