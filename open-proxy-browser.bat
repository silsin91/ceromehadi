@echo off
echo ========================================================
echo          Chrome Proxy for GitHub Codespaces
echo ========================================================
echo.
echo This will open a new Google Chrome window that uses the
echo internet connection from your GitHub Codespace.
echo.
echo Make sure your Codespace is running and port 10808 is forwarded!
echo.
echo Press any key to open the browser...
pause >nul

start "" chrome.exe --user-data-dir="%tmp%\codespace-chrome" --proxy-server="socks5://127.0.0.1:10808"

echo.
echo Chrome has been launched! 
echo If it says "No internet", make sure port 10808 is forwarded in VS Code.
echo.
pause