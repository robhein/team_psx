@echo off

IF "%PROCESSOR_ARCHITECTURE%"=="x86" set XMD_DIR=C:\Xilinx\14.3\ISE_DS\EDK\bin\nt
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" set XMD_DIR=C:\Xilinx\14.3\ISE_DS\EDK\bin\nt64

%XMD_DIR%\xmd.exe -tcl download.tcl

pause
