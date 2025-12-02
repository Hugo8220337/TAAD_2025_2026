@echo off
REM Robust PyInstaller build script (Windows .bat)

REM Go to the directory of this script
pushd "%~dp0" || (echo Failed to enter script directory & exit /b 1)

REM Change to the src directory (relative to the script directory)
pushd "%~dp0..\src" || (echo Source directory not found: "%~dp0..\src" & popd & exit /b 1)

REM Verify the main script exists
if not exist "apply_filters.py" (
  echo ERROR: apply_filters.py not found in %cd%
  popd
  popd
  exit /b 1
)

REM Run PyInstaller
pyinstaller --onefile apply_filters.py --name FireDataFilter --add-data "filters;filters" --add-data "utils;utils"
if errorlevel 1 (
  echo PyInstaller failed
  popd
  popd
  exit /b 1
)

REM Ensure destination dist directory (next to build_scripts)
set "OUT_DIR=%~dp0..\dist"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

REM Move the generated executable to the target dist
if exist "dist\FireDataFilter.exe" (
  move /y "dist\FireDataFilter.exe" "%OUT_DIR%\FireDataFilter.exe"
) else (
  echo ERROR: Executable not found in dist\ after PyInstaller.
  popd
  popd
  exit /b 1
)

REM Cleanup build artifacts in src
rmdir /s /q "build" 2>nul
rmdir /s /q "dist" 2>nul
del /q "__pycache__" 2>nul
del /q "*.spec" 2>nul

REM Return to original folder
popd
popd
echo Build complete. Executable placed in "%OUT_DIR%\FireDataFilter.exe"
REM ...existing code...