/* GSolone 26/5/21
   Credits:
    https://nsis.sourceforge.io/GetOptions
    https://nsis.sourceforge.io/Reference/Sleep
    https://nsis.sourceforge.io/GetFileVersion
    https://nsis.sourceforge.io/Reference/CopyFiles
    https://nsis.sourceforge.io/Graying_out_Section_(define_mandatory_sections)
    https://nsis-dev.github.io/NSIS-Forums/html/t-124640.html
    https://nsis-dev.github.io/NSIS-Forums/html/t-255747.html
    https://stackoverflow.com/a/18139991/2220346
    https://stackoverflow.com/a/15633078/2220346
    https://stackoverflow.com/questions/18999481/nsis-weird-behavior-with-getparameters
    https://stackoverflow.com/questions/50493006/how-to-compare-two-string-in-nsis
   Modifiche:
    6/3/23 1.6- code refactoring.
    11/11/22 1.5- aggiungo la section Post per fare un po' di pulizia al termine installazione (rimuovo pacchetto setup N++ + file LATEST_NPP preso da GitHub).
    20/9/22 1.4- rilevo automaticamente l'ultima versione disponibile (prendo da GitHub la versione dal mio SW_Updates) e scarico il pacchetto necessario.
    22/7/22 1.3- integro il plugin di Compare.
    14/6/22 1.2- nuovi XML Tools.
    18/5/22 1.1- provo a unire tutto sotto lo stesso tetto (installazione x86/x64)
*/

!define PRODUCT_NAME "Notepad++ Custom Installer"
!define PRODUCT_VERSION "1.6"
!define PRODUCT_VERSION_MINOR "0.0"
!define PRODUCT_PUBLISHER "Emmelibri S.r.l."
!define PRODUCT_WEB_SITE "https://www.emmelibri.it"
!define PRODUCT_BUILD "${PRODUCT_NAME} ${PRODUCT_VERSION}.${PRODUCT_VERSION_MINOR} (build ${MyTIMESTAMP})"

!include "MUI.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!addplugindir "Plugins"

!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_NODESC
!define MUI_ICON "Include\notepad-plus-plus.ico"
!define /date MyTIMESTAMP_Yr "%Y"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro GetParameters
!insertmacro GetOptions
!insertmacro GetFileVersion

VIProductVersion "${PRODUCT_VERSION}.${PRODUCT_VERSION_MINOR}"
VIAddVersionKey ProductName "${PRODUCT_NAME}"
VIAddVersionKey Comments "${PRODUCT_NAME}"
VIAddVersionKey CompanyName "Emmelibri S.r.l."
VIAddVersionKey LegalCopyright GSolone
VIAddVersionKey FileDescription "Installs Notepad++ x86/x64 with a custom configuration"
VIAddVersionKey FileVersion ${PRODUCT_VERSION}
VIAddVersionKey ProductVersion ${PRODUCT_VERSION}
VIAddVersionKey InternalName "${PRODUCT_VERSION}"
VIAddVersionKey LegalTrademarks "GSolone, 2022"
VIAddVersionKey OriginalFilename "NPPInstaller-${PRODUCT_VERSION}.exe"

Var NPP_VersionFile
Var NPP_InstallerVersion
Var NPP_vLATEST

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "EM_NPPInstaller_${PRODUCT_VERSION}.exe"
InstallDir "$TEMP"
ShowInstDetails show
BrandingText "Emmelibri S.r.l. - GSolone ${MyTIMESTAMP_Yr}"

