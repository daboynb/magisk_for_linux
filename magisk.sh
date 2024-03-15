#!/bin/bash

# Sudo check
if [ `whoami` = root ];
then
    echo Please do not run this script as root or using sudo
    return 1 2>/dev/null
    exit 1
fi

# Functions 

copy_files() {
    echo ""
    echo "Copying files"
    cp $HOME/Magisk/wokdir/assets/boot_patch.sh $HOME/Magisk/pc_magisk/boot_patch.sh
    cp $HOME/Magisk/wokdir/assets/util_functions.sh $HOME/Magisk/pc_magisk/util_functions.sh
    cp $HOME/Magisk/wokdir/lib/x86_64/libmagiskboot.so $HOME/Magisk/pc_magisk/magiskboot
    cp $HOME/Magisk/wokdir/lib/armeabi-v7a/libmagisk32.so $HOME/Magisk/pc_magisk/magisk32
    cp $HOME/Magisk/wokdir/lib/arm64-v8a/libmagisk64.so $HOME/Magisk/pc_magisk/magisk64
    cp $HOME/Magisk/wokdir/lib/arm64-v8a/libmagiskinit.so $HOME/Magisk/pc_magisk/magiskinit
}

install_dependencies() {
    echo ""
    echo "Installing dependencies"
    echo ""
    sudo apt install adb fastboot dos2unix unzip ed curl -y
    PATH=$PATH:/usr/lib/android-sdk/platform-tools/fastboot
    PATH=$PATH:/usr/lib/android-sdk/platform-tools/adb

    # Check 
    programs=("adb" "fastboot" "dos2unix" "unzip" "curl" "ed")

    for program in "${programs[@]}"; do
        if sudo which "$program" >/dev/null 2>&1; then
            echo "$program is installed"
            echo ""
        else
            echo "$program is not installed"
            sleep 10
            exit 1
        fi
    done
}
adapt_the_script_for_pc() {
    echo ""
    echo "Adapting script for pc"
    echo ""
    
    # Get line
    line=$(grep -n '/proc/self/fd/$OUTFD' util_functions.sh | awk '{print $1}' | sed 's/.$//')

    # Add echo "$1" and delete the line
    (
    echo "$line"
    echo 'd'
    echo "$line-1"
    echo a
    echo 'echo "$1"'
    echo .
    echo wq
    ) | ed util_functions.sh > /dev/null 2>&1 

    # Replace getprop
    sed -i 's/getprop/adb shell getprop/g' util_functions.sh 

    # Adb
    echo "Waiting for adb conenction"
    echo ""
    while true; do adb get-state > /dev/null 2>&1 && break; done
}

patch_the_image() {
    # Patch
    echo ""
    echo "You need to accept the popup that appears on the phone"
    echo ""
    echo "Now if adb is working we can patch the image"
    echo ""
    read -e -p "Drag & drop your boot.img : " file
    eval file=$file
    sh boot_patch.sh $file
}

# Menu
mainmenu() {
    echo -ne "
1) Use the last stable magisk 
2) Use magisk canary
0) Exit
Choose an option:  "
    read -r ans
    case $ans in

    1)
            # Dependencies
            install_dependencies
            
            # Delete old dir
            echo "Deleteting old dir"
            rm -rf $HOME/Magisk
            
            # Make a dir for download
            mkdir $HOME/Magisk
            cd $HOME/Magisk
            
            # Download lastest release
            echo ""
            echo "Downloading lastest magisk"
            echo ""
            wget $(curl -s https://api.github.com/repos/topjohnwu/Magisk/releases/latest | grep 'browser_download_url' | cut -d\" -f4)
            
            # Remove no needed apk
            rm $HOME/Magisk/stub-release.apk
            
            # Unzip the apk on his directory
            echo ""
            echo "Unzipping"
            echo ""
            mkdir $HOME/Magisk/wokdir
            unzip $HOME/Magisk/Magisk* -d $HOME/Magisk/wokdir
            
            # Create direcorty where file will be copied
            mkdir $HOME/Magisk/pc_magisk
            
            # Copy all files needed
            copy_files
            
            # Remove old dir
            rm -rf $HOME/Magisk/wokdir
            
            # Enter into folder 
            cd $HOME/Magisk/pc_magisk
            
            # Adapt_the_script_for_pc
            adapt_the_script_for_pc
            
            # Patch
            patch_the_image
        ;;
    2)
            
            # Dependencies
            install_dependencies
            
            # Delete old dir
            echo "Deleteting old dir"
            rm -rf $HOME/Magisk
            
            # Make a dir for download
            mkdir $HOME/Magisk
            cd $HOME/Magisk
            
            # Download lastest release
            echo ""
            echo "Downloading lastest magisk"
            echo ""
            wget https://raw.githubusercontent.com/topjohnwu/magisk-files/canary/app-debug.apk
            
            # Unzip the apk on his directory
            echo ""
            echo "Unzipping"
            echo ""
            mkdir $HOME/Magisk/wokdir
            unzip $HOME/Magisk/app-debug.apk -d $HOME/Magisk/wokdir
            
            # Create direcorty where file will be copied
            mkdir $HOME/Magisk/pc_magisk
            
            # Copy all files needed
            copy_files
            
            # Remove old dir
            rm -rf $HOME/Magisk/wokdir
            
            # Enter into folder 
            cd $HOME/Magisk/pc_magisk
            
            # Adapt_the_script_for_pc
            adapt_the_script_for_pc
            
            # Patch
            patch_the_image
        ;;
    0)      
            echo "Bye bye."
            exit 0
            ;;
    *)
        echo "Wrong option."
        mainmenu
        ;;
    esac
}

mainmenu