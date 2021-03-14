@echo off
rem --------------------------------------------------------
rem which.cmd
rem Adapted from https://stackoverflow.com/a/304441
rem Synonym to Linux 'which' command, looks for file
rem on path. Extended version for windows command line.
rem Will also find folders...
rem Use: place the file which.cmd somewhere in your path.
rem --------------------------------------------------------

:: use extra command environment
setlocal enableextensions enabledelayedexpansion

:: no argument will display help
:usage
if "x%1"=="x" (
    echo Usage: WHICH ^<progName^> ^<alt^> ^<--verbose^> 
    echo        Search PATH for existence of ^<progName^>.
    echo        If ^<progName^> is not found different extensions from
    echo        %PATHEXT% 
    echo        will be evaluated as well.
    echo        If ^<progName^> is not found in PATH and parameter ^<alt^>
    echo        is used, ^<alt^> will be searched using 'WHERE /R'.
    echo        When ^<--verbose^> is used extmore information about the 
    echo        search will be displayed.
    endlocal
    goto :close
)

:: searchfile is used for the WHERE search
set searchfile=%1

:: check command line arguments
set verbose=0
set searchcontinue=0
if %2. EQU . (
  goto :checkprogname
) else (
  goto :continue_check
)

:: more then one argument from command line
:continue_check
if /I "%2" EQU "--verbose" (
  set verbose=1
  goto :checkprogname
  ) else (
      if exist %2 (
          set searchcontinue=1
          set searchfolder=%2  
        ) else (
          set searchcontinue=0
        )
      if not %3.==. (
        if /I "%3" EQU "--verbose" (
          set verbose=1
          ) 
        )
    )
goto :checkprogname
)

:: arguments checked, first check the file argument itself
:checkprogname
set fullspec=
if %verbose%. EQU 1. echo|set /p=Does %1 exist in path...
set found=0
set extmore=0
call :find_it %1
if %verbose%. EQU 1. (
  if %found%. EQU 0. echo  it doesn't, trying extensions list...
)

:: during checkprogname the file wasn't found, continue to loop 
:: through the path extensions from environment var 'pathext'
set mypathext=!pathext!
:loop1
    :: stop if found or out of extensions.
    set evalext=1
    if "x!mypathext!"=="x" goto :loop1end

    :: get the next extension and try it.
    for /f "delims=;" %%j in ("!mypathext!") do (
        set myext=%%j
      )
    call :find_it %1!myext!

:: remove the extension (not overly efficient but it works).
:loop2
  if not "x!myext!"=="x" (
      set extmore=1
      set myext=!myext:~1!
      set mypathext=!mypathext:~1!
      goto :loop2
  )
  if not "x!mypathext!"=="x" set mypathext=!mypathext:~1!
  goto :loop1

:: we do not have a match, echo results to screen when verbose
:: was used, forward to checkout function for errorlevel
:loop1end
if %verbose%. EQU 1. echo|set /p =.... %1 not found 
if %verbose%. EQU 1. if %searchcontinue%.==1. echo continuing search on %searchfolder% (this might take long)
:end
goto :checkiffound

:: we haven't found the file in path and with different extensions
:: an extra search path was given, check that with WHERE
:wherefile
if %verbose%. EQU 1. echo      WHERE /R %searchfolder% %searchfile%
where /Q /R %searchfolder% %searchfile%
if %verbose%. EQU 1. (
  if errorlevel 2 echo      Something is wrong, maybe no read access to %searchfolder%?
  if errorlevel 1 echo      File %searchfile% not found on %searchfolder%
)
goto :close

:: checkout function which sets errorlevel based on search result
:checkiffound
if %found%. EQU 0. (
  if %searchcontinue%.==1. (
    goto :wherefile
  ) else (
    set errorlevel=1
    goto :close
  )
) else (
  set errorlevel=0
)

:: search for the file in the path
:find_it
  for %%i in (%1) do set fullspec=%%~$PATH:i
  if not "x!fullspec!"=="x" (
    @echo.   !fullspec!
    goto :close
    ) 
  goto :eof

:: finished, remove added environment variables and exit
:close
endlocal
EXIT /B