Section "" NPPGETLATEST
  StrCpy $NPP_VersionFile "https://raw.githubusercontent.com/gioxx/SWUpdates-Alert/main/updates/LATEST_NPP"
  DetailPrint "Scarico file di versione da $NPP_VersionFile"
  inetc::get /WEAKSECURITY $NPP_VersionFile "$TEMP\LATEST_NPP" /END
  Pop $0
  StrCmp $0 "OK" versionfile_done
   DetailPrint "Ho riscontrato problemi nel download del file."
   DetailPrint "Termino l'installazione, contattare l'HelpDesk di riferimento."
  goto versionfile_goodbye

  versionfile_done:
   FileOpen $4 "$TEMP\LATEST_NPP" r
   FileRead $4 $NPP_vLATEST
   FileClose $4
   StrCpy $NPP_InstallerVersion $NPP_vLATEST "" 1
   DetailPrint "NPPvLATEST $NPP_vLATEST"
   DetailPrint "Installer version $NPP_InstallerVersion"
  
  versionfile_goodbye:
SectionEnd

Section "Disinstalla Notepad++ x86 precedenti" UNINST_X86
  DetailPrint "Eseguo disinstallazione: $PROGRAMFILES\Notepad++\uninstall.exe"
  nsExec::Exec "$PROGRAMFILES\Notepad++\uninstall.exe /S"
  RmDir /r "$PROGRAMFILES\Notepad++"
SectionEnd

Section "Notepad++ x64 Custom Installation" INST_X64
  SetOutPath "$TEMP"
  ;URL di esempio per scaricare NPP: https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.5/npp.7.9.5.Installer.x64.exe
  IfFileExists "$TEMP\npp.$NPP_InstallerVersion.Installer.x64.exe" download_done
   DetailPrint "Scarico Notepad++ x64 da https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$NPP_InstallerVersion/npp.$NPP_InstallerVersion.Installer.x64.exe"
   inetc::get /WEAKSECURITY "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$NPP_InstallerVersion/npp.$NPP_InstallerVersion.Installer.x64.exe" "$TEMP\npp.$NPP_InstallerVersion.Installer.x64.exe" /END
   Pop $0
   StrCmp $0 "OK" download_done
    DetailPrint "Ho riscontrato problemi nel download del file."
    DetailPrint "Termino l'installazione, contattare l'HelpDesk di riferimento."
    goto npp_goodbye

  download_done:
   IfFileExists "$PROGRAMFILES64\Notepad++\uninstall.exe" nppx64_found nppx64_notfound
    nppx64_found:
     ${GetFileVersion} "$PROGRAMFILES64\Notepad++\notepad++.exe" $R0
     ${If} $R0 == "$NPP_InstallerVersion.0"
      DetailPrint "Questa versione di Notepad++ x64 è già installata sulla macchina."
     ${Else}
      goto nppx64_notfound
     ${EndIf}
     goto nppx64_done

  nppx64_notfound:
   DetailPrint "Installo Notepad++ x64 $NPP_InstallerVersion, attendi."
   nsExec::Exec "$TEMP\npp.$NPP_InstallerVersion.Installer.x64.exe /S /noUpdater"
   Sleep 10000

  nppx64_done:
   SetOutPath "$PROGRAMFILES64\Notepad++\"
   SetOverwrite ifdiff
   File "Include\config.model.xml"
   CopyFiles "$PROGRAMFILES64\Notepad++\localization\italian.xml" "$PROGRAMFILES64\Notepad++\nativeLang.xml"
   SetOutPath "$PROGRAMFILES64\Notepad++\Plugins\XMLTools"
   File "Include\XMLTools.dll"
   SetOutPath "$PROGRAMFILES64\Notepad++\Plugins\ComparePlugin"
   File "Include\ComparePlugin.dll"
   SetOutPath "$PROGRAMFILES64\Notepad++\Plugins\ComparePlugin\ComparePlugin"
   File "Include\ComparePlugin\git2.dll"
   File "Include\ComparePlugin\sqlite3.dll"

  npp_goodbye:
SectionEnd

