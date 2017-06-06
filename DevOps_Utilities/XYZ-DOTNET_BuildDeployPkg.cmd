rem @echo off

--------- Create folder structure

cd DevOps_Utilities

if NOT EXIST "Deployment\Installable\Wills-DotNet" mkdir Deployment\Installable\Wills-DotNet\


if NOT EXIST "Deployment\Installable\Install" mkdir Deployment\Installable\Install\


rem --------- Copying and deleteing the files & folders which are not required
cd ..
xcopy /S /O /Y Wills\CWM.Wills\_PublishedWebsites\CWM.Wills\*.* DevOps_Utilities\Deployment\Installable\Wills-DotNet /X /E

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
set OLD_WillsDOTNET_PACKAGE_NAME=WillsDOTNET_%OLD_BUILD_NUMBER%.zip

set WillsDOTNET_PACKAGE_NAME=WillsDOTNET_%BUILD_NUMBER%.zip

ECHO OLD_PackageName = %OLD_WillsDOTNET_PACKAGE_NAME%
ECHO PackageName = %WillsDOTNET_PACKAGE_NAME%

rem --------------------------------------------------------------
echo Cleanup Deployment files ...
rem --------------------------------------------------------------
:: if exist "%AdvFeeWS_PACKAGE_NAME%" rmdir /Q %AdvFeeWS_PACKAGE_NAME%
if exist "%OLD_WillsDOTNET_PACKAGE_NAME%" del /f /q %OLD_WillsDOTNET_PACKAGE_NAME%


rem --------------------------------------------------------------
echo Deploy Settings Files  ...
rem --------------------------------------------------------------
if NOT EXIST ".\Deployment\Installable\Wills-DotNet" goto ERROR



rem --------------------------------------------------------------
echo Creating WillsDOTNET_Build.zip ...
rem --------------------------------------------------------------
7z.exe a -r ...\..\%WillsDOTNET_PACKAGE_NAME% .\Deployment\Installable\*.*


rem --------------------------------------------------------------
echo Cleanup Older Checksum
rem --------------------------------------------------------------
set OLD_WillsDOTNETChecksum=WillsDOTNETChecksum_%OLD_BUILD_NUMBER%.txt

if exist "%OLD_WillsDOTNETChecksum%" del /f /q %OLD_WillsDOTNETChecksum%

rem --------------------------------------------------------------
echo Creating FCIV Checksum for Zipped CMS Package ...
rem --------------------------------------------------------------
fciv %WillsDOTNET_PACKAGE_NAME% -both > WillsDOTNETChecksum_%BUILD_NUMBER%.txt

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