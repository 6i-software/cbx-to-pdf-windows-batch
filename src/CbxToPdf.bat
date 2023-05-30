
@echo off
setlocal EnableDelayedExpansion

:: ---------------------- ::
:: CbxToPdf configuration ::
:: ---------------------- ::

:: Application constants
set APPLICATION_NAME=CbxToPdf
set APPLICATION_VERSION=1.0.0
set FOLDER_SCRIPT=%~dp0
set FOLDER_TEMP=%~dp0temp

:: Application arguments CLI
set ARGUMENTS=%*
set ARGUMENT_FILES=
set OPTION_QUIET=0
set OPTION_VERBOSE=1
set OPTION_FOLDER_OUTPUT=%~dp0output\
set OPTION_HELP=0
set OPTION_VERSION=0
set OPTION_KEEP_FOLDER_TEMP=0

:: Application variables
set CONSOLE_WIDTH=
set COUNT_FILES=

:: BinaryDependencies default values
set ZIP_BIN="C:\Program Files\7-Zip\7z.exe"
set IMAGE_MAGICK_BIN="C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe"
set IMAGE_MAGICK_ARGUMENTS="-resize 1200x1850 -format jpg"


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


:: --------------------- ::
:: Start CLI application ::
:: --------------------- ::
call :ReadIniConfig
call :ReadCliArguments %*
call :StartApplication %1
call :StopApplication 0
exit /b 0


:ReadIniConfig
call :ReadIniKey config.ini BinaryDependencies ZIP_BIN ZIP_BIN
call :ReadIniKey config.ini BinaryDependencies IMAGE_MAGICK_BIN IMAGE_MAGICK_BIN
call :ReadIniKey config.ini BinaryDependencies IMAGE_MAGICK_ARGUMENTS IMAGE_MAGICK_ARGUMENTS
exit /b 0


