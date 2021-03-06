;Exaile Windows installer script
;Modified by Dustin Spicuzza
;Based on the Quod Libet / Ex Falso Windows installer script
;Modified by Steven Robertson
;Based on the NSIS Modern User Interface Start Menu Folder Example Script
;Written by Joost Verburg

    ;compression
    SetCompressor /SOLID LZMA

    !define MULTIUSER_EXECUTIONLEVEL Highest
    !define MULTIUSER_MUI
    !define MULTIUSER_INSTALLMODE_COMMANDLINE
    !include "MultiUser.nsh"

    !define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Exaile"
    !define INSTDIR_KEY "Software\Exaile"
    !define INSTDIR_SUBKEY "InstDir"

;--------------------------------
;Include Modern UI and other libs

    !include "MUI2.nsh"
    !include "LogicLib.nsh"
    !include "x64.nsh"

;--------------------------------
;General

    ;Name and file
    Name "Exaile"
    OutFile "exaile-LATEST.exe"

    ;Default installation folder
    InstallDir "$PROGRAMFILES\Exaile"

    ;Get installation folder from registry if available
    ;InstallDirRegKey HKCU "${INSTDIR_KEY}" ""
    ;doesn't work with multi user -> see onInit..

    ;Request application privileges for Windows Vista+
    RequestExecutionLevel admin

;--------------------------------
;Variables

    Var StartMenuFolder
    Var instdir_temp
    
    Var HAVE_PYTHON
    Var HAVE_PYTHON_ARCH
    Var HAVE_MUTAGEN
    Var HAVE_GSTCOMSDK
    Var HAVE_GSTCOMSDK_32
    Var HAVE_GSTCOMSDK_64
    
    Var NEED_PYTHON
    Var NEED_MUTAGEN
    Var NEED_GSTCOMSDK
    
    Var INSTALL_ARCH
    
;--------------------------------
;Interface Settings

    !define MUI_ABORTWARNING
    !define MUI_ICON "..\..\dist\copy\data\images\exaile.ico"
  
;--------------------------------
;Pages

    !insertmacro MULTIUSER_PAGE_INSTALLMODE
    !insertmacro MUI_PAGE_LICENSE "..\..\COPYING"
    !insertmacro MUI_PAGE_DIRECTORY
    
    Page custom architectureSelect
    Page custom dependenciesCreate dependenciesLeave

    ;Start Menu Folder Page Configuration
    !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
    !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Exaile" 
    !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

    !insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

    !insertmacro MUI_PAGE_INSTFILES

    !insertmacro MUI_UNPAGE_CONFIRM
    !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages

    ; TODO: Should we only support the languages that Exaile supports? 

    !insertmacro MUI_LANGUAGE "English" ;first language is the default language
    !insertmacro MUI_LANGUAGE "Afrikaans"
    !insertmacro MUI_LANGUAGE "Albanian"
    !insertmacro MUI_LANGUAGE "Arabic"
    !insertmacro MUI_LANGUAGE "Basque"
    !insertmacro MUI_LANGUAGE "Belarusian"
    !insertmacro MUI_LANGUAGE "Bosnian"
    !insertmacro MUI_LANGUAGE "Breton"
    !insertmacro MUI_LANGUAGE "Bulgarian"
    !insertmacro MUI_LANGUAGE "Catalan"
    !insertmacro MUI_LANGUAGE "Croatian"
    !insertmacro MUI_LANGUAGE "Czech"
    !insertmacro MUI_LANGUAGE "Danish"
    !insertmacro MUI_LANGUAGE "Dutch"
    !insertmacro MUI_LANGUAGE "Esperanto"
    !insertmacro MUI_LANGUAGE "Estonian"
    !insertmacro MUI_LANGUAGE "Farsi"
    !insertmacro MUI_LANGUAGE "Finnish"
    !insertmacro MUI_LANGUAGE "French"
    !insertmacro MUI_LANGUAGE "Galician"
    !insertmacro MUI_LANGUAGE "German"
    !insertmacro MUI_LANGUAGE "Greek"
    !insertmacro MUI_LANGUAGE "Hebrew"
    !insertmacro MUI_LANGUAGE "Hungarian"
    !insertmacro MUI_LANGUAGE "Icelandic"
    !insertmacro MUI_LANGUAGE "Indonesian"
    !insertmacro MUI_LANGUAGE "Irish"
    !insertmacro MUI_LANGUAGE "Italian"
    !insertmacro MUI_LANGUAGE "Japanese"
    !insertmacro MUI_LANGUAGE "Korean"
    !insertmacro MUI_LANGUAGE "Kurdish"
    !insertmacro MUI_LANGUAGE "Latvian"
    !insertmacro MUI_LANGUAGE "Lithuanian"
    !insertmacro MUI_LANGUAGE "Luxembourgish"
    !insertmacro MUI_LANGUAGE "Macedonian"
    !insertmacro MUI_LANGUAGE "Malay"
    !insertmacro MUI_LANGUAGE "Mongolian"
    !insertmacro MUI_LANGUAGE "Norwegian"
    !insertmacro MUI_LANGUAGE "NorwegianNynorsk"
    !insertmacro MUI_LANGUAGE "Polish"
    !insertmacro MUI_LANGUAGE "PortugueseBR"
    !insertmacro MUI_LANGUAGE "Portuguese"
    !insertmacro MUI_LANGUAGE "Romanian"
    !insertmacro MUI_LANGUAGE "Russian"
    !insertmacro MUI_LANGUAGE "SerbianLatin"
    !insertmacro MUI_LANGUAGE "Serbian"
    !insertmacro MUI_LANGUAGE "SimpChinese"
    !insertmacro MUI_LANGUAGE "Slovak"
    !insertmacro MUI_LANGUAGE "Slovenian"
    !insertmacro MUI_LANGUAGE "SpanishInternational"
    !insertmacro MUI_LANGUAGE "Spanish"
    !insertmacro MUI_LANGUAGE "Swedish"
    !insertmacro MUI_LANGUAGE "Thai"
    !insertmacro MUI_LANGUAGE "TradChinese"
    !insertmacro MUI_LANGUAGE "Turkish"
    !insertmacro MUI_LANGUAGE "Ukrainian"
    !insertmacro MUI_LANGUAGE "Uzbek"
    !insertmacro MUI_LANGUAGE "Welsh"

