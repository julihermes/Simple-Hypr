#!/bin/bash

clear

cat <<"EOF"
   _____ ______  _______  __    ______   __  ____  ______  ____
  / ___//  _/  |/  / __ \/ /   / ____/  / / / /\ \/ / __ \/ __ \
  \__ \ / // /|_/ / /_/ / /   / __/    / /_/ /  \  / /_/ / /_/ /
 ___/ // // /  / / ____/ /___/ /___   / __  /   / / ____/ _, _/
/____/___/_/  /_/_/   /_____/_____/  /_/ /_/   /_/_/   /_/ |_|

Version 0.1
EOF

# Software for nvidia GPU only
nvidia_stage=(
    linux-headers
    nvidia-dkms
    nvidia-settings
    libva
    libva-nvidia-driver-git
)

# The packages
pkgs=(
    pacman-contrib
    greetd
    greetd-tuigreet-bin
    uwsm
    libnewt
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    polkit-gnome
    hyprlock
    hypridle
    ghostty
    ttf-jetbrains-mono-nerd
    ttf-unifont
    noto-fonts-emoji
    starship
    fzf
    man-db
    grc
    bat
    lsd
    lesspipe
    zoxide
    zsh
    neovim
    nautilus
    file-roller
    firefox-bin
    gnome-calculator
    papers
    loupe
    mpv
    mpv-modernz-git
    mpv-thumbfast-git
    hyprpaper
    wget
    btop
    grimblast
    gradia
    python-cairo
    fastfetch


    # wf-recorder
    # pamixer
    # pavucontrol
    # brightnessctl
    # bluez
    # bluez-utils
    # blueman
    # network-manager-applet
    # gnome-themes-extra
)

# Set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

# Function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# Function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if paru -Q $1 &>>/dev/null; then
        echo -e "$COK - $1 is already installed."
    else
        # No package found so installing
        echo -en "$CNT - Now installing $1 ."
        paru -S --noconfirm $1 &>>$INSTLOG &
        show_progress $!
        # Test to make sure package installed
        if paru -Q $1 &>>/dev/null; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # If this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}

# Set some expectations for the user
echo -e "$CNT - You are about to execute a script that would attempt to setup Hyprland.
This script was designed for a fresh minimal installation of Arch Linux with git installed,
if your scenario is different from this, make sure you know what you are doing."
sleep 1

# Attempt to discover if this is a VM or not
echo -e "$CNT - Checking for Physical or VM..."
ISVM=$(hostnamectl | grep Chassis)
echo -e "Using $ISVM"
if [[ $ISVM == *"vm"* ]]; then
    echo -e "$CWR - Please note that VMs are not fully supported and if you try to run this on
    a Virtual Machine there is a high chance this will fail."
    sleep 1
fi

# Give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/simplehypr.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# Find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    # Give the user an option to not install NVIDIA GPU driver
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install NVIDIA GPU driver? (y,n) ' INSTNVIDIA
    if [[ $INSTNVIDIA == "Y" || $INSTNVIDIA == "y" ]]; then
        ISNVIDIA=true
    else
        ISNVIDIA=false
    fi
else
    ISNVIDIA=false
fi

# Syncing pacman and updating packages
echo -en "$CNT - Syncing pacman and updating packages."
sudo pacman -Syu --noconfirm &>>$INSTLOG &
show_progress $!
echo -e "\e[1A\e[K$COK - pacman and packages updated."

# Check for AUR manager
if [ ! -f /sbin/paru ]; then
    echo -en "$CNT - Configuring Paru."
    git clone https://aur.archlinux.org/paru.git &>>$INSTLOG
    cd paru
    makepkg -si --noconfirm &>>../$INSTLOG &
    show_progress $!
    if [ -f /sbin/paru ]; then
        echo -e "\e[1A\e[K$COK - paru configured"
        cd ..

        # Update the Paru database
        echo -en "$CNT - Updating Paru."
        paru -Syy --noconfirm &>>$INSTLOG &
        show_progress $!
        echo -e "\e[1A\e[K$COK - paru updated."
    else
        # If this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - paru install failed, please check the install.log"
        exit
    fi
fi

# Setup Nvidia if it was found
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
    for SOFTWR in ${nvidia_stage[@]}; do
        install_software $SOFTWR
    done

    # Update config
    sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
    echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $INSTLOG
fi

# Install the correct hyprland version
echo -e "$CNT - Installing Hyprland, this may take a while..."
if [[ "$ISNVIDIA" == true ]]; then
    #check for hyprland and remove it so the -nvidia package can be installed
    if paru -Q hyprland &>> /dev/null ; then
        paru -R --noconfirm hyprland &>> $INSTLOG &
    fi
    install_software hyprland-nvidia
