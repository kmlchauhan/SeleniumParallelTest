rem @echo off

--------- Create folder structure

cd DevOps_Utilities

if NOT EXIST "Deployment\Installable\DB_Scripts" mkdir Deployment\Installable\DB_Scripts\


if NOT EXIST "Deployment\Installable\Install" mkdir Deployment\Installable\Install\


rem --------- Copying and deleteing the files & folders which are not required
cd ..
xcopy /S /O /Y Database\*.* DevOps_Utilities\Deployment\Installable\DB_Scripts /X /E

xcopy /S /O /Y Devops_Utilities\Buildscripts\Install\*.* Devops_Utilities\Deployment\Installable\Install /X /E

pushd
cd %~dp0
echo.
echo -------------------------------------------------------------
echo Building the deployment package ...
echo -------------------------------------------------------------
echo.

echo --------  %~dp0

set /a OLD_BUILD_NUMBER=%BUILD_NUMBER% - 1
set OLD_DBSCRIPTS_PACKAGE_NAME=DBSCRIPTS_%OLD_BUILD_NUMBER%.zip

set DBSCRIPTS_PACKAGE_NAME=DBSCRIPTS_%BUILD_NUMBER%.zip

ECHO OLD_PackageName = %OLD_DBSCRIPTS_PACKAGE_NAME%
ECHO PackageName = %DBSCRIPTS_PACKAGE_NAME%

rem --------------------------------------------------------------
echo Cleanup Deployment files ...
rem --------------------------------------------------------------

if exist "%OLD_DBSCRIPTS_PACKAGE_NAME%" del /f /q %OLD_DBSCRIPTS_PACKAGE_NAME%


rem --------------------------------------------------------------
echo Deploy Settings Files  ...
rem --------------------------------------------------------------
if NOT EXIST ".\Deployment\Installable\DBSCRIPTS" goto ERROR



rem --------------------------------------------------------------
echo Creating DBSCRIPTS_Build.zip ...
rem --------------------------------------------------------------
7z.exe a -r ...\..\%DBSCRIPTS_PACKAGE_NAME% .\Deployment\Installable\*.*


rem --------------------------------------------------------------
echo Creating FCIV Checksum for Zipped CMSWS Package ...
rem --------------------------------------------------------------

fciv %DBSCRIPTS_PACKAGE_NAME% -sha1 > DBChecksum_%BUILD_NUMBER%.txt


rd /s /q .\Deployment\Installable

if NOT %ERRORLEVEL% == 0 goto ERROR

cd %~dp0
exit /b 0

:ERROR
echo.
echo An error occured while creating the deployment package. Exiting...
echo.
cd %~dp0
exit /b -1