:ReadIniKey <file> <section> <key> <result>
if not exist %~1 (
	call :Error "Unable to parse ini file The file ^(%_colorForegroundBrightWhite%%~1%_colorForegroundWhite%^) doesnt exist."
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
        call :Error "Use an unknown option: %_colorForegroundBrightWhite%%~1" 1
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
    set IMAGE_MAGICK_ARGUMENTS=%IMAGE_MAGICK_ARGUMENTS% -monitor
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

call :Newline
call :Log "╔═════════════════════╗"
call :Log "║  1. Initialization  ║" 
call :Log "╚═════════════════════╝"
call :Debug "Enable ASCII Control-Character Graphics by setting the console codepage to: 65001"
call :ResolveOutputFolder
call :DebugApplication
call :ResolveArgumentFiles
call :CreateTempFolder
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
set FULLPATHS=
set COUNT_FULLPATHS=0
for %%d in (%ARGUMENT_FILES%) do (
    set /a COUNT_FULLPATHS = COUNT_FULLPATHS + 1
    set file=%%d
    for %%x in (!file!) do (
        set fullpath=%%~fx
    )
    set FULLPATHS=!FULLPATHS! "!fullpath!"
)
call :Debug "Parse fullpaths: %FULLPATHS%"
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
        call :Debug " - Item %%i: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a valid directory"
        set item=!item!\*.cbr !item!\*.cbz
    ) else (
        if exist !item! (
            call :Debug " - Item %%i: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a valid file"
        ) else (
            call :Debug " - Item %%i: %_colorForegroundBrightBlue%!item!%_colorReset% - Is a unvalid file/directory. It's does not exist."
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

set ARGUMENT_FILES=!ARGUMENT_FILES:~0,-1!
exit /b 0


:DebugApplication
call :Debug "CLI arguments: %_colorForegroundBrightBlue%%ARGUMENTS%%_colorReset%"
call :Debug ZIP_BIN: %_colorForegroundBrightBlue%%ZIP_BIN%%_colorReset%
call :Debug IMAGE_MAGICK_BIN: %_colorForegroundBrightBlue%%IMAGE_MAGICK_BIN%%_colorReset%
call :Debug IMAGE_MAGICK_ARGUMENTS: %_colorForegroundBrightBlue%%IMAGE_MAGICK_ARGUMENTS%%_colorReset%
call :Debug FOLDER_SCRIPT: %_colorForegroundBrightBlue%%FOLDER_TEMP%%_colorReset%
call :Debug FOLDER_TEMP: %_colorForegroundBrightBlue%%FOLDER_TEMP%%_colorReset%
call :Debug FOLDER_OUTPUT: %_colorForegroundBrightBlue%%FOLDER_OUTPUT%%_colorReset%
call :Debug OPTION_FOLDER_OUTPUT: %_colorForegroundBrightBlue%%OPTION_FOLDER_OUTPUT%%_colorReset%
call :Debug OPTION_VERBOSE: %_colorForegroundBrightBlue%%OPTION_VERBOSE%%_colorReset%
call :Debug OPTION_KEEP_FOLDER_TEMP: %_colorForegroundBrightBlue%%OPTION_KEEP_FOLDER_TEMP%%_colorReset%
call :Debug ARGUMENT_FILES: %_colorForegroundBrightBlue%%ARGUMENT_FILES%%_colorReset%
exit /b 0


:CheckCbxFiles
call :Debug "ARGUMENT_FILES is equals to: !ARGUMENT_FILES!
call :Debug Check CBX files is launch now.

if [!ARGUMENT_FILES!]==[] (
    call :Error "No cbx files found. You must give one or more file."
    call :StopApplication 1
) else (
    set COUNT_FILES=0
    for %%x in (!ARGUMENT_FILES!) do (
        set /a COUNT_FILES+=1
    )
    call :Debug COUNT_FILES: %_colorForegroundBrightBlue%!COUNT_FILES!%_colorReset%
    
    set idx=0
    for %%x in (!ARGUMENT_FILES!) do (      
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
        ) else (
            call :Error "Oh ^!, application does not found any cbx files to convert."
            call :StopApplication 1
        )
    )    
)
exit /b 0


:IterateCbxFiles
set idx=0
for %%x in (%ARGUMENT_FILES%) do (
    set /a idx+=1
    set file=%%x
    set dirpath=%%~dpx
    set fullpath=%%~fx
    set filename=%%~nx
    set extension=%%~xx
            
    if !COUNT_FILES! == 1 (
        call :Log "Launch conversion of the file: %_colorForegroundBrightBlue%!filename!!extension!%_colorReset%"
    ) else (
        call :Log "[File !idx!/!COUNT_FILES!] Launch conversion of the file: %_colorForegroundBrightBlue%!filename!!extension!%_colorReset%"
    )
    call :UnpackArchive "!fullpath!" "%FOLDER_TEMP%\!filename!!extension!"\
	call :ConvertWebpImages "%FOLDER_TEMP%\!filename!!extension!"\
	call :GeneratePdf "%FOLDER_TEMP%\!filename!!extension!\" "%FOLDER_OUTPUT%" "!filename!"
	call :Newline
)

if not %OPTION_KEEP_FOLDER_TEMP% == 1 (
	rmdir /S/Q "%FOLDER_TEMP%"
	call :Debug "Temp folder "%FOLDER_TEMP%" is deleted"
)

if %OPTION_VERBOSE% gtr 0 (
    echo Job is done ^^!
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
call :Info "Uncompress file %_colorForegroundBrightBlue%"%1"%_colorReset% is done."
exit /b 0


:ConvertWebpImages <folder_images>
call :Info "Try to convert webp images into %_colorForegroundBrightBlue%"%1"%_colorReset%."
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
        %IMAGE_MAGICK_BIN% mogrify %IMAGE_MAGICK_ARGUMENTS% -path ./CONVERTED %%x
        if %OPTION_VERBOSE% gtr 2 (
            echo  - ^(!progress!^%% Image !index_webp_image!/!count_webp_images!^) %%x is converted
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
    call :Info "We found no webp images in cbx file."
    
)
cd %FOLDER_SCRIPT%
exit /b 0


:GeneratePdf <folder_images> <output> <cbx_name>
cd %1
%IMAGE_MAGICK_BIN% convert *.* %3.pdf
move %3.pdf %2>nul
call :Log "Ok, the file %_colorForegroundBrightBlue%"%3.pdf"%_colorReset% was saved into %_colorForegroundBrightBlue%"%2"%_colorReset%"
cd %FOLDER_SCRIPT%
exit /b 0


:Newline
if %OPTION_VERBOSE% gtr 0 (
    echo:
)
exit /b 0


:Log <message>
set message=%1
set message=%message:"=%
if %OPTION_VERBOSE% gtr 0 (
    echo %message%
)
exit /b 0


:Info <message>
set message=%1
set message=%message:"=%
if %OPTION_VERBOSE% gtr 1 (
    echo [INFO] %message%
)
exit /b 0


:Debug <message>
set message=%*
set message=%message:"=%
if %OPTION_VERBOSE% gtr 2 (
    echo [DEBUG] %message%
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
