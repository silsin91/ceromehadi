@echo off
echo Starting Chrome Docker Codespace...
docker compose up -d
echo.
echo ================ Chrome Codespace Ready ================
echo To see the links and passwords, run the following command:
echo bash .devcontainer/start-stack.sh
echo.
pause