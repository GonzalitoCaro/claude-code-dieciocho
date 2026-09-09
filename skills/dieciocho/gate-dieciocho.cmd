@echo off
REM Filtro barato para el hook UserPromptSubmit.
REM Este .cmd corre en CADA prompt, asi que tiene que ser liviano: findstr
REM cuesta ~85ms y PowerShell ~380ms. Levantamos PowerShell solo si calza.
REM findstr consume el stdin, por eso el .ps1 va con -Directo (no lo relee).
findstr /i /c:"dieciocho" >nul || exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prompt-monito.ps1" -Directo