;------------------------------------------------------------
; DOWNLOAD AND INSTALL DEPENDENCIES FIRST
;!define TEST_URL ""

; Use the official python.org Python packages
!define PYTHON_VERSION          "2.7"
!define PYTHON_FULL_VERSION     "2.7.8"
!define PYTHON_PATH             "C:\Python27"
!define PYTHON_FN_32            "python-${PYTHON_FULL_VERSION}.msi"
!define PYTHON_FN_64            "python-${PYTHON_FULL_VERSION}.amd64.msi"
!define PYTHON_FSIZE            "16MB"
!define PYTHON_URL_32           "http://python.org/ftp/python/${PYTHON_FULL_VERSION}/${PYTHON_FN_32}"
!define PYTHON_URL_64           "http://python.org/ftp/python/${PYTHON_FULL_VERSION}/${PYTHON_FN_64}"
;!define PYTHON_URL_32           "${TEST_URL}/${PYTHON_FN_32}"
;!define PYTHON_URL_64           "${TEST_URL}/${PYTHON_FN_64}"
!define PYTHON_CMD              "msiexec /i $DAI_TMPFILE /passive ALLUSERS=1"

; Use the mutagen setup package
!define MUTAGEN_VERSION         "1.24"
!define MUTAGEN_FN              "mutagen-${MUTAGEN_VERSION}.tar.gz"
!define MUTAGEN_FSIZE           "818KB"
!define MUTAGEN_URL             "https://bitbucket.org/lazka/mutagen/downloads/${MUTAGEN_FN}"
;!define MUTAGEN_URL             "${TEST_URL}/${MUTAGEN_FN}"
!define MUTAGEN_CMD             "${PYTHON_PATH}\python.exe $PLUGINSDIR\install_targz.py $DAI_TMPFILE"

; Use the GStreamer.com SDK
!define GSTCOMSDK_VERSION       "2013.6"
!define GSTCOMSDK_FN_32         "gstreamer-sdk-x86-${GSTCOMSDK_VERSION}.msi"
!define GSTCOMSDK_FN_64         "gstreamer-sdk-x86_64-${GSTCOMSDK_VERSION}.msi"
!define GSTCOMSDK_FSIZE         "106MB"
!define GSTCOMSDK_URL_32        "http://cdn.gstreamer.com/windows/x86/${GSTCOMSDK_FN_32}"
!define GSTCOMSDK_URL_64        "http://cdn.gstreamer.com/windows/x86-64/${GSTCOMSDK_FN_64}"
;!define GSTCOMSDK_URL_32        "${TEST_URL}/${GSTCOMSDK_FN_32}"
;!define GSTCOMSDK_URL_64        "${TEST_URL}/${GSTCOMSDK_FN_64}"
!define GSTCOMSDK_FEATURES      "_gstreamer_core,_gstreamer_system,_gstreamer_playback,_gstreamer_codecs,_gstreamer_networking,_gstreamer_python,_gtk__2.0,_gtk__2.0_python,_gstreamer_codecs_gpl,_gstreamer_codecs_restricted,_gstreamer_networking_restricted"
!define GSTCOMSDK_CMD           "msiexec /i $DAI_TMPFILE /passive ALLUSERS=1 ADDLOCAL=${GSTCOMSDK_FEATURES}"

!include "download.nsi"

