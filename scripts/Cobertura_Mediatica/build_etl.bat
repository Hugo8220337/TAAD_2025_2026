@echo off
SETLOCAL

:: --- CONFIGURAÇÃO ---
:: Nome do seu arquivo Python (altere se necessário)
SET SCRIPT_PYTHON=etl.py

:: Nome do executável final
SET NOME_EXE=ETL_News_Loader
:: --------------------

echo ========================================================
echo   INICIANDO COMPILACAO DO EXECUTAVEL PARA SSIS
echo ========================================================

:: Verifica se o PyInstaller está instalado
pyinstaller --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] PyInstaller nao encontrado. Instalando...
    pip install pyinstaller
)

echo.
echo [INFO] Limpando builds anteriores...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist *.spec del *.spec

echo.
echo [INFO] Gerando executavel (isso pode demorar alguns minutos)...
echo.

:: COMANDO PYINSTALLER
:: --onefile: Gera um único arquivo .exe (mais fácil para deploy)
:: --clean: Limpa cache antes de construir
:: --hidden-import: Garante que o pyodbc e pandas sejam incluídos
:: --name: Nome do arquivo final
pyinstaller --noconfirm --onefile --clean ^
 --hidden-import "pyodbc" ^
 --hidden-import "sqlalchemy.dialects.mssql" ^
 --hidden-import "pandas" ^
 --name "%NOME_EXE%" ^
 "%SCRIPT_PYTHON%"

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERRO] Falha na criacao do executavel.
    pause
    EXIT /B 1
)

echo.
echo ========================================================
echo   SUCESSO!
echo ========================================================
echo O arquivo executavel esta localizado na pasta: dist\%NOME_EXE%.exe
echo.
echo Voce pode mover este arquivo para o servidor do SSIS.
echo.
pause