@echo off
REM Script de build para o Meteorology Extractor (Windows .bat)

REM Vai para o diretório deste script
pushd "%~dp0" || (echo Failed to enter script directory & exit /b 1)

REM Muda para o diretório src (relativo ao diretório do script)
pushd "%~dp0src" || (echo Source directory not found: "%~dp0src" & popd & exit /b 1)

REM Verifica se o script principal existe
if not exist "extract_meteorology.py" (
  echo ERROR: extract_meteorology.py not found in %cd%
  popd
  popd
  exit /b 1
)

REM Executa o PyInstaller
REM Nota: Adicionamos "apis;apis" e "utils;utils" para garantir que os módulos locais são incluídos
pyinstaller --onefile extract_meteorology.py --name MeteorologyExtractor --add-data "apis;apis" --add-data "utils;utils"
if errorlevel 1 (
  echo PyInstaller failed
  popd
  popd
  exit /b 1
)

REM Garante que o diretório de destino dist existe (ao lado de build_scripts/scripts)
set "OUT_DIR=%~dp0..\dist"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

REM Move o executável gerado para a pasta dist alvo
if exist "dist\MeteorologyExtractor.exe" (
  move /y "dist\MeteorologyExtractor.exe" "%OUT_DIR%\MeteorologyExtractor.exe"
) else (
  echo ERROR: Executable not found in dist\ after PyInstaller.
  popd
  popd
  exit /b 1
)

REM Limpeza dos ficheiros de build na pasta src
rmdir /s /q "build" 2>nul
rmdir /s /q "dist" 2>nul
del /q "__pycache__" 2>nul
del /q "*.spec" 2>nul

REM Regressa à pasta original
popd
popd
echo Build complete.
echo Executable placed in "%OUT_DIR%\MeteorologyExtractor.exe"
pause