Section "Notepad++ x86 Custom Installation" INST_X86
  SetOutPath "$TEMP"
  ;URL di esempio per scaricare NPP: https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.5/npp.7.9.5.Installer.exe
  IfFileExists "$TEMP\npp.$NPP_InstallerVersion.Installer.exe" download_done
   DetailPrint "Scarico Notepad++ x86 da https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$NPP_InstallerVersion/npp.$NPP_InstallerVersion.Installer.exe"
   inetc::get /WEAKSECURITY "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$NPP_InstallerVersion/npp.$NPP_InstallerVersion.Installer.exe" "$TEMP\npp.$NPP_InstallerVersion.Installer.exe" /END
   Pop $0
   StrCmp $0 "OK" download_done
   DetailPrint "Ho riscontrato problemi nel download del file."
   DetailPrint "Termino l'installazione, contattare l'HelpDesk di riferimento."
   goto npp_goodbye

  download_done:
   IfFileExists "$PROGRAMFILES\Notepad++\uninstall.exe" nppx86_found nppx86_notfound
    nppx86_found:
     ${GetFileVersion} "$PROGRAMFILES\Notepad++\notepad++.exe" $R0
     ${If} $R0 == "$NPP_InstallerVersion.0"
      DetailPrint "Questa versione di Notepad++ x86 è già installata sulla macchina."
     ${Else}
      goto nppx86_notfound
     ${EndIf}
     goto nppx86_done

  nppx86_notfound:
   DetailPrint "Installo Notepad++ x86 $NPP_InstallerVersion, attendi."
   nsExec::Exec "$TEMP\npp.$NPP_InstallerVersion.Installer.exe /S /noUpdater"
   Sleep 10000

  nppx86_done:
   SetOutPath "$PROGRAMFILES\Notepad++\"
   SetOverwrite ifdiff
   File "Include\config.model.xml"
   CopyFiles "$PROGRAMFILES\Notepad++\localization\italian.xml" "$PROGRAMFILES\Notepad++\nativeLang.xml"
   SetOutPath "$PROGRAMFILES\Notepad++\Plugins\XMLTools"
   File "Include\x86\XMLTools.dll"
   SetOutPath "$PROGRAMFILES\Notepad++\Plugins\ComparePlugin"
   File "Include\x86\ComparePlugin.dll"
   SetOutPath "$PROGRAMFILES\Notepad++\Plugins\ComparePlugin\ComparePlugin"
   File "Include\x86\ComparePlugin\git2.dll"
   File "Include\x86\ComparePlugin\sqlite3.dll"

  npp_goodbye:
SectionEnd

Section -Post
  DetailPrint "Pulizia ..."
  SetOutPath $TEMP
  IfFileExists "$TEMP\LATEST_NPP" 0 +2
   Delete "$TEMP\LATEST_NPP"
  IfFileExists "$TEMP\npp.$NPP_InstallerVersion.Installer.exe" 0 +2
   Delete "$TEMP\npp.$NPP_InstallerVersion.Installer.exe"
SectionEnd

Function .onInit
  SetShellVarContext All
  !insertmacro UnselectSection ${UNINST_X86}
  !insertmacro UnselectSection ${INST_X64}
  !insertmacro UnselectSection ${INST_X86}
  
  ${If} ${RunningX64}
    DetailPrint "Windows x64"
    IfFileExists "$PROGRAMFILES\Notepad++\uninstall.exe" nppx86_found nppx86_notfound
     nppx86_found:
      SectionSetFlags ${UNINST_X86} 17
      goto nppx86_done
    nppx86_notfound:
      SectionSetFlags ${UNINST_X86} ${SF_RO}
    nppx86_done:
    SectionSetFlags ${INST_X64} 17
    SectionSetFlags ${INST_X86} ${SF_RO}
  ${Else}
    DetailPrint "Windows x86, passo a installazione 32 bit"
    SectionSetFlags ${UNINST_X86} ${SF_RO}
    SectionSetFlags ${INST_X64} ${SF_RO}
    SectionSetFlags ${INST_X86} 17
  ${EndIf}
FunctionEnd