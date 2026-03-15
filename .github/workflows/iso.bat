@ECHO off

curl -Is https://github.com >nul 2>&1
if errorlevel 1 (
    echo Please connect to the internet
    exit /b 1
)

SET latest=GITHUBRELEASE
SET latestkver=%latest%
CALL SET latestkver=%%latestkver:v=%%
FOR /f "tokens=1,2 delims=-" %%a IN ("%latestkver%") DO (
  SET latestkver=%%a
)

SET downloads=%userprofile%\Downloads

ECHO.
ECHO Choose the flavour of Linux Mint you wish to install:
ECHO.
ECHO 1. Cinnamon
ECHO 2. Xfce
ECHO 3. MATE
ECHO.
ECHO Type your choice (1,2 or 3) from the above list and press return.
SET /P flavinput=

IF "%flavinput%"=="1" (
    SET flavour=cinnamon
    SET flavourcap=Cinnamon
) ELSE (
    IF "%flavinput%"=="2" (
        SET flavour=xfce
        SET flavourcap=Xfce
    ) ELSE (
        IF "%flavinput%"=="3" (
            SET flavour=mate
            SET flavourcap=MATE
        ) ELSE (
            ECHO Invalid input. Aborting!
            EXIT
        )
    )
)

SET iso=linuxmint-22.3-%flavour%-%latestkver%-t2-noble
SET ver=Linux Mint 22.3 "Zena" - %flavourcap% Edition

ECHO.
ECHO Downloading Part 1 for %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Mint/releases/download/%latest%/%iso%.iso.00 > %downloads%\%iso%.iso

ECHO.
ECHO Downloading Part 2 for %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Mint/releases/download/%latest%/%iso%.iso.01 >> %downloads%\%iso%.iso

curl -s -L https://github.com/t2linux/T2-Mint/releases/download/%latest%/sha256-%flavour% -o shafile.txt

FOR /F "DELIMS=" %%A IN (shafile.txt) DO (
    SET actual_iso_chksum=%%A
    GOTO :break_loop
)
:break_loop

DEL shafile.txt

FOR /f "tokens=1,2 delims= " %%a IN ("%actual_iso_chksum%") DO (
  SET actual_iso_chksum=%%a
)

ECHO.
ECHO Verifying sha256 checksums

FOR /f "tokens=1" %%i IN ('certutil -hashfile %downloads%\%iso%.iso SHA256 ^| findstr /v "hash"') DO (
    SET "downloaded_iso_chksum=%%i"
)

IF "%actual_iso_chksum%" NEQ "%downloaded_iso_chksum%" (
    ECHO.
    ECHO Error: Failed to verify sha256 checksums of the ISO
    DEL %downloads%\%iso%.iso
    EXIT
)

ECHO.
ECHO ISO saved to Downloads
