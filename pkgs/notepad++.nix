{ stdenv
, lib
, mkWindowsApp
, wine
, wineArch
, fetchurl
, imagemagick
, makeDesktopItem
, makeDesktopIcon
, copyDesktopItems
, copyDesktopIcons
}:
let
  version = "8.3.1";

  srcs = {
    win64 = fetchurl {
      url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v${version}/npp.${version}.Installer.x64.exe";
      sha256 = "11cbfksxqzdzdail4xqfcm8sm7vm0brmjpkr1v3wqjc3j6c9snj2";
    };

    win32 = fetchurl {
      url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v${version}/npp.${version}.Installer.exe";
      sha256 = "060q1dbi0g9wwvj5b0sm9ijiv4xg3xb2pl688i62fgvphg06nd7f";
    };
  };
in mkWindowsApp rec {
  inherit version wine wineArch;

  pname = "notepad++";
 
  src = srcs."${wineArch}";

  nativeBuildInputs = [ copyDesktopItems copyDesktopIcons ];
  dontUnpack = true;
  fileMap = { "$HOME/.config/Notepad++" = "drive_c/users/$USER/Application Data/Notepad++"; };

  winAppInstall = ''
    wine start /unix ${src} /S
    wineserver -w
    rm -f "$WINEPREFIX/drive_c/Program Files/Notepad++/uninstall.exe"
    rm -fR "$WINEPREFIX/drive_c/Program Files/Notepad++/updater"

    # Workaround for a Notepad++ config directory that won't sit still :)
    # Use symlinks to enforce a single config directory
    mkdir -p "$WINEPREFIX/drive_c/users/$USER/Application Data/Notepad++"
    rm -fR "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Notepad++"
    mkdir -p "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming"
    ln -s "$WINEPREFIX/drive_c/users/$USER/Application Data/Notepad++" "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Notepad++"
  '';

  winAppRun = ''
   wine start /unix "$WINEPREFIX/drive_c/Program Files/Notepad++/notepad++.exe" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/notepad++
    
    runHook postInstall
  '';

  desktopItems = let
    textTypes = builtins.map (s: "text/" + s) [ "plain" "html" "rust" "vbscript" "x-cmake" "x-changelog" "x-cobol" "x-common-lisp" "x-csharp" "x-c++src" "x-csrc" "x-erlang" "x-fortran" "x-haskell" "x-java" "x-log" "x-makefile" "x-objcsrc" "x-python" "x-readme" "x-scheme" "x-install" ];

    appTypes = builtins.map (s: "application/" + s) [ "json" "x-msi" "xml" "x-perl" ];
    mimeTypes = builtins.concatLists [ textTypes appTypes ];
  in [
    (makeDesktopItem {
      inherit mimeTypes;

      name = "Notepad++";
      exec = pname;
      icon = pname;
      desktopName = "Notepad++";
      genericName = "Text Editor";
      categories = ["Utility" "TextEditor"];
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = "notepad++";
    icoIndex = 2;

    src = fetchurl {
      url = "https://notepad-plus-plus.org/favicon.ico";
      sha256 = "1av2m6m665ccfngnzqnbsnv2aky907p2c6ggvfxrwbp70szgj9vi";
    };
  };

  meta = with lib; {
    description = "A text editor and source code editor for use under Microsoft Windows. It supports around 80 programming languages with syntax highlighting and code folding. It allows working with multiple open files in a single window, thanks to its tabbed editing interface.";
    homepage = "https://notepad-plus-plus.org/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emmanuelrosa ];
    platforms = [ "x86_64-linux" "i386-linux" ];
  };
}
