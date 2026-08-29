@echo off
setlocal

rem ============================================================
rem  Install script shipped inside the release zip.
rem  Expected zip layout (after unzip, next to this script):
rem    empty-fort-strategy\
rem      package.json + cordis.patch.yml   (bundle manifest)
rem      preset\                            (the mode itself)
rem  Step 1: copy ONLY preset\ contents into the dsh user preset
rem          directory - this installs the mode itself. The
rem          bundle manifest must NOT land there: the request-time
rem          package-inventory resolver walks up from the preset
rem          folder looking for package.json, and one inside it
rem          can break every model request.
rem  Step 2: best-effort auto register into the plugin list
rem          (dsh plugin --profile web add). Needs dsh or npx
rem          on PATH; the npx way may download on first run.
rem          If it fails, the mode still works - the plugin
rem          list entry can be added manually later.
rem  After install: restart dsh, open a NEW session, pick the
rem  mode in the mode selector.
rem  Keep this file ASCII-only: cmd parses .bat files in ANSI
rem  code page, UTF-8 Chinese comments would break it.
rem ============================================================

set "SRC=%~dp0empty-fort-strategy"
set "DST=%USERPROFILE%\.dsh\.agent-presets\empty-fort-strategy"

if not exist "%SRC%\preset\preset.yml" (
    echo [ERROR] folder not found next to this script: %SRC%
    echo Make sure you unzipped the whole release, not only this file.
    pause
    exit /b 1
)

echo [1/2] installing the mode into %DST% ...
if exist "%DST%" rmdir /S /Q "%DST%"
xcopy /E /I /Y "%SRC%\preset" "%DST%" >nul
if errorlevel 1 (
    echo [ERROR] copy failed
    pause
    exit /b 1
)
echo       done.

echo.
echo [2/2] registering into the plugin list (optional) ...

rem Detect how to call dsh: direct command first, npx fallback.
set "DSHCMD="
where dsh >nul 2>&1
if not errorlevel 1 set "DSHCMD=dsh"
if not defined DSHCMD (
    where npx >nul 2>&1
    if not errorlevel 1 set "DSHCMD=npx -y @deepseek-ai/dsh"
)

if not defined DSHCMD (
    echo       skipped: neither dsh nor npx found on PATH.
    echo       The mode works without the plugin list entry.
    echo       To add it manually, run in your dsh environment:
    echo         dsh plugin --profile web add ^<path to the unzipped empty-fort-strategy folder^>
    goto :summary
)

rem dsh forwards the path to pnpm, which breaks on spaces.
rem Stage the package into a temp folder and prefer its 8.3
rem short path when short names are enabled on the volume.
set "STAGE=%TEMP%\efs-bundle-src"
if exist "%STAGE%" rmdir /S /Q "%STAGE%"
xcopy /E /I /Y "%SRC%" "%STAGE%" >nul
set "STAGERUN=%STAGE%"
for %%I in ("%STAGE%") do set "STAGERUN=%%~sI"
if not exist "%STAGERUN%\package.json" set "STAGERUN=%STAGE%"

echo       running: %DSHCMD% plugin --profile web add
echo       (npx may download the dsh package on first run, please wait)
call %DSHCMD% plugin --profile web add "%STAGERUN%"
if errorlevel 1 (
    echo       [WARN] auto register failed.
    echo       The mode works without the plugin list entry.
    echo       To add it manually, run in your dsh environment:
    echo         dsh plugin --profile web add ^<path to the unzipped empty-fort-strategy folder^>
) else (
    echo       done.
)
if exist "%STAGE%" rmdir /S /Q "%STAGE%"

:summary
echo.
echo ============================================================
echo  Installed: %DST%
echo  Next steps:
echo    1. restart dsh  (pnpm dsh web)
echo    2. open a NEW session
echo    3. select the mode in the mode selector
echo ============================================================
echo.
pause
