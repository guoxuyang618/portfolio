@echo off  
cd /d c:\Users\matthewguo\CodeBuddy\20260309152659\portfolio  
start /b npx astro dev > dev-server.log 2>&1  
timeout /t 8 /nobreak >nul  
type dev-server.log 
