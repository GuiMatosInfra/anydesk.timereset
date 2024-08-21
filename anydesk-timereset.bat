@echo off
setlocal enableextensions
title Reset AnyDesk

:: Verifica se o script está sendo executado como administrador
reg query HKEY_USERS\S-1-5-19 >NUL || (
    echo Please run this script as an administrator.
    pause >NUL
    exit /b
)

:: Define a página de código
chcp 437 > NUL

:: Parar o serviço AnyDesk
call :stop_any

:: Apagar arquivos de configuração
del /f "%ALLUSERSPROFILE%\AnyDesk\service.conf" > NUL 2>&1
del /f "%APPDATA%\AnyDesk\service.conf" > NUL 2>&1

:: Mover arquivos de configuração de usuário temporariamente
copy /y "%APPDATA%\AnyDesk\user.conf" "%temp%\" > NUL
rd /s /q "%temp%\thumbnails" 2>NUL
xcopy /c /e /h /r /y /i /k "%APPDATA%\AnyDesk\thumbnails" "%temp%\thumbnails" > NUL

:: Apagar todos os arquivos e pastas da instalação do AnyDesk
del /f /a /q "%ALLUSERSPROFILE%\AnyDesk\*" > NUL 2>&1
del /f /a /q "%APPDATA%\AnyDesk\*" > NUL 2>&1

:: Reiniciar o serviço AnyDesk
call :start_any

:lic
:: Verifica a presença do identificador AnyDesk
type "%ALLUSERSPROFILE%\AnyDesk\system.conf" | find "ad.anynet.id=" > NUL || goto lic

:: Restaurar arquivos de configuração e pastas
call :stop_any
move /y "%temp%\user.conf" "%APPDATA%\AnyDesk\user.conf" > NUL
xcopy /c /e /h /r /y /i /k "%temp%\thumbnails" "%APPDATA%\AnyDesk\thumbnails" > NUL
rd /s /q "%temp%\thumbnails" > NUL

:: Reiniciar o AnyDesk
call :start_any

:: Finalizar
echo *********
echo Completed.
echo(
goto :eof

:start_any
:: Inicia o serviço AnyDesk
sc start AnyDesk > NUL
:: Aguarda até que o serviço esteja ativo
timeout /t 5 > NUL
if %errorlevel% neq 0 goto start_any

:: Verifica o caminho de instalação e inicia o AnyDesk
set "AnyDesk1=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"
set "AnyDesk2=%ProgramFiles%\AnyDesk\AnyDesk.exe"
if exist "%AnyDesk1%" start "" "%AnyDesk1%"
if exist "%AnyDesk2%" start "" "%AnyDesk2%"
exit /b

:stop_any
:: Para o serviço AnyDesk
sc stop AnyDesk > NUL
:: Aguarda até que o serviço esteja inativo
timeout /t 5 > NUL
if %errorlevel% neq 0 goto stop_any
:: Finaliza qualquer processo AnyDesk em execução
taskkill /f /im "AnyDesk.exe" > NUL 2>&1
exit /b
