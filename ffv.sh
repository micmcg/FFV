#!/usr/bin/env bash

versions=('3.6.9' '4.0.1' '5.0.1' '6.0.2' '7.0.1' '8.0.1' '9.0.1' 
    '10.0.1' '11.0' '12.0' '13.0' '14.0.1' '15.0.1' '16.0.2' '17.0.1' '18.0.2' '19.0.2'
    '20.0.1' '21.0' '22.0' '23.0.1' '24.0' '25.0.1' '26.0' '27.0.1' '28.0' '29.0.1'
    '30.0' '31.0' '32.0.3' '33.1.1' '34.0' '35.0.1' '36.0.4' '37.0.1')

uninstall=${UNINSTALL:-false}
clean=${CLEAN:-false}
force=${FORCE:-false}

while getopts ":u :c :f" opt; do
    case $opt in
    u)
        uninstall=true
        ;;
    c)
        clean=true
        ;;
    f)
        force=true
        ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
  esac
done

if $uninstall
    then
        echo "### Uninstalling FFV ###"
        echo "  # Removing FFV Cache #"
        rm -rf ~/.ffv
        echo "  # Removing FFV Firefox Applications #"
        rm -rf /Applications/Firefox-Versions
        echo "  # Removing FFV profiles"
        for i in "${versions[@]}"; do
            rm -rf ~/Library/Application\ Support/Firefox/Profiles/*.Firefox-$i-FFV
        done
        echo "### FFV Uninstall complete ###"
        exit
fi
if $clean
    then
        echo "Enabling -Clean mode, will download fresh copies of the installers"
fi

if $force
    then
        echo "Enabling -Force mode, will overwrite applications and profiles"
fi

mkdir -p /Applications/Firefox-Versions
mkdir -p ~/.ffv && cd ~/.ffv

for i in "${versions[@]}"; do
    echo ""
    echo "### INSTALLING FIREFOX $i ###"
    if ! $clean && [ -f ./Firefox-$i.dmg ]
        then
            echo "  # Skipping download Firefox $i #"
        else
            echo "  # Downloading Firefox $i #"
            curl -L ftp://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$i/mac/en-GB/Firefox%20$i.dmg -o ./Firefox-$i.dmg
    fi
    if ! $force && [ -d /Applications/Firefox-Versions/Firefox-$i.app ]
        then
            echo "  # Skipping copying application #"
        else
            echo "  # Copying application to /Applications/Firefox-Versions/Firefox-$i #"
            if [ -d /Volumes/Firefox ]
                then
                    echo "  # Unmounting existing Firefox Installer"
                    hdiutil unmount /Volumes/Firefox/
            fi
            hdiutil mount ./Firefox-$i.dmg
            if [ -d /Applications/Firefox-Versions/Firefox-$i.app ]
                then
                    rm -rf /Applications/Firefox-Versions/Firefox-$i.app
            fi
            cp -R /Volumes/Firefox/Firefox.app/ /Applications/Firefox-Versions/Firefox-$i.app
            hdiutil unmount /Volumes/Firefox/
    fi
    if ! $force && [ -f ~/Library/Application\ Support/Firefox/Profiles/*.Firefox-$i-FFV/prefs.js ]
        then
            echo "  # Skipping profile creation #"
        else
            if [ -d ~/Library/Application\ Support/Firefox/Profiles/*.Firefox-$i-FFV ]
                then
                    echo "  # Deleting existing profile Firefox-$i #"
                    rm -rf ~/Library/Application\ Support/Firefox/Profiles/*.Firefox-$i-FFV
            fi

            echo "  # Creating profile for Firefox-$i #"
            if [ -f /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin-orig ]
                then
                    /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin-orig -CreateProfile Firefox-$i-FFV
                else
                    /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin -CreateProfile Firefox-$i-FFV
            fi
            echo ""
            echo "  # Disabling auto update and default browser check for Firefox-$i #"
            find ~/Library/Application\ Support/Firefox/Profiles/*.Firefox-$i-FFV -name prefs.js -print0 -exec sh -c 'echo "
            user_pref(\"app.update.auto\", false);
            user_pref(\"app.update.disable_button.showUpdateHistory\", false);
            user_pref(\"app.update.enabled\", false);
            user_pref(\"browser.shell.checkDefaultBrowser\", false);
            user_pref(\"browser.rights.3.shown\", true);" >> $1' -- {} \;
            echo ""
    fi

    if ! $force && [ -f /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin-orig ]
        then
            echo "  # Skipping profile binding #"
        else
            echo "  # Binding profile for Firefox-$i #"
            mv /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin-orig
            echo "#!/bin/bash
            exec \"/Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin-orig\" -P Firefox-$i-FFV" > /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin
            chmod +x /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin

            if [ -f /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox ]
                # Newer versions of Firefox use firefox not firefox-bin
                then
                    mv /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-orig
                    ln -s /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox-bin /Applications/Firefox-Versions/Firefox-$i.app/Contents/MacOS/firefox
            fi
    fi

    echo "### FINISHED INSTALLING FIREFOX $i ###"
    echo ""
done

echo "### FINISHED INSTALLING ALL THE FIREFOXES ###"


