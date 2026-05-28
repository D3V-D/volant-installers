@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
title Volant - Installation and Setup

:: --- APPLICATION CONFIG ---

set "VOLANT_REPO=https://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@github.com/D3V-D/volant-core.git"
set "VOLANT_SOURCE=volant-core"
set "VOLANT_LAUNCH=launch.bat"

echo.
echo.
echo                         ,--,                               ___
echo        ,---.          ,--.'^|                             ,--.'^|_
echo       /__./^|   ,---.  ^|  ^| :                     ,---,   ^|  ^| :,'
echo  ,---.^;  ^; ^|  '   ,'\ :  : '                 ,-+-. /  ^|  :  : ' :
echo /___/ \  ^| ^| /   /   ^|^|  ' ^|     ,--.--.    ,--.'^|'   ^|.;__,'  /
echo \   ^;  \ ' ^|.   ^; ,. :'  ^| ^|    /       \  ^|   ^|  ,^"' ^|^|  ^|   ^|
echo  \   \  \: ^|'   ^| ^|: :^|  ^| :   .--.  .-. ^| ^|   ^| /  ^| ^|:__,'^| :
echo   ^;   \  ' .'   ^| .^; :'  : ^|__  \__\/: . . ^|   ^| ^|  ^| ^|  '  : ^|__
echo    \   \   '^|   :    ^|^|  ^| '.'^| ,^" .--.^; ^| ^|   ^| ^|  ^|/   ^|  ^| '.'^|
echo     \   `  ^; \   \  / ^;  :    ^;/  /  ,.  ^| ^|   ^| ^|--'    ^;  :    ^;
echo      :   \ ^|  `----'  ^|  ,   /^;  :   .'   \^|   ^|/        ^|  ,   /
echo       '---^"            ---`-' ^|  ,     .-./'---'          ---`-'
echo                                `--`---'
echo.
echo =================================
echo  Volant - Installation and Setup
echo =================================
echo.

:: Make freshly installed tools reachable without restarting the shell.
set "PATH=%PATH%;C:\Program Files\Git\cmd;%USERPROFILE%\.local\bin;%LOCALAPPDATA%\Microsoft\WindowsApps"

:: ===================================================
:: 1. SYSTEM DEPENDENCY CHECK
:: ===================================================

:: --- winget (ships with Windows 10 1809+ / Windows 11 via "App Installer") ---
where winget >nul 2>nul
if errorlevel 1 (
    echo [X] winget was not found.
    echo     Open the Microsoft Store, install "App Installer" from Microsoft,
    echo     then re-run this installer. winget ships with modern Windows
    echo     but may be missing on older or freshly-imaged machines.
    pause
    popd
    exit /b 1
)

:: --- Git ---
where git >nul 2>nul
if errorlevel 1 (
    echo [+] Installing Git...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)
where git >nul 2>nul
if errorlevel 1 (
    echo [X] Git is still not available after install.
    echo     Open a new terminal and try `git --version`, or install Git manually
    echo     from https://git-scm.com/download/win and re-run this installer.
    pause
    popd
    exit /b 1
)

:: --- uv (Python package + interpreter manager from Astral) ---
where uv >nul 2>nul
if errorlevel 1 (
    echo [+] Installing uv...
    powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
    set "PATH=%PATH%;%USERPROFILE%\.local\bin"
)
where uv >nul 2>nul
if errorlevel 1 (
    echo [X] uv is still not available after install.
    echo     Try opening a new terminal and running `uv --version`, or install
    echo     uv manually from https://docs.astral.sh/uv/ and re-run this installer.
    pause
    popd
    exit /b 1
)

:: ===================================================
:: 2. PROJECT REPOSITORY SETUP
:: ===================================================

if exist "%VOLANT_SOURCE%\%VOLANT_LAUNCH%" goto :SKIP_CLONE

if exist "%VOLANT_SOURCE%\" (
    echo [!] Folder "%VOLANT_SOURCE%" exists but %VOLANT_LAUNCH% was not found.
    echo     Remove "%VOLANT_SOURCE%" or fix the repo, then run this installer again.
    pause
    popd
    exit /b 1
)

echo [+] Cloning Volant repository...
echo     %VOLANT_REPO%
git clone "%VOLANT_REPO%" "%VOLANT_SOURCE%"
if errorlevel 1 (
    echo.
    echo [X] Clone failed. Check:
    echo     - VOLANT_REPO at the top of this file points to the correct repo
    echo     - Git is installed and you have access ^(Credential Manager or SSH^)
    pause
    popd
    exit /b 1
)

:SKIP_CLONE
echo [+] Repository verified.

:: ===================================================
:: 3. PYTHON RUNTIME + PROJECT DEPENDENCIES (via uv)
:: ===================================================

pushd "%VOLANT_SOURCE%"

echo [+] Ensuring a managed Python runtime is installed...
uv python install
if errorlevel 1 (
    echo [X] uv could not install Python. Check your internet connection and retry.
    popd
    pause
    popd
    exit /b 1
)

echo [+] Installing Python dependencies (Streamlit, ...)...
uv sync
if errorlevel 1 (
    echo [X] uv sync failed. Check the output above for details.
    popd
    pause
    popd
    exit /b 1
)

popd

:: ===================================================
:: 4. DESKTOP SHORTCUT CREATOR
:: ===================================================

set "TARGET_BAT=%CD%\%VOLANT_SOURCE%\%VOLANT_LAUNCH%"
set "TARGET_DIR=%CD%\%VOLANT_SOURCE%"
set "ICON_PATH=%CD%\%VOLANT_SOURCE%\static\fly.ico"

if not exist "%TARGET_BAT%" (
    echo [X] Launch script not found: %TARGET_BAT%
    echo     Add %VOLANT_LAUNCH% to the repository root, then re-run this installer.
    pause
    popd
    exit /b 1
)

echo [+] Creating desktop shortcut...

set "VOLANT_TARGET_BAT=%TARGET_BAT%"
set "VOLANT_TARGET_DIR=%TARGET_DIR%"
set "VOLANT_ICON_PATH=%ICON_PATH%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); if ([string]::IsNullOrWhiteSpace($desktop)) { $desktop=Join-Path $env:USERPROFILE 'Desktop' }; New-Item -ItemType Directory -Path $desktop -Force | Out-Null; $shortcut=Join-Path $desktop 'Volant.lnk'; $s=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut); $s.TargetPath=$env:VOLANT_TARGET_BAT; $s.WorkingDirectory=$env:VOLANT_TARGET_DIR; if (Test-Path $env:VOLANT_ICON_PATH) { $s.IconLocation=$env:VOLANT_ICON_PATH + ',0' } else { $s.IconLocation='C:\Windows\System32\shell32.dll, 22' }; $s.Description='Launch Volant fly tracking analysis'; $s.Save(); Write-Host ('    ' + $shortcut)"
if errorlevel 1 (
    echo [X] Unable to create the desktop shortcut.
    echo     Volant was installed, but Windows would not allow the shortcut to be saved.
    echo     You can still launch it with: %TARGET_BAT%
    pause
    popd
    exit /b 1
)

echo.
echo =====================================================
echo  Volant installed successfully!
echo  A shortcut has been created on your Desktop.
echo  Use it to launch Volant from: %VOLANT_SOURCE%
echo.
echo  IMPORTANT: If you move this installation folder,
echo  delete the old folder and run this installer again
echo  from the new location so the shortcut stays valid.
echo =====================================================
echo.
pause
popd
endlocal
