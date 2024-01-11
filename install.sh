#!/bin/bash

clear

cat <<"EOF"
   _____ ______  _______  __    ______   __  ____  ______  ____
  / ___//  _/  |/  / __ \/ /   / ____/  / / / /\ \/ / __ \/ __ \
  \__ \ / // /|_/ / /_/ / /   / __/    / /_/ /  \  / /_/ / /_/ /
 ___/ // // /  / / ____/ /___/ /___   / __  /   / / ____/ _, _/
/____/___/_/  /_/_/   /_____/_____/  /_/ /_/   /_/_/   /_/ |_|

Version 1.0
EOF

# Define the software that would be installed
# Need some prep work
prep_stage=(
    qt5-wayland
    qt5ct
    qt6-wayland
    qt6ct
    qt5-svg
    qt5-quickcontrols2
    qt5-graphicaleffects
    gtk3
    polkit-gnome
    pipewire
    wireplumber
    jq
    wl-clipboard
    cliphist
    python-requests
    pacman-contrib
    linux-headers
)

#software for intel GPU only
intel_stage=(
    xf86-video-intel
    mesa
    lib32-mesa
    lib32-vulkan-intel
    vulkan-intel
)

#software for nvidia GPU only
nvidia_stage=(
    nvidia-dkms
    nvidia-settings
    libva
    libva-nvidia-driver-git
)

#software for amd GPU only
amd_stage=(
    xf86-video-amdgpu
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    libva-mesa-driver
    lib32-libva-mesa-driver
    mesa-vdpau
    lib32-mesa-vdpau
)

#the main packages
main_stage=(
    kitty
    mako
    waybar
    swww
    swaylock-effects
    wofi
    wlogout
    xdg-desktop-portal-hyprland
    swappy
    grim
    slurp
    nemo
    btop
    pamixer
    pavucontrol
    brightnessctl
    bluez
    bluez-utils
    blueman
    network-manager-applet
    gvfs
    thunar-archive-plugin
    file-roller
    starship
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    nwg-look-bin
    sddm
)

#personal packages
personal_stage=(
    thunderbird
)

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

# function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}


read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST

echo $'[\e[1;33mACTION\e[0m] - Would you like to install GPU drivers? (leave blank if you dont)
    1) Intel
    2) Nvidia
    3) AMD'

ISINTEL=false
ISNVIDIA=false
ISAMD=false

read GRAPHICSCARD
case $GRAPHICSCARD in
1)
    ISINTEL=true;;
2)
    ISNVIDIA=true;;
3)
    ISAMD=true;;
esac

#### Check for package manager ####
if [ ! -f /sbin/yay ]; then  
    echo -en "$CNT - Configuering yay."
    git clone https://aur.archlinux.org/yay.git &>> $INSTLOG
    cd yay
    makepkg -si --noconfirm &>> ../$INSTLOG &
    show_progress $!
    if [ -f /sbin/yay ]; then
        echo -e "\e[1A\e[K$COK - yay configured"
        cd ..

        # update the yay database
        echo -en "$CNT - Updating yay."
        yay -Suy --noconfirm &>> $INSTLOG &
        show_progress $!
        echo -e "\e[1A\e[K$COK - yay updated."
    else
        # if this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
        exit
    fi
fi

### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

    # Prep Stage - Bunch of needed items
    echo -e "$CNT - Prep Stage - Installing needed components, this may take a while..."
    for SOFTWR in ${prep_stage[@]}; do
        install_software $SOFTWR 
    done

    # Setup Intel if it was found
    if [[ "$ISINTEL" == true ]]; then
        echo -e "$CNT - Intel GPU support setup stage, this may take a while..."
        for SOFTWR in ${intel_stage[@]}; do
            install_software $SOFTWR
        done
    fi

    # Setup Nvidia if it was found
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
        for SOFTWR in ${nvidia_stage[@]}; do
            install_software $SOFTWR
        done

        # update config
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
        echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $INSTLOG
    fi

    # Setup AMD if it was found
    if [[ "$ISAMD" == true ]]; then
        echo -e "$CNT - AMD GPU support setup stage, this may take a while..."
        for SOFTWR in ${amd_stage[@]}; do
            install_software $SOFTWR
        done
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

    # main components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${main_stage[@]}; do
        install_software $SOFTWR 
    done

    # personal components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${personal_stage[@]}; do
        install_software $SOFTWR 
    done

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
fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Copying config files..."

    # copy the HyprV directory
    #cp -R HyprV ~/.config/

    #set the measuring unit
    echo -e "$CNT - Attempring to set mesuring unit..."
    if locale -a | grep -q ^en_US; then
        echo -e "$COK - Setting mesuring system to imperial..."
        ln -sf ~/.config/HyprV/waybar/conf/mesu-imp.jsonc ~/.config/HyprV/waybar/conf/mesu.jsonc
        sed -i 's/SET_MESU=""/SET_MESU="I"/' ~/.config/HyprV/hyprv.conf
    else
        echo -e "$COK - Setting mesuring system to metric..."
        sed -i 's/SET_MESU=""/SET_MESU="M"/' ~/.config/HyprV/hyprv.conf
        ln -sf ~/.config/HyprV/waybar/conf/mesu-met.jsonc ~/.config/HyprV/waybar/conf/mesu.jsonc
    fi

    # Setup each appliaction
    # check for existing config folders and backup 
    for DIR in hypr kitty mako swaylock waybar wlogout wofi
    do
        DIRPATH=~/.config/$DIR
        if [ -d "$DIRPATH" ]; then 
            echo -e "$CAT - Config for $DIR located, backing up."
            mv $DIRPATH $DIRPATH-back &>> $INSTLOG
            echo -e "$COK - Backed up $DIR to $DIRPATH-back."
        fi

        # make new empty folders
        mkdir -p $DIRPATH &>> $INSTLOG
    done

    # link up the config files
    echo -e "$CNT - Setting up the new config..." 
    cp HyprV/hypr/* ~/.config/hypr/
    cp HyprV/kitty/kitty.conf ~/.config/kitty/kitty.conf
    cp HyprV/mako/conf/config-dark ~/.config/mako/config
    cp HyprV/swaylock/config ~/.config/swaylock/config
    cp HyprV/waybar/conf/v4-config.jsonc ~/.config/waybar/config.jsonc
    cp HyprV/waybar/style/v4-style-dark.css ~/.config/waybar/style.css
    cp HyprV/wlogout/layout ~/.config/wlogout/layout
    cp HyprV/wofi/config ~/.config/wofi/config
    cp HyprV/wofi/style/v4-style-dark.css ~/.config/wofi/style.css


    # add the Nvidia env file to the config (if needed)
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "\nsource = ~/.config/hypr/env_var_nvidia.conf" >> ~/.config/hypr/hyprland.conf
    fi

    # Copy the SDDM theme
    echo -e "$CNT - Setting up the login screen."
    sudo cp -R Extras/sdt /usr/share/sddm/themes/
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

    # stage the .desktop file
    sudo cp Extras/hyprland.desktop /usr/share/wayland-sessions/

    # setup the first look and feel as dark
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    cp -f HyprV/backgrounds/v4-background-dark.jpg /usr/share/sddm/themes/sdt/wallpaper.jpg
fi

### Install the starship shell ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to activate the starship shell? (y,n) ' STAR
if [[ $STAR == "Y" || $STAR == "y" ]]; then
    # install the starship shell
    echo -e "$CNT - Hansen Crusher, Engage!"
    echo -e "$CNT - Updating .bashrc..."
    echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
    echo -e "$CNT - copying starship config file to ~/.config ..."
    cp Extras/starship.toml ~/.config/
fi

### Script is done ###
echo -e "$CNT - Script had completed!"
if [[ "$ISNVIDIA" == true ||  "$ISINTEL" == true || "$ISAMD" == true]]; then 
    echo -e "$CAT - Since we attempted to setup an GPU the script will now end and you should reboot.
    Please type 'reboot' at the prompt and hit Enter when ready."
    exit
fi

read -rep $'[\e[1;33mACTION\e[0m] - Would you like to start Hyprland now? (y,n) ' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec sudo systemctl start sddm &>> $INSTLOG
else
    exit
fi
