@echo off

set "fullpath=%~dp0"
if "%fullpath:~-1%"=="\" set "fullpath=%fullpath:~0,-1%"
for %%a in ("%fullpath%") do set "foldername=%%~nxa"

set TARGET=%foldername%
echo Building %TARGET%...

if not exist "bin" md "bin"
if not exist "bin\debug" md "bin\debug"
if not exist "bin\release" md "bin\release"

if "%~1" == "-d" (
    odin build . -build-mode:exe -debug -o:minimal -out:bin/debug/%TARGET%.exe -subsystem:console -warnings-as-errors
) else (
    odin build . -build-mode:exe -o:speed -out:bin/release/%TARGET%.exe -subsystem:console -warnings-as-errors
)

echo Done.

