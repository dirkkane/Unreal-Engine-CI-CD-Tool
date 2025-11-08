cd %REPO_DIRECTORY%

for /f "delims=" %%H in ('git rev-parse --short HEAD 2^>nul') do set "hash=%%H"

cd %BUILD_DIRECTORY%
:: Build game
cmd.exe /c ""C:/Program Files/Epic Games/UE_5.6/Engine/Build/BatchFiles/RunUAT.bat"  -ScriptsForProject="%REPO_DIRECTORY%/%PROJECT_NAME%.uproject" Turnkey -command=VerifySdk -platform=Win64 -UpdateIfNeeded -EditorIO -EditorIOPort=53614  -project="%REPO_DIRECTORY%/%PROJECT_NAME%.uproject" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook  -project="%REPO_DIRECTORY%/%PROJECT_NAME%.uproject" -target=%PROJECT_NAME% -unrealexe="C:\Program Files\Epic Games\UE_5.6\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" -platform=Win64 -installed -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory="%BUILD_DIRECTORY%" -distribution -clientconfig=Shipping -nodebuginfo" -nocompile -nocompileuat

:: Format build name
set baseName=%PROJECT_NAME%_%year%_%month%_%day%
set version=
::set counter=2
::
:::: Add V# to the end of build name if a build of the same name already exists in the output folder
::for %%F in (*) do (
::    if !errorlevel! == 0 (
::    echo %%~nxF | findstr /i "%baseName%%version%" >nul
::        set version=_V!counter!
::		set /a counter+=1
::    )
::)

:: Remove unwanted files
del /s /q ".\Windows\*.txt"
rmdir /s /q ".\Windows\Engine\Extras"
for /r ".\Windows" %%f in (*.pdb) do del /q "%%f"

:: Archive build
"C:\Program Files\7-Zip\7z.exe" a -t7z -m0=lzma2 -mx=9 "%baseName%%version%_%hash%.7z" ".\Windows"

echo Archive created as %baseName%%version%_%hash%.7z

:: Delete uncompressed build
if exist ".\Windows" (
	rmdir /s /q ".\Windows"
)