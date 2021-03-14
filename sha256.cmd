@echo off
rem --------------------------------------------------------
rem sha256.cmd
rem creates a sha256 hash of a file given as argument.
rem checks if the file has a corrosponding '.sha256'
rem file and if so compares the output of the given and the
rem computed hash.
rem --------------------------------------------------------

:: use extra command environment (if needed)
setlocal enableextensions enabledelayedexpansion

:: need argument
if %1.==. goto :usage

set verbose=0

:: more then one argument from command line
:checkarguments
if /I "%1" EQU "--verbose" goto :usage
if /I "%2" EQU "--verbose" (
  set verbose=1
  )
goto :checkfile
)

:: if the file doesn't exist show usage
:checkfile
if NOT EXIST %1 (
  if %verbose%.==1. echo Argument file %1 does not exist
  goto :usage
)

:: file exists, compute hash
:computehash
if EXIST %1.sha256 (
  if %verbose%.==1. (
    echo Verifying sha256 hash value of %1
    echo against contents of file %1.sha256
    )     
    goto :full_check
  ) ELSE (
    if %verbose%.==1. (
      echo Creating sha256 hash value of %1
      )
    goto :get_hash
    )
goto :usage

:: use powershell to compute hash, hash is put into clipboard
:get_hash
powershell -NoProfile -Command "Get-FileHash -Path '%1' -Algorithm SHA256 | Select -ExpandProperty 'Hash'" | clip
powershell -NoProfile -Command Get-Clipboard
if %verbose%.==1. (
  echo The hashvalue is placed on the clipboard. 
  echo Wait 5 seconds or press key.
  timeout 5 >null
)
goto end

:full_check
powershell -NoProfile -Command "Get-FileHash -Path '%1' -Algorithm SHA256 | Select -ExpandProperty 'Hash' | Compare-Object -ReferenceObject (Get-Content '%1'.sha256).SubString(0,64) -PassThru -IncludeEqual | %%{ if ($_.SideIndicator -ne '==') {write-host -f red 'Hash waarde wijkt af!!'} else {write-host -f green 'Geen fouten gevonden'} }"
goto end

:: display usage information
:usage
echo Usage: SHA256 ^<fileName^> ^<--verbose^> 
echo        Creates SHA256 hash for ^<fileName^> and puts the
echo        value on the clipboard. Using ^<--verbose^>  will
echo        echo the results to screen.
goto end

:end
