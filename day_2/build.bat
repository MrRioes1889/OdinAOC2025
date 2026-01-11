@echo off

REM Get the full path of the batch file
set "fullpath=%~dp0"
REM Remove trailing backslash if present
if "%fullpath:~-1%"=="\" set "fullpath=%fullpath:~0,-1%"
REM Extract the name of the folder containing the batch file
for %%a in ("%fullpath%") do set "foldername=%%~nxa"

set TARGET=%foldername%
echo Building %TARGET%...

if not exist "bin" md "bin"
if not exist "bin\debug" md "bin\debug"
if not exist "bin\release" md "bin\release"

odin build . -build-mode:exe -debug -o:minimal -out:bin/debug/%TARGET%.exe -subsystem:console -warnings-as-errors

echo Done.
