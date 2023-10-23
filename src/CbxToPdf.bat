@echo off
setlocal EnableDelayedExpansion



:: ┌───────────────┐ ::
:: │               │ ::
:: │ Configuration │ ::
:: │               │ ::
:: └───────────────┘ ::

:: Save current working dir with pushd (we use popd to restore it)
pushd .

:: Change the current working dir to the folder of this script
set FOLDER_RUN=%cd%
cd %~dp0
set FOLDER_BATCH=%cd%
cd %FOLDER_BATCH%

:: Application constants
set APPLICATION_NAME=CbxToPdf
set APPLICATION_VERSION=1.1.0
set FOLDER_SCRIPT=%~dp0
set FOLDER_TEMP=%~dp0temp

:: Application arguments CLI
set ARGUMENTS=%*
set ARGUMENT_FILES=
set OPTION_QUIET=0
set OPTION_VERBOSE=1
set OPTION_FOLDER_OUTPUT=!FOLDER_RUN!\output\
set OPTION_HELP=0
set OPTION_VERSION=0
set OPTION_KEEP_FOLDER_TEMP=0

:: Application variables
set CONSOLE_WIDTH=
set COUNT_FILES=

:: BinaryDependencies default values
set ZIP_BIN="C:\Program Files\7-Zip\7z.exe"
set IMAGE_MAGICK_BIN="C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe"
set IMAGE_MAGICK_ARGUMENTS_MOGRIFY="-resize 1200x1850 -format jpg"