else
    install_software hyprland
fi

# Install packages
echo -e "$CNT - Installing packages, this may take a while..."
for SOFTWR in ${pkgs[@]}; do
    install_software $SOFTWR
done

echo -e "$CNT - Copying config files..."
# Check for existing config folders and backup
for DIR in hypr ghostty zsh btop
do
    DIRPATH=~/.config/$DIR
    if [ -d "$DIRPATH" ]; then
        echo -e "$CAT - Config for $DIR located, backing up."
        mv $DIRPATH $DIRPATH-backup &>> $INSTLOG
        echo -e "$COK - Backed up $DIR to $DIRPATH-back."
    fi

    # Make new empty folders
    mkdir -p $DIRPATH &>> $INSTLOG
    cp -ra configs/$DIR/. $DIRPATH/ &>> $INSTLOG
done

# Add the Nvidia env file to the config (if needed)
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "\nsource = ~/.config/hypr/configs/env_nvidia.conf" >> ~/.config/hypr/configs/env.conf
fi

# Coping .desktops files to hide some unused applications
APPSDIR=~/.local/share/applications
if ! [ -d "$APPSDIR" ]; then
    mkdir -p $APPSDIR &>> $INSTLOG
fi
cp -r configs/desktops/* $APPSDIR &>> $INSTLOG

# Coping greetd config
cp configs/greetd.toml /etc/greetd/config.toml &>> $INSTLOG

# Coping polkit gnome service file
cp configs/polkit-gnome.service /usr/lib/systemd/user/ &>> $INSTLOG

# Coping starship config
cp configs/starship.toml ~/.config/ &>> $INSTLOG

# Coping lessfilter config
cp configs/.lessfilter ~/ &>> $INSTLOG

# Coping wallpaper
cp configs/wallpaper.jpg ~/Pictures/ &>> $INSTLOG

# Remove not uwsm wayland session
sudo rm /usr/share/wayland-sessions/hyprland.desktop &>> $INSTLOG

# Setup ZSH
echo -e "$CNT - Setting up ZSH (will prompt your password) ..."
cp configs/.zshenv ~/.zshenv &>> $INSTLOG
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep &>> $INSTLOG &
show_progress $!
chsh -s $(which zsh)

# Setup the first look and feel preferences
# gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
# gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
# gsettings set org.gnome.desktop.interface icon-theme "Tela"
# gsettings set org.nemo.desktop show-desktop-icons false
# gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
# cp configs/user-dirs.dirs ~/.config/user-dirs.dirs

echo -e "$CNT - Setting up cursor theme..."
for COLOR in Black Dark Light
do
    wget https://github.com/ful1e5/BreezeX_Cursor/releases/latest/download/BreezeX-$COLOR.tar.xz &>> $INSTLOG
    tar -xf BreezeX-$COLOR.tar.xz &>> $INSTLOG
    hyprcursor-util -x BreezeX-$COLOR &>> $INSTLOG
    hyprcursor-util -c extracted_BreezeX-$COLOR &>> $INSTLOG
    mv BreezeX-$COLOR ~/.local/share/icons/BreezeX-$COLOR &>> $INSTLOG
    mv theme_Extracted\ Theme ~/.local/share/icons/BreezeX-$COLOR-Hyprcursor &>> $INSTLOG
done

# Start the bluetooth service
# echo -e "$CNT - Starting the Bluetooth Service..."
# sudo systemctl enable --now bluetooth.service &>> $INSTLOG
# sleep 2

# Enable weekly pacman cache clean service
echo -e "$CNT - Enabling weekly Pacman cache clean service..."
sudo systemctl enable paccache.timer &>>$INSTLOG
sleep 2

# Enable greetd service
echo -e "$CNT - Enabling greetd service..."
sudo systemctl enable greetd.service &>>$INSTLOG
sleep 2

# Enable polkit gnome service
echo -e "$CNT - Enabling polkit gnome service..."
systemctl --user enable polkit-gnome.service &>>$INSTLOG
sleep 2

# Enable hypridle service
echo -e "$CNT - Enabling hypridle service..."
systemctl --user enable --now hypridle.service &>>$INSTLOG
sleep 2

# Enable hyprpaper service
echo -e "$CNT - Enabling hyprpaper service..."
systemctl --user enable --now hyprpaper.service &>>$INSTLOG
sleep 2

# Script is done
echo -e "$CNT - Script had completed!
(you can safely delete the Simple-Hypr folder)
Please type 'reboot' at the prompt and hit Enter when ready."
exit