Section "-python"
    ${If} $NEED_PYTHON == '1'
        DetailPrint "--- DOWNLOAD PYTHON ---"
        
        ${If} $INSTALL_ARCH == "32"
            !insertmacro downloadAndInstall "Python" "${PYTHON_URL_32}" "${PYTHON_FN_32}" "${PYTHON_CMD}"
        ${Else}
            !insertmacro downloadAndInstall "Python" "${PYTHON_URL_64}" "${PYTHON_FN_64}" "${PYTHON_CMD}"
        ${EndIf}
        
        Call DetectPython
        ${If} $HAVE_PYTHON == 'NOK'
            MessageBox MB_OK "Python installation appears to have failed. You may need to retry manually."
        ${EndIf}
    ${EndIf}
SectionEnd

Section "-mutagen"
    ${If} $NEED_MUTAGEN == '1'
        DetailPrint "--- DOWNLOAD MUTAGEN ---"
        !insertmacro downloadAndInstall "Mutagen" "${MUTAGEN_URL}" "${MUTAGEN_FN}" "${MUTAGEN_CMD}"
        Call DetectMutagen
        ${If} $HAVE_MUTAGEN == 'NOK'
            MessageBox MB_OK "Mutagen installation appears to have failed. You may need to retry manually."
        ${EndIf}
    ${EndIf}
SectionEnd

Section "-gstcomsdk"
    ${If} $NEED_GSTCOMSDK == '1'
    
        DetailPrint "--- DOWNLOAD GSTREAMER.COM SDK ---"
        
        ${If} $INSTALL_ARCH == "32"
            !insertmacro downloadAndInstall "GStreamer.com SDK" "${GSTCOMSDK_URL_32}" "${GSTCOMSDK_FN_32}" "${GSTCOMSDK_CMD}"
            Pop $0
        ${Else}
            !insertmacro downloadAndInstall "GStreamer.com SDK" "${GSTCOMSDK_URL_64}" "${GSTCOMSDK_FN_64}" "${GSTCOMSDK_CMD}"
            Pop $0
        ${EndIf}
    
        ${If} $0 != "0"
            MessageBox MB_OK "GStreamer.com SDK installation appears to have failed. You may need to retry manually."
        ${EndIf}
    ${EndIf}   
SectionEnd

;------------------------------------------------------------
; Install Exaile last

Section "-Exaile" SecExaile

    SetOutPath "$INSTDIR"

    File /r "..\..\dist\copy\*.*" 

    ;Store installation folder
    WriteRegStr SHCTX "${INSTDIR_KEY}" "${INSTDIR_SUBKEY}" $INSTDIR

    ;Multi user uninstaller stuff
    WriteRegStr SHCTX "${UNINST_KEY}" \
    "DisplayName" "Exaile - Music Player for GTK+"
    WriteRegStr SHCTX "${UNINST_KEY}" "DisplayIcon" "$\"$INSTDIR\data\images\exaile.ico$\""
    WriteRegStr SHCTX "${UNINST_KEY}" "UninstallString" \
    "$\"$INSTDIR\uninstall.exe$\" /$MultiUser.InstallMode"
    WriteRegStr SHCTX "${UNINST_KEY}" "QuietUninstallString" \
    "$\"$INSTDIR\uninstall.exe$\" /$MultiUser.InstallMode /S"

    ;Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Exaile.lnk" "$INSTDIR\exaile.bat" "" "$INSTDIR\data\images\exaile.ico"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Exaile (Debug).lnk" "$INSTDIR\exaile.bat" "--console" "$INSTDIR\data\images\exaile.ico"

    !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

!include "arch.nsi"

!include "dependencies.nsi"

!include "detect.nsi"


Function .onInit
    !insertmacro MULTIUSER_INIT
    ;Read the install dir and set it
    ReadRegStr $instdir_temp SHCTX "${INSTDIR_KEY}" "${INSTDIR_SUBKEY}"
    StrCmp $instdir_temp "" skip 0
    StrCpy $INSTDIR $instdir_temp
    skip:
    
    InitPluginsDir
    File /oname=$PLUGINSDIR\install_targz.py install_targz.py
    
    Call DetectPython
    Call DetectMutagen
    Call DetectGstreamerComSDK
    
FunctionEnd

Function .onGUIEnd

    Delete $PLUGINSDIR\install_targz.py

FunctionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

    RMDir /r "$INSTDIR"

    Delete "$INSTDIR\uninstall.exe"

    !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder

    Delete "$SMPROGRAMS\$StartMenuFolder\Exaile.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Exaile (Debug).lnk"
    RMDir "$SMPROGRAMS\$StartMenuFolder"

    ;Old installer wrote the path to HKCU only, delete it
    ;DeleteRegKey HKCU "Software\Exaile"

    DeleteRegKey SHCTX "${UNINST_KEY}"
    DeleteRegKey SHCTX "${INSTDIR_KEY}"

SectionEnd

Function un.onInit
    !insertmacro MULTIUSER_UNINIT
FunctionEnd
