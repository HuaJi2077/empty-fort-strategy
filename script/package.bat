@echo off
setlocal

rem ============================================================
rem  Package a distributable release.
rem  1. Copy preset/ into dist\empty-fort-strategy\preset\
rem  2. Copy package.json + cordis.patch.yml (unchanged) into
rem     dist\empty-fort-strategy\ so `dsh plugin add` works on
rem     the unpacked folder. exports already points to
rem     ./preset/index.mjs, no rewriting needed.
rem  3. Copy install.bat (shipped with the release) into dist\
rem  4. Zip both into dist\empty-fort-strategy.zip
rem  NOTE: pure file copies only, no text processing.
rem  PowerShell text round-trips mangle UTF-8 Chinese into
rem  broken JSON (ANSI code page), which later breaks every
rem  model request via the plugin-package inventory resolver.
rem  Keep this file ASCII-only: cmd parses .bat files in ANSI
rem  code page, UTF-8 Chinese comments would break it.
rem  Upload the zip to GitHub Releases.
rem ============================================================

set "ROOT=%~dp0.."
set "DIST=%ROOT%\dist"
set "PKG=%DIST%\empty-fort-strategy"

if exist "%DIST%" rmdir /S /Q "%DIST%"
mkdir "%PKG%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] cannot create %PKG%
    pause
    exit /b 1
)

echo [1/4] copying preset into dist\empty-fort-strategy\preset ...
xcopy /E /I /Y "%ROOT%\preset" "%PKG%\preset" >nul
if errorlevel 1 (
    echo [ERROR] copy preset failed
    pause
    exit /b 1
)
echo       done.

echo [2/4] copying bundle manifest into dist\empty-fort-strategy ...
copy /Y "%ROOT%\package.json" "%PKG%\package.json" >nul
if errorlevel 1 (
    echo [ERROR] copy package.json failed
    pause
    exit /b 1
)
copy /Y "%ROOT%\cordis.patch.yml" "%PKG%\cordis.patch.yml" >nul
if errorlevel 1 (
    echo [ERROR] copy cordis.patch.yml failed
    pause
    exit /b 1
)
echo       done.

echo [3/4] copying install.bat into dist ...
copy /Y "%~dp0install.bat" "%DIST%\install.bat" >nul
if errorlevel 1 (
    echo [ERROR] copy install.bat failed
    pause
    exit /b 1
)
echo       done.

echo [4/4] creating zip ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%DIST%\empty-fort-strategy','%DIST%\install.bat' -DestinationPath '%DIST%\empty-fort-strategy.zip' -Force"
if errorlevel 1 (
    echo [ERROR] zip failed
    pause
    exit /b 1
)
echo       done.

echo.
echo ============================================================
echo  Release ready: dist\empty-fort-strategy.zip
echo  Zip layout:
echo    empty-fort-strategy\        (bundle manifest, for plugin list)
echo      package.json
echo      cordis.patch.yml
echo      preset\                   (the mode itself)
echo    install.bat                 (run after unzip)
echo  Upload it to GitHub Releases.
echo ============================================================
echo.
pause
