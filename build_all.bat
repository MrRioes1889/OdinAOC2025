@echo off
for /d %%D in (day_*) do (
    echo %%D
    pushd %%D
    if "%~1" == "-d" (
        call build.bat -d
    ) else (
        call build.bat
    )
    popd
)