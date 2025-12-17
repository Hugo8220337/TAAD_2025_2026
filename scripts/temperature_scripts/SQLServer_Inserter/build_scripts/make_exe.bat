@echo off
REM PyInstaller build script for SQLServer_Inserter (Windows .bat)

REM Change to the directory of this script
pushd "%~dp0" || (echo Failed to enter script directory & exit /b 1)

REM Change to the project root (parent of build_scripts)
pushd "%~dp0\.." || (echo Project root not found: "%~dp0\.." & popd & exit /b 1)

REM Verify the main script exists
if not exist "main.py" (
  echo ERROR: main.py not found in %cd%
  popd
  popd
  exit /b 1
)

REM Run PyInstaller (include sql folder as data so SQL files are available at runtime)
pyinstaller --onefile main.py --name SQLServerInserter --add-data "sql;sql"
if errorlevel 1 (
  echo PyInstaller failed
  popd
  popd
  exit /b 1
)

REM Ensure destination dist directory (next to build_scripts)
set "OUT_DIR=%~dp0\..\dist"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

REM Move the generated executable to the target dist
if exist "dist\SQLServerInserter.exe" (
  move /y "dist\SQLServerInserter.exe" "%OUT_DIR%\SQLServerInserter.exe"
) else (
  echo ERROR: Executable not found in dist\ after PyInstaller.
  popd
  popd
  exit /b 1
)

REM Cleanup build artifacts in project root
rmdir /s /q "build" 2>nul
@REM rmdir /s /q "dist" 2>nul
del /q "__pycache__" 2>nul
del /q "*.spec" 2>nul

REM Return to original folder
popd
popd
echo Build complete. Executable placed in "%OUT_DIR%\SQLServerInserter.exe"
