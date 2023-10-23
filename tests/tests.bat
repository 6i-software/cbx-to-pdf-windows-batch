@echo off
setlocal EnableDelayedExpansion

:: ANSI Colors configuration
set _colorPrefixANSI=[
set _colorReset=[0m
set _colorForeground=[95m

:: Initialization tests
call :InitializationTests
call :RunningTests
exit /b 0



:InitializationTests
setlocal EnableDelayedExpansion
echo.
echo ╔═════════════════════╗
echo ║  1. Initialization  ║
echo ╚═════════════════════╝
echo.

set FOLDER_REPORT=report
if not exist "%FOLDER_REPORT%" (
    echo Attempt to create report folder: %_colorForeground%%FOLDER_REPORT%%_colorReset%
    mkdir %FOLDER_REPORT%"
) else (
    echo Ok - The report folder already exist: %_colorForeground%%FOLDER_REPORT%%_colorReset%
)

set PATH_TESTS="./test-*"
set COUNT_TESTS=0
for %%A in (!PATH_TESTS!) do (
    set /a COUNT_TESTS+=1
)
echo Ok - It was found %_colorForeground%!COUNT_TESTS!%_colorReset% tests in tests folder.

endlocal
exit /b 0



:RunningTests
echo.
echo ╔════════════════════════╗
echo ║  2. Running all tests  ║
echo ╚════════════════════════╝
echo.

set "index=0"
for %%x in ("./test-*") do (
    set /a index+=1
    set file=%%x
    set dirpath=%%~dpx
    set fullpath=%%~fx
    set filename=%%~nx
    set extension=%%~xx

    echo --- Run test !index!/!COUNT_TESTS! :: %_colorForeground%!file!%_colorReset% ---
    echo Create report test in %_colorForeground%"./report/!filename!.log"%_colorReset%
    call !file! > ./report/!filename!.log
    echo OK - Test is finished.
    echo.
)
exit /b 0