:: ------------------------- ::
:: ANSI Colors configuration ::
:: ------------------------- ::
set _colorPrefixANSI=[
:: Styles
set _colorReset=[0m
set _colorBold=[1m
set _colorUnderline=[4m
set _colorInverse=[7m
:: Normal foreground colors
set _colorForegroundBlack=[30m
set _colorForegroundRed=[31m
set _colorForegroundGreen=[32m
set _colorForegroundYellow=[33m
set _colorForegroundBlue=[34m
set _colorForegroundMagenta=[35m
set _colorForegroundCyan=[36m
set _colorForegroundWhite=[37m
:: Bright foreground colors
set _colorForegroundBrightBlack=[90m
set _colorForegroundBrightRed=[91m
set _colorForegroundBrightGreen=[92m
set _colorForegroundBrightYellow=[93m
set _colorForegroundBrightBlue=[94m
set _colorForegroundBrightMagenta=[95m
set _colorForegroundBrightCyan=[96m
set _colorForegroundBrightWhite=[97m
:: Normal background colors
set _colorBackgroundBlack=[40m
set _colorBackgroundRed=[41m
set _colorBackgroundGreen=[42m
set _colorBackgroundYellow=[43m
set _colorBackgroundBlue=[44m
set _colorBackgroundMagenta=[45m
set _colorBackgroundCyan=[46m
set _colorBackgroundWhite=[47m
:: Bright background colors
set _colorBackgroundBrightBlack=[100m
set _colorBackgroundBrightRed=[101m
set _colorBackgroundBrightGreen=[102m
set _colorBackgroundBrightYellow=[103m
set _colorBackgroundBrightBlue=[104m
set _colorBackgroundBrightMagenta=[105m
set _colorBackgroundBrightCyan=[106m
set _colorBackgroundBrightWhite=[107m



:: ┌───────────────────────┐ ::
:: │                       │ ::
:: │ Start CLI application │ ::
:: │                       │ ::
:: └───────────────────────┘ ::
call :ReadIniConfig
call :ReadCliArguments %*
call :StartApplication %1
call :StopApplication 0
exit /b 0


:: ------------------------------------- ::
:: Read configuration if config.ini file ::
:: ------------------------------------- ::
:ReadIniConfig
call :ReadIniKey config.ini BinaryDependencies ZIP_BIN ZIP_BIN
call :ReadIniKey config.ini BinaryDependencies IMAGE_MAGICK_BIN IMAGE_MAGICK_BIN
call :ReadIniKey config.ini BinaryDependencies IMAGE_MAGICK_ARGUMENTS_MOGRIFY IMAGE_MAGICK_ARGUMENTS_MOGRIFY
exit /b 0

:ReadIniKey <file> <section> <key> <result>
if not exist %~1 (
	call :Error "Unable to parse the configuration file ^(%_colorForegroundBrightWhite%%~1%_colorForegroundWhite%^) doesnt exist." true
	call :StopApplication 1
)
set %~4=
setlocal
set insection=
for /f "usebackq eol=; tokens=*" %%a in ("%~1") do (
	set line=%%a
	if defined insection (
		for /f "tokens=1,* delims==" %%b in ("!line!") do (
			if /i "%%b"=="%3" (
				endlocal
				set %~4=%%c
				goto :eof
			)
		)
    )
    if "!line:~0,1!"=="[" (
		for /f "delims=[]" %%b in ("!line!") do (
			if /i "%%b"=="%2" (
				set insection=1
			) else (
				endlocal
				if defined insection goto :eof
			)
		)
	)
)
endlocal
exit /b 0


:: ---------------------------- ::
:: Read and parse CLI arguments ::
:: ---------------------------- ::
:ReadCliArguments <arguments_cli>
set _=%~1
if "%_:~,1%"=="-" (
    if /i "%~1"=="-h" (
        set OPTION_HELP=1
    ) else if /i "%~1"=="--help" (
        set OPTION_HELP=1
    ) else if /i "%~1"=="--verbose" (
        set OPTION_VERBOSE=1
    ) else if /i "%~1"=="-v" (
        set OPTION_VERBOSE=1
    ) else if /i "%~1"=="-vv" (
        set OPTION_VERBOSE=2
    ) else if /i "%~1"=="-vvv" (
        set OPTION_VERBOSE=3
    ) else if /i "%~1"=="-o" (
        set OPTION_FOLDER_OUTPUT=%~2
        shift
    ) else if /i "%~1"=="--output" (
        set OPTION_FOLDER_OUTPUT=%~2
        shift
    ) else if /i "%~1"=="-q" (
        set OPTION_QUIET=1
    ) else if /i "%~1"=="--quiet" (
        set OPTION_QUIET=1
    ) else if /i "%~1"=="--version" (
        set OPTION_VERSION=1
    ) else if /i "%~1"=="--keep-folder-temp" (
        set OPTION_KEEP_FOLDER_TEMP=1
    ) else (
        call :Error "Use an unknown option: %_colorForegroundBrightWhite%%~1" true
        call :StopApplication 1
        exit /b 0
    )
) else (
    set ARGUMENT_FILES=%ARGUMENT_FILES% %1
)
set _=
shift
if not "%~1" == "" goto :ReadCliArguments
exit /b 0



:: ----------------- ::
:: Start application ::
:: ----------------- ::
:StartApplication
setlocal EnableDelayedExpansion

:: Enable ASCII Control-Character Graphics. Remarks, the file source encoding must be in UTF-8 (no BOM).
for /f "tokens=2 delims=:" %%a in ('chcp') do set CONSOLE_CODEPAGE=%%a
set CONSOLE_CODEPAGE=%CONSOLE_CODEPAGE: =%
chcp 65001>NUL

:: Disable verbose mode if quiet option is enable
if %OPTION_QUIET% == 1 (
    set OPTION_VERBOSE=0
)
if %OPTION_VERBOSE% gtr 2 (
    set IMAGE_MAGICK_ARGUMENTS_MOGRIFY=%IMAGE_MAGICK_ARGUMENTS_MOGRIFY% -monitor
)

:: Show help by default, if no options/arguments is given
if [%1]==[] set OPTION_HELP=1
if %OPTION_HELP% == 1 (
    call :Splashscreen
    call :ShowHelp
    call :StopApplication 0
    exit /b 0
)

:: Show application version, if --version is given
if %OPTION_VERSION% == 1 (
    call :ShowVersion
    call :StopApplication 0
    exit /b 0
)

:: Show application and launch conversion of cbx files given in CLI arguments
call :Splashscreen

:: Check binary dependencies
set BIN_DEPENDENCIES=true
if not exist %ZIP_BIN% (
    call :Error "CbxToPdf use 7-Zip to unpack CBX file, but it was not found. You must install it (for example with 'choco install 7zip'), then after you need to update the config.ini file accordingly to the folder installation used." true
    set BIN_DEPENDENCIES=false
)
if not exist %IMAGE_MAGICK_BIN% (
    call :Error "CbxToPdf use ImageMagick to convert webp images, but it was not found. You must install it (for example with 'choco install imagemagick'), then after you need to update the config.ini file accordingly to the folder installation used." true
    set BIN_DEPENDENCIES=false
)
if %BIN_DEPENDENCIES% == false (
	call :StopApplication 1
)


call :Newline
call :Log "╔═════════════════════╗"
call :Log "║  1. Initialization  ║"
call :Log "╚═════════════════════╝"
call :Debug "Enable ASCII Control-Character Graphics by setting the console codepage to: 65001"
call :ResolveOutputFolder
call :DebugApplication
call :CreateTempFolder
call :ResolveArgumentFiles
call :CheckCbxFiles

call :Newline
call :Log "╔════════════════════════╗"
call :Log "║  2. Convert cbx files  ║"
call :Log "╚════════════════════════╝"
call :IterateCbxFiles

endlocal
exit /b 0


:Splashscreen
setlocal EnableDelayedExpansion
if %OPTION_VERBOSE% gtr 0 (
	call :GetConsoleWidth
	set topic[0]=    ██████╗  ██╗
	set topic[1]=   ██╔════╝    ║   %APPLICATION_NAME% - v%APPLICATION_VERSION%
	set topic[2]=   ███████   ██║
	set topic[3]=   ██    ██╗ ██║   Copyright © 2023
	set topic[4]=   ╚██████╔╝ ██║   https://github.com/v20100v/
	set topic[5]=    ╚═════╝  ╚═╝

	echo:
	call :HorizontalRule
	echo:
	echo:
	for /l %%i in (0,1,5) do (
		set str=!topic[%%i]!
		set str=!str:█=%_colorForegroundBlue%█%_colorReset%!
		echo !str!
	)
	echo:
	call :HorizontalRule
	echo:
)
exit /b 0


:ShowVersion
echo %APPLICATION_NAME% version %APPLICATION_VERSION%
exit /b 0


:ShowHelp
echo.
echo Usage:
echo   %APPLICATION_NAME% [%_colorForegroundBrightBlue%options%_colorReset%] %_colorForegroundBlue%FILES%_colorReset%
echo.
echo Options:
echo   %_colorForegroundBrightBlue%-h, --help%_colorReset%             Display this help message.
echo   %_colorForegroundBrightBlue%-q, --quiet%_colorReset%            Do not output any message.
echo   %_colorForegroundBrightBlue%-o, --output%_colorReset%           Set the output folder. [Default=./]
echo   %_colorForegroundBrightBlue%--keep-folder-temp%_colorReset%     To keep the temporary folder at the end.
echo   %_colorForegroundBrightBlue%-v^|vv^|vvv, --verbose%_colorReset%   Increase the level verbosity ^(1=normal, 2=info, 3=debug).
echo   %_colorForegroundBrightBlue%--version%_colorReset%              Display this application version.
echo.
echo Examples:
echo   ^> %APPLICATION_NAME% my-file.cbr
echo   ^> %APPLICATION_NAME% -vv -output-path ./out/of/space/ --keep-folder-temp my-file.cbz
echo   ^> %APPLICATION_NAME% my-file1.cbr ../foo/my-file2.cbr c:/bar/my-file3.cbz
echo   ^> %APPLICATION_NAME% "./out of space/my file with spaces.cbr"
echo   ^> %APPLICATION_NAME% ./my-folder/*.cbr
echo   ^> %APPLICATION_NAME% ./my-folder/*.cbz
echo   ^> %APPLICATION_NAME% ./my-folder
echo.
echo CbxToPdf is free and available as open source under the terms of the MIT License.
echo But you can buy me a coffee here : %_colorForegroundBrightBlue%https://www.buymeacoffee.com/vincent.blain%_colorReset%
echo.
exit /b 0


:ResolveOutputFolder
set FOLDER_OUTPUT=%OPTION_FOLDER_OUTPUT%
for %%x in ("%OPTION_FOLDER_OUTPUT%\") do set FOLDER_OUTPUT=%%~dpx
if not exist "%FOLDER_OUTPUT%" (
    call :Info "Attempt to create output folder into: %_colorForegroundBrightBlue%%FOLDER_OUTPUT%%_colorReset%"
    mkdir "%FOLDER_OUTPUT%"
) else (
    call :Info "Ok, the output folder exist: %_colorForegroundBrightBlue%%FOLDER_OUTPUT%%_colorReset%"
)
exit /b 0


:ResolveArgumentFiles
cd !FOLDER_RUN!
set FULLPATHS=
set COUNT_FULLPATHS=0

for %%d in (%ARGUMENT_FILES%) do (
    set /a COUNT_FULLPATHS = COUNT_FULLPATHS + 1

    set FULLPATHS=!FULLPATHS! "%%~fd"
)
call :Debug "Parsing the given fullpaths: %_colorForegroundBrightBlue%!FULLPATHS!%_colorReset%"
call :Debug "Check the %_colorForegroundBrightBlue%%COUNT_FULLPATHS%%_colorReset% fullpath given in ARGUMENT_FILES."

if %COUNT_FULLPATHS% == 0 (
    call :Error "No cbx files given. You must give one or more file."
    call :StopApplication 1
)

set has_error=0
set /a ITERATIONS = COUNT_FULLPATHS - 1
set ARGUMENT_FILES=
for %%x in (!FULLPATHS!) do (
    set item=%%x
    if exist !item!\* (
        if %OPTION_VERBOSE% gtr 2 (
            echo [DEBUG]  - Item: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a valid directory
        )
        set item=!item!\*.cbr !item!\*.cbz
    ) else (
        if exist !item! (
            if %OPTION_VERBOSE% gtr 2 (
                echo [DEBUG]  - Item: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a valid file
            )
        ) else (
            if %OPTION_VERBOSE% gtr 2 (
                echo [DEBUG]  - Item: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a unvalid file/directory. It's does not exist.
            )
            if not %OPTION_VERBOSE% gtr 2 (
                if !has_error! == 0 (echo:)
            )
            call :Error "The given file ^(%_colorForegroundBrightWhite%!item!%_colorForegroundWhite%^) does not exist."
            set has_error=1
        )
    )
    set ARGUMENT_FILES=!ARGUMENT_FILES!!item!;
)
if %has_error% == 1 (
    call :StopApplication 1
)

set FILES_TO_PARSED=!ARGUMENT_FILES:~0,-1!
exit /b 0


:DebugApplication
if %OPTION_VERBOSE% gtr 2 (
    echo [DEBUG] CLI arguments: %_colorForegroundBrightBlue%%ARGUMENTS%%_colorReset%
    echo [DEBUG] ZIP_BIN: %_colorForegroundBrightBlue%%ZIP_BIN%%_colorReset%
    echo [DEBUG] IMAGE_MAGICK_BIN: %_colorForegroundBrightBlue%%IMAGE_MAGICK_BIN%%_colorReset%
    echo [DEBUG] IMAGE_MAGICK_ARGUMENTS_MOGRIFY: %_colorForegroundBrightBlue%%IMAGE_MAGICK_ARGUMENTS_MOGRIFY%%_colorReset%
    echo [DEBUG] FOLDER_RUN: %_colorForegroundBrightBlue%%FOLDER_RUN%%_colorReset%
    echo [DEBUG] FOLDER_SCRIPT: %_colorForegroundBrightBlue%%FOLDER_SCRIPT%%_colorReset%
    echo [DEBUG] FOLDER_TEMP: %_colorForegroundBrightBlue%%FOLDER_TEMP%%_colorReset%
    echo [DEBUG] FOLDER_OUTPUT: %_colorForegroundBrightBlue%%FOLDER_OUTPUT%%_colorReset%
    echo [DEBUG] OPTION_FOLDER_OUTPUT: %_colorForegroundBrightBlue%%OPTION_FOLDER_OUTPUT%%_colorReset%
    echo [DEBUG] OPTION_VERBOSE: %_colorForegroundBrightBlue%%OPTION_VERBOSE%%_colorReset%
    echo [DEBUG] OPTION_KEEP_FOLDER_TEMP: %_colorForegroundBrightBlue%%OPTION_KEEP_FOLDER_TEMP%%_colorReset%
    echo [DEBUG] ARGUMENT_FILES: %_colorForegroundBrightBlue%%ARGUMENT_FILES%%_colorReset%
)
exit /b 0


:CheckCbxFiles
call :Debug "Check CBX files is launch now."
call :Debug "FILES_TO_PARSED is equals to: %_colorForegroundBrightBlue%!FILES_TO_PARSED!%_colorReset%

if [!FILES_TO_PARSED!]==[] (
    call :Error "No cbx files found. You must give one or more file."
    call :StopApplication 1
) else (
    set COUNT_FILES=0
    for %%x in (!FILES_TO_PARSED!) do (
        set /a COUNT_FILES+=1
    )
    call :Debug "We find %_colorForegroundBrightBlue%!COUNT_FILES!%_colorReset% files to parsed."

    set idx=0
    for %%x in (!FILES_TO_PARSED!) do (
        set /a idx+=1
        set file=%%x
        set dirpath=%%~dpx
        set fullpath=%%~fx
        set filename=%%~nx
        set extension=%%~xx
        set checkCbxExtension=0

        :: Debug
        if %OPTION_VERBOSE% gtr 2 (
            echo ---
            echo  file !idx!: %_colorForegroundBrightBlue%!file!%_colorReset%
            echo  dirpath: %_colorForegroundBrightBlue%!dirpath!%_colorReset%
            echo  fullpath: %_colorForegroundBrightBlue%!fullpath!%_colorReset%
            echo  filename: %_colorForegroundBrightBlue%!filename!%_colorReset%
            echo  extension: %_colorForegroundBrightBlue%!extension!%_colorReset%
        )

        if "!extension!"==".cbz" set checkCbxExtension=1
        if "!extension!"==".cbr" set checkCbxExtension=1
        if !checkCbxExtension! == 0 (
            call :Error "You must give cbx file: %_colorForegroundBrightWhite%!file!"
            call :StopApplication 1
        )

        if not exist !fullpath! (
            call :Error "The given file ^(%_colorForegroundBrightWhite%!fullpath!%_colorForegroundWhite%^) does not exist."
            call :StopApplication 1
        )
    )
    if %OPTION_VERBOSE% gtr 2 (
        echo ---
    )

    if !COUNT_FILES!==1 (
        call :Log "Ok, one cbx file was found to be converted."
    ) else (
        if !COUNT_FILES! gtr 1 (
            call :Log "Ok, %_colorForegroundBrightBlue%!COUNT_FILES!%_colorReset% cbx files were found to be converted."
			for %%x in (!FILES_TO_PARSED!) do (
				set /a idx+=1
				set file=%%x
				if %OPTION_VERBOSE% gtr 0 (
					echo - !file!
				)
			)
        ) else (
            call :Error "Oh, application does not found any cbx files to convert." true
            call :StopApplication 1
        )
    )
)
exit /b 0


:IterateCbxFiles
set idx=0
for %%x in (%ARGUMENT_FILES%) do (
    :: Timer for measuring time conversion of cbx file
    set startTime=!time!

    set /a idx+=1
    set file=%%x
    set dirpath=%%~dpx
    set fullpath=%%~fx
    set filename=%%~nx
    set extension=%%~xx

    if !COUNT_FILES! == 1 (
        call :Log "Launch conversion of : %_colorForegroundBrightBlue%!fullpath!%_colorReset%"
    ) else (
        call :Log "[!idx!/!COUNT_FILES!] Launch conversion of : %_colorForegroundBrightBlue%!filename!!extension!%_colorReset%"
    )
    call :UnpackArchive "!fullpath!" "%FOLDER_TEMP%\!filename!!extension!"\
	call :ConvertWebpImages "%FOLDER_TEMP%\!filename!!extension!"\
	call :GeneratePdf "%FOLDER_TEMP%\!filename!!extension!\" "%FOLDER_OUTPUT%" "!filename!"
	if not %OPTION_KEEP_FOLDER_TEMP% == 1 (
		rmdir /S/Q "%FOLDER_TEMP%\!filename!!extension!\"
		call :Debug "Temp folder "%FOLDER_TEMP%\!filename!!extension!\" is deleted"
	)

	set endTime=!time!

    for /f "tokens=1-4 delims=:.," %%a in ("!startTime!") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
    for /f "tokens=1-4 delims=:.," %%a in ("!endTime!") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
    set /a hours=!end_h!-!start_h!
    set /a mins=!end_m!-!start_m!
    set /a secs=!end_s!-!start_s!
    set /a ms=!end_ms!-!start_ms!
    if !ms! lss 0 set /a secs = !secs! - 1 & set /a ms = 100!ms!
    if !secs! lss 0 set /a mins = !mins! - 1 & set /a secs = 60!secs!
    if !mins! lss 0 set /a hours = !hours! - 1 & set /a mins = 60!mins!
    if !hours! lss 0 set /a hours = 24!hours!
    if 1!ms! lss 100 set ms=0!ms!
    set /a totalsecs = !hours!*3600 + !mins!*60 + !secs!

    call :Info "Time of conversion into PDF : !hours!:!mins!:!secs!.!ms! ^(!totalsecs!.!ms! secs total^)"
	call :Newline
)

if not %OPTION_KEEP_FOLDER_TEMP% == 1 (
	rmdir /S/Q "%FOLDER_TEMP%"
	call :Debug "Temp folder "%FOLDER_TEMP%" is deleted"
)

if %OPTION_VERBOSE% gtr 0 (
    if !COUNT_FILES! == 1 (
		echo Job is done ^^!
    ) else (
		echo Job is done, all !COUNT_FILES! files are converted ^^!
    )
)
exit /b 0


:CreateTempFolder
cd /d %~dp0
if not exist "%FOLDER_TEMP%" (
    call :Info "Attempt to create temp folder into: %_colorForegroundBrightBlue%%~dp0%_colorReset%"
    mkdir "%FOLDER_TEMP%"
) else (
    call :Info "Temp folder already exist, attempt to clean it into: %_colorForegroundBrightBlue%%~dp0%_colorReset%"
    rmdir /S/Q "%FOLDER_TEMP%"
    mkdir "%FOLDER_TEMP%"
    call :Info "Clean folder is done."
)
exit /b 0


:UnpackArchive <archive_file> <folder_extract>
if %OPTION_VERBOSE% gtr 2 (
    %ZIP_BIN% e %1 -y -o%2\
) else (
    %ZIP_BIN% e %1 -y -o%2\ > nul
)
call :Info "Uncompress cbx file in temp folder is done."
exit /b 0


:ConvertWebpImages <folder_images>
call :Debug "Try to convert webp images into %_colorForegroundBrightBlue%"%1"%_colorReset%."
cd %1
mkdir CONVERTED
set count_webp_images=0
for %%x in (*.webp) do set /a count_webp_images+=1

if %count_webp_images% gtr 0 (
    call :Info "We found %_colorForegroundBrightBlue%%count_webp_images%%_colorReset% webp images in %_colorForegroundBrightBlue%"%1"%_colorReset%. Start image conversion now."

    set index_webp_image=0
    for %%x in (*.webp) do (
        set /a index_webp_image=index_webp_image+1
        set /a progress=!index_webp_image!00/!count_webp_images! >nul
        %IMAGE_MAGICK_BIN% mogrify %IMAGE_MAGICK_ARGUMENTS_MOGRIFY% -path ./CONVERTED %%x
        if %OPTION_VERBOSE% gtr 1 (
            echo  - %IMAGE_MAGICK_BIN% mogrify %IMAGE_MAGICK_ARGUMENTS_MOGRIFY% -path ./CONVERTED %%x
            echo   ^(!progress!^%% Image !index_webp_image!/!count_webp_images!^) %%x is converted
        )
    )

    call :Info "All webp images are converted."
    del *.webp
    if %OPTION_VERBOSE% gtr 2 (
        move .\CONVERTED\*.* .
    ) else (
        move .\CONVERTED\*.* . >nul
    )
    rmdir CONVERTED
) else (
    call :Info "No webp images to convert were found in temp folder of cbx file."
)
cd %FOLDER_SCRIPT%
exit /b 0


:GeneratePdf <folder_images> <output> <cbx_name>
call :Info "Start conversion into PDF."
cd %1
set outputpdf=%3.pdf
set outputpdf_compress=%3-compress.pdf
%IMAGE_MAGICK_BIN% convert *.* %outputpdf%

move !outputpdf! %2>nul
call :Info "Ok, the cbx file is converted in : %_colorForegroundBrightBlue%"%2"%_colorForegroundBrightBlue%"%3.pdf"%_colorReset%
cd %FOLDER_SCRIPT%
exit /b 0


:Newline
if %OPTION_VERBOSE% gtr 0 (
    echo:
)
exit /b 0


:Log <msg>
set msg=%1
set msg=%msg:"=%
set "msg=%msg%"

if %OPTION_VERBOSE% gtr 0 (
    echo !msg!
)
exit /b 0


:Info <msg>
set msgInfo=%1
set msgInfo=%msgInfo:"=%
set "msgInfo=%msgInfo%"

if %OPTION_VERBOSE% gtr 1 (
    echo [INFO] !msgInfo!
)
exit /b 0


:Debug <msg>
set msgDebug=%1
set msgDebug=%msgDebug:"=%
set "msgDebug=%msgDebug%"

if %OPTION_VERBOSE% gtr 2 (
    echo [DEBUG] !msgDebug!
)
exit /b 0


:Warning <message>
set message=%1
set message=%message:"=%
if %OPTION_VERBOSE% gtr 0 (
    echo %_colorForegroundYellow%[WARNING] %message%%_colorReset%
)
exit /b 0


:Error <message> <new_line_before> <new_line_after>
set message=%1
set message=%message:"=%
if not "%2"=="" echo:
echo %_colorBackgroundRed%[ERROR] %message%%_colorReset%
if not "%3"=="" echo:
exit /b 0


:HorizontalRule
for /l %%i in (0,1,!CONSOLE_WIDTH!) do (<nul set /p=─)
exit /b 0


:GetConsoleWidth
set /a counter=0
for /f "tokens=1,2,*" %%A in ('mode con') do (set /a counter=!counter!+1&if !counter! equ 4 set CONSOLE_WIDTH=%%B)
set /a CONSOLE_WIDTH = !CONSOLE_WIDTH!-1
exit /b 0


:StopApplication [errorcode] - Exits only the current batch file
:: Restore the previous console codepage.
if %OPTION_VERBOSE% gtr 2 (
    echo:
)

call :Debug "Restore the previous working current dir save with pushd instruction"
popd

call :Debug "Restore the previous console codepage to: %CONSOLE_CODEPAGE%"
chcp %CONSOLE_CODEPAGE%>NUL

call :Debug "Stop application with error code: %1"
set _errLevel=%1
:popStack
(
    (goto) 2>nul
    setlocal DisableDelayedExpansion    
    call set caller=%%~0
    call set _caller=%%caller:~0,1%%
    call set _caller=%%_caller::=%%
    if not defined _caller (
        REM callType = func
        rem set _errLevel=%_errLevel%
        goto :popStack
    )   
    (goto) 2>nul
    endlocal
    cmd /c "exit /b %_errLevel%"
)
exit /b 0
