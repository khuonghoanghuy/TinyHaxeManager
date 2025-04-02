@echo off
setlocal enabledelayedexpansion

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: This script requires administrator privileges to set system variables.
    echo Please run this script as administrator by right-clicking and selecting "Run as administrator".
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: Create folders if they don't exist
mkdir haxe-ver 2>nul
mkdir haxe-ver\downloads 2>nul
mkdir haxe-ver\install 2>nul

:: Check if no arguments provided
if "%~1"=="" (
    call :help_without_args
    exit /b 1
)

:: Main command handler
set "command=%~1"
shift

:: Command router
if "%command%"=="help" (
    call :help
) else if "%command%"=="use" (
    call :use %1
) else if "%command%"=="list" (
    call :list
) else if "%command%"=="install" (
    call :install %1
) else if "%command%"=="remove" (
    call :remove %1
) else if "%command%"=="version" (
    call :version
) else (
    echo Unknown command: %command%
    echo.
    call :help
    exit /b 1
)

exit /b 0

:version
echo 1.0.1
exit /b 0

:help
echo Tiny Haxe Manager - A lightweight Haxe version manager
echo.
echo Usage: tinyHX ^<command^> [arguments]
echo.
echo Commands:
echo   help                    Show this help message
echo   use ^<version^>         Switch to specified Haxe version
echo   list                    List all installed Haxe versions
echo   install ^<version^>     Install a specific Haxe version
echo   remove ^<version^>      Remove a specific Haxe version
echo.
echo Note: This script requires administrator privileges to set system variables.
echo Version: 1.0.1
exit /b 0

:help_without_args
echo Error: No arguments provided
echo.
call :help
exit /b 1

:list
echo Installed Haxe versions:
echo.
for /d %%d in ("%cd%\haxe-ver\install\haxe-*") do (
    set "dir_name=%%~nxd"
    set "version=!dir_name:haxe-=!"
    echo !version!
)
if not exist "%cd%\haxe-ver\install\haxe-*" (
    echo No Haxe versions installed.
    echo Use 'tinyHX install <version>' to install a version.
)
exit /b 0

:install
if "%~1"=="" (
    echo Error: Version number required
    echo Usage: tinyHX install ^<version^>
    exit /b 1
)
set "version=%~1"
set "download_dir=haxe-ver\downloads"
set "install_dir=haxe-ver\install\haxe-%version%"
set "zip_name=haxe-%version%-win64.zip"
set "download_url=https://github.com/HaxeFoundation/haxe/releases/download/%version%/%zip_name%"

if exist "%install_dir%" (
    echo Haxe %version% is already installed at:
    echo %cd%\%install_dir%
    exit /b 0
)

echo Downloading %zip_name%...
:: Download with progress and retry logic
:download_retry
:: Remove any existing partial download
del "%download_dir%\%zip_name%" 2>nul

:: Download with curl and check for HTML content
curl -L -o "%download_dir%\%zip_name%" "%download_url%" >nul 2>&1

:: Check if the file exists and is not HTML
findstr /i "<html" "%download_dir%\%zip_name%" >nul 2>&1
if not errorlevel 1 (
    echo Download failed! The version %version% might not exist.
    echo Please check available versions at: https://github.com/HaxeFoundation/haxe/releases
    del "%download_dir%\%zip_name%" 2>nul
    exit /b 1
)

:: Check if download was successful
if not exist "%download_dir%\%zip_name%" (
    echo Download failed! Retrying...
    timeout /t 2 >nul
    goto download_retry
)

:: Wait a moment to ensure file is fully written
timeout /t 1 >nul

echo Extracting to: %install_dir%
:: Create a temporary directory for extraction
set "temp_extract=%TEMP%\tinyHX_extract_%version%"
mkdir "%temp_extract%" 2>nul

:: Extract to temporary directory first
powershell -Command "try { Expand-Archive -Path '%download_dir%\%zip_name%' -DestinationPath '%temp_extract%' -Force } catch { Write-Host $_.Exception.Message; exit 1 }"

if errorlevel 1 (
    echo EXTRACTION FAILED for Haxe %version%
    echo The downloaded file might be corrupted. Please try again.
    rmdir /s /q "%temp_extract%" 2>nul
    del "%download_dir%\%zip_name%" 2>nul
    exit /b 1
)

:: Move files from the root of the extracted folder to the install directory
:: This handles cases where the ZIP has a root folder
for /d %%d in ("%temp_extract%\*") do (
    xcopy /E /I /Y "%%d\*" "%install_dir%\"
)

:: Clean up temporary directory
rmdir /s /q "%temp_extract%" 2>nul

:: Verify extraction
if not exist "%install_dir%\haxe.exe" (
    echo Installation verification failed! Required files are missing.
    rmdir /s /q "%install_dir%" 2>nul
    del "%download_dir%\%zip_name%" 2>nul
    exit /b 1
)

:: Clean up
del "%download_dir%\%zip_name%" 2>nul

echo Successfully installed Haxe %version% to:
echo %cd%\%install_dir%
echo.
echo Use 'tinyHX use %version%' to switch to this version
echo Note: You'll need to run 'tinyHX use %version%' as administrator to set system variables.
exit /b 0

:remove
if "%~1"=="" (
    echo Error: Version number required
    echo Usage: tinyHX remove ^<version^>
    exit /b 1
)
set "version=%~1"
set "install_dir=haxe-ver\install\haxe-%version%"

if not exist "%install_dir%" (
    echo Error: Haxe version %version% is not installed
    exit /b 1
)

echo Removing Haxe %version%...
rmdir /s /q "%install_dir%"
echo Successfully removed Haxe %version%
exit /b 0

:use
if "%~1"=="" (
    echo Error: Version number required
    echo Usage: tinyHX use ^<version^>
    exit /b 1
)
set "version=%~1"
set "install_dir=haxe-ver\install\haxe-%version%"

if not exist "%install_dir%" (
    echo Error: Haxe version %version% is not installed
    echo Use 'tinyHX install %version%' to install it first
    exit /b 1
)

:: Get relative paths
set "haxe_path=%cd%\%install_dir%"
set "haxelib_path=%cd%\%install_dir%\lib"

echo Updating PATH for Haxe %version%...

:: Get current PATH from User environment
set "current_path="
for /f "tokens=*" %%a in ('powershell -Command "[Environment]::GetEnvironmentVariable('PATH', 'User')"') do set "current_path=%%a"

:: Remove all existing Haxe paths from current PATH
for /d %%d in ("%cd%\haxe-ver\install\haxe-*") do (
    set "dir_path=%cd%\%%d"
    set "current_path=!current_path:%%I\=!"
    set "current_path=!current_path:%%I=!"
)

:: Add new Haxe and haxelib paths at the beginning of PATH
set "new_path=%haxe_path%;%haxelib_path%;%current_path%"

:: Update User PATH
powershell -Command "[Environment]::SetEnvironmentVariable('PATH', '%new_path%', 'User')"

:: Broadcast environment changes
echo Broadcasting environment changes to the system...
powershell -Command "& {[void][System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path', 'User'), 'Process')}"

echo Successfully switched to Haxe %version%
echo User PATH has been updated.
echo.
echo You can verify the installation by running:
echo haxe --version
echo haxelib --version
exit /b 0