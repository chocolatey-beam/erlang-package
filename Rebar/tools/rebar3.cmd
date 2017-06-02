@echo off
@call :find_erts_dir

@set rebar_cng_dir=Rebar3
@set base_cng_dir=%ChocolateyInstall%/Lib
@set rebar_escript_path=%base_cng_dir%/%rebar_cng_dir%
for %%r in ("%rebar_escript_path%") do @(set rebar_escript_path=%%~sr)

@%erts_bin_dir%/escript.exe %rebar_escript_path%/rebar3 %*
@goto :eof

:: Find the ERTS dir
:find_erts_dir
@set possible_erts_dir=%release_root_dir%\erts-%erts_vsn%
@if exist "%possible_erts_dir%" (
  call :set_erts_dir_from_default
) else (
  call :set_erts_dir_from_erl
)
@goto :eof

:: Set the ERTS dir from the passed in erts_vsn
:set_erts_dir_from_default
@set erts_dir=%possible_erts_dir%
@for %%e in ("%erts_dir%") do set erts_dir=%%~se
@set rootdir=%release_root_dir%
@for %%r in ("%rootdir%") do set rootdir=%%~sr
@goto :eof

:: Set the ERTS dir from erl
:set_erts_dir_from_erl
@for /f "delims=" %%i in ('where erl') do @(
  set erl=%%~si
)

@set dir_cmd="%erl%" -noshell -eval "io:format(\"~s\", [filename:nativename(code:root_dir())])." -s init stop
%dir_cmd% > %TEMP%/erlroot.txt 
@set /P erl_root=< %TEMP%/erlroot.txt
@for %%f in ("%erl_root%") do set erl_root=%%~sf
@set erts_dir_cmd=dir /b "%erl_root%"\erts*
%erts_dir_cmd% > %TEMP%/ertsdir.txt
@set /P erts_dir_name=< %TEMP%/ertsdir.txt
@set erts_bin_dir=%erl_root%\%erts_dir_name%\bin
@for %%e in ("%erts_bin_dir%") do set erts_bin_dir=%%~se
@goto :eof

