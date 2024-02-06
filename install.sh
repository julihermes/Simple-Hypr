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

# Define the software that would be installed
# Need some prep work
prep_stage=(
    qt5-svg
    qt5-quickcontrols2
    qt5-graphicaleffects
    gtk3
    polkit-gnome
    python-requests
    pacman-contrib
)

# Software for nvidia GPU only
nvidia_stage=(
    linux-headers
    nvidia-dkms
    nvidia-settings
    libva
    libva-nvidia-driver-git
)

# The main packages
main_stage=(
    xdg-desktop-portal-hyprland
    kitty
    waybar
    swaybg
    swaync
    swaylock-effects
    rofi
    swappy
    grim
    slurp
    wf-recorder
    pamixer
    pavucontrol
    brightnessctl
    bluez
    bluez-utils
    blueman
    network-manager-applet
    file-roller
    nemo
    nemo-fileroller
    gnome-themes-extra
    arc-gtk-theme
    ttf-ubuntu-font-family
    ttf-sourcecodepro-nerd
    noto-fonts-emoji
    btop
    starship
    python-pywal
    sddm
    bash-completion
    neofetch
    firefox
)

# Personal packages
personal_stage=(
    keyd
    neovim
    lsd
    lazygit
    gnome-calculator
    evince
    image-roll
    totem
    gst-libav
    gnome-disk-utility
    enpass-bin
    google-chrome
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
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # No package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # Test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
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
    sudo touch /tmp/hyprv.tmp
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

# Update pacman
echo -en "$CNT - Updating pacman."
sudo pacman -Syy &>> $INSTLOG &
show_progress $!
echo -e "\e[1A\e[K$COK - pacman updated."

# Update applications
echo -en "$CNT - Upgrading applications."
sudo pacman -Suy &>> $INSTLOG &
show_progress $!
echo -e "\e[1A\e[K$COK - applications updated."

# Check for package manager
if [ ! -f /sbin/yay ]; then
    echo -en "$CNT - Configuring yay."
    git clone https://aur.archlinux.org/yay.git &>> $INSTLOG
    cd yay
    makepkg -si --noconfirm &>> ../$INSTLOG &
    show_progress $!
    if [ -f /sbin/yay ]; then
        echo -e "\e[1A\e[K$COK - yay configured"
        cd ..

        # Update the yay database
        echo -en "$CNT - Updating yay."
        yay -Suy --noconfirm &>> $INSTLOG &
        show_progress $!
        echo -e "\e[1A\e[K$COK - yay updated."
    else
        # If this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
        exit
    fi
fi

# Prep Stage - Bunch of needed items
echo -e "$CNT - Prep Stage - Installing needed components, this may take a while..."
for SOFTWR in ${prep_stage[@]}; do
    install_software $SOFTWR
done

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
    if yay -Q hyprland &>> /dev/null ; then
        yay -R --noconfirm hyprland &>> $INSTLOG &
    fi
    install_software hyprland-nvidia
else
    install_software hyprland
fi

# Main components
echo -e "$CNT - Installing main components, this may take a while..."
for SOFTWR in ${main_stage[@]}; do
    install_software $SOFTWR
done

echo -en "$CNT - Instaling icon theme."
git clone https://github.com/vinceliuice/Tela-icon-theme.git &>> $INSTLOG &
show_progress $!
cd Tela-icon-theme
./install.sh &>> ../$INSTLOG
if [ -d "$HOME/.local/share/icons/Tela" ]; then
    echo -e "\e[1A\e[K$COK - icon theme configured"
else
    echo -e "\e[1A\e[K$CER - icon theme install failed, please check the install.log"
fi
cd ..

# Start the bluetooth service
echo -e "$CNT - Starting the Bluetooth Service..."
sudo systemctl enable --now bluetooth.service &>> $INSTLOG
sleep 2

# Enable the sddm login manager service
echo -e "$CNT - Enabling the SDDM Service..."
sudo systemctl enable sddm &>> $INSTLOG
sleep 2

# Clean out other portals
echo -e "$CNT - Cleaning out conflicting xdg portals..."
yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>> $INSTLOG

# Ask if want to install personal pacakges
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the personal packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    # Personal components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${personal_stage[@]}; do
        install_software $SOFTWR
    done
fi

# Setup each appliaction
# Check for existing config folders and backup
for DIR in hypr btop kitty rofi swaylock swaync waybar
do
    DIRPATH=~/.config/$DIR
    if [ -d "$DIRPATH" ]; then
        echo -e "$CAT - Config for $DIR located, backing up."
        mv $DIRPATH $DIRPATH-back &>> $INSTLOG
        echo -e "$COK - Backed up $DIR to $DIRPATH-back."
    fi

    # Make new empty folders
    mkdir -p $DIRPATH &>> $INSTLOG
done

echo -e "$CNT - Copying config files..."
cp -r configs/hypr/* ~/.config/hypr/
cp -r configs/btop/* ~/.config/btop/
cp -r configs/kitty/* ~/.config/kitty/
cp -r configs/rofi/* ~/.config/rofi/
cp -r configs/swaylock/* ~/.config/swaylock/
cp -r configs/swaync/* ~/.config/swaync/
cp -r configs/waybar/* ~/.config/waybar/

# Add the Nvidia env file to the config (if needed)
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "\nsource = ~/.config/hypr/configs/env_nvidia.conf" >> ~/.config/hypr/configs/env.conf
fi

# Setup manual fonts
FONTDIR=~/.local/share/fonts
if [ -d "$FONTDIR" ]; then
    echo -e "$COK - $FONTDIR found"
else
    echo -e "$CWR - $FONTDIR NOT found, creating..."
    mkdir -p $FONTDIR
fi
cp -r configs/rofi/powermenu/fonts/* $FONTDIR
fc-cache

# Coping .desktops files to hide some unused applications
APPSDIR=~/.local/share/applications
if [ -d "$APPSDIR" ]; then
    echo -e "$COK - $APPSDIR found"
else
    echo -e "$CWR - $APPSDIR NOT found, creating..."
    mkdir -p $APPSDIR
fi
cp -r configs/desktops/* $APPSDIR

# Setup "Set as background" nemo action
NEMOACDIR=~/.local/share/nemo/actions
if [ -d "$NEMOACDIR" ]; then
    echo -e "$COK - $NEMOACDIR found"
else
    echo -e "$CWR - $NEMOACDIR NOT found, creating..."
    mkdir -p $NEMOACDIR
fi
cp configs/set_as_background.nemo_action $NEMOACDIR/
sleep 2

# Copy the SDDM theme
echo -e "$CNT - Setting up the login screen."
sudo cp -R configs/sdt /usr/share/sddm/themes/
sudo chown -R $USER:$USER /usr/share/sddm/themes/sdt
sudo mkdir /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sdt" | sudo tee -a /etc/sddm.conf.d/10-theme.conf &>> $INSTLOG
WLDIR=/usr/share/wayland-sessions
if [ -d "$WLDIR" ]; then
    echo -e "$COK - $WLDIR found"
else
    echo -e "$CWR - $WLDIR NOT found, creating..."
    sudo mkdir $WLDIR
fi
# Stage the .desktop file
sudo mv ~/.local/share/applications/hyprland.desktop /usr/share/wayland-sessions/

# Setup the first look and feel preferences
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Tela"
gsettings set org.nemo.desktop show-desktop-icons false
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
cp configs/user-dirs.dirs ~/.config/user-dirs.dirs

# Install the starship shell
echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
echo -e "$CNT - copying starship config file to ~/.config ..."
cp configs/starship.toml ~/.config/

# Copy .bachrc
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy .bachrc file?
(not recommended if you have changed the personal package list a lot) (y,n) ' BASHRC
if [[ $BACHRC == "Y" || $BASHRC == "y" ]]; then
    cp -f configs/.bashrc ~/.bashrc
fi

# Enable and congif keyd if installed
if [ -x "$(command -v keyd)" ]; then
    sudo cp configs/keyd.config /etc/keyd/default.conf
    sudo systemctl enable keyd
fi

# Script is done
echo -e "$CNT - Script had completed!"
if [[ "$ISNVIDIA" == true ]]; then
    echo -e "$CAT - Since we attempted to setup an Nvidia GPU the script will now end and you should reboot.
    Please type 'reboot' at the prompt and hit Enter when ready."
    exit
fi

read -rep $'[\e[1;33mACTION\e[0m] - Would you like to start Hyprland now? (y,n) ' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec sudo systemctl start sddm &>> $INSTLOG
else
    exit
fi
