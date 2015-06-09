@echo off
set gitver=unknown
for /f %%i in ('git describe') do set gitver=%%i
echo module safearg.version_; > src\safearg\version_.d
echo enum appVersion = "%gitver%"; >> src\safearg\version_.d
