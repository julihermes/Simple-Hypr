#!/bin/bash

# Software for nvidia GPU only
# nvidia_stage=(
#     linux-headers
#     nvidia-dkms
#     nvidia-settings
#     libva
#     libva-nvidia-driver-git
# )

# The packages
pkgs=(
    pacman-contrib
    greetd
    greetd-tuigreet
    uwsm
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
    xcur2png


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

# Log file setup
LOG_FILE="install-$(date +%Y%m%d-%H%M%S).log"

# Function to print colored output with logging
print_msg() {
    case $2 in
        -i)
            gum log -l info "$1" --level.background="12" --level.foreground="0"
            gum log -l info "$1" -t dateTime -o "$LOG_FILE"
            ;;

        -w)
            gum log -l warn "$1" --level.background="11" --level.foreground="0"
            gum log -l warn "$1" -t dateTime -o "$LOG_FILE"
            ;;

        -e)
            gum log -l error "$1" --level.background="9" --level.foreground="0"
            gum log -l error "$1" -t dateTime -o "$LOG_FILE"
            ;;

        -f)
            gum log -l fatal "$1" --level.background="13" --level.foreground="0"
            gum log -l fatal "Check $LOG_FILE file for details." --level.background="13" --level.foreground="0"
            gum log -l fatal "$1" -t dateTime -o "$LOG_FILE"
            ;;

        -s)
            gum log -f '%s %s' "$(tput setab 10 setaf 0)SUCCESS$(tput sgr0)" "$1"
            gum log "SUCCESS $1" -t dateTime -o "$LOG_FILE"
            ;;

        -k)
            gum log -f '%s %s' "$(tput setab 7 setaf 0)SKIP$(tput sgr0)" "$1"
            gum log "SKIP $1" -t dateTime -o "$LOG_FILE"
            ;;

        *)
            gum log "$1"
            gum log "$1" -t dateTime -o "$LOG_FILE"
            ;;
    esac
}

# Find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    ISNVIDIA=true
else
    ISNVIDIA=false
fi

# Function to setup log file and instal gum
initial_setup() {
    echo "============ SIMPLE HYPR ============" >> $LOG_FILE
    echo "Version: 0.2" >> $LOG_FILE
    echo "Started: $(date)" >> $LOG_FILE
    echo "=====================================" >> $LOG_FILE
    echo "" >> $LOG_FILE

    echo "$(date '+%Y-%m-%d %H:%M:%S') Setting up gum." >> "$LOG_FILE"
    printf "Initializing...\n"

    if sudo pacman -S gum --noconfirm &>> $LOG_FILE; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') gum installed successfully." >> "$LOG_FILE"
        clear
    else
        echo "Impossible to continue, check $LOG_FILE file for details."
        echo "$(date '+%Y-%m-%d %H:%M:%S') Error to install gum." >> "$LOG_FILE"
        exit
    fi
}

print_banner() {
    gum style --border double --align center --margin "1 2" ' ███████╗██╗███╗   ███╗██████╗ ██╗     ███████╗    ██╗  ██╗██╗   ██╗██████╗ ██████╗  ' ' ██╔════╝██║████╗ ████║██╔══██╗██║     ██╔════╝    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗ ' ' ███████╗██║██╔████╔██║██████╔╝██║     █████╗      ███████║ ╚████╔╝ ██████╔╝██████╔╝ ' ' ╚════██║██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝      ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗ ' ' ███████║██║██║ ╚═╝ ██║██║     ███████╗███████╗    ██║  ██║   ██║   ██║     ██║  ██║ ' ' ╚══════╝╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝ '
}

# Function to install yay and update system parkages
install_yay() {
    if ! command -v yay &> /dev/null; then
        gum spin --spinner line --title "Installing yay..." -- git clone https://aur.archlinux.org/yay-bin.git >> $LOG_FILE
        cd yay-bin
        gum spin --spinner line --title "Installing yay..." -- makepkg -si --noconfirm >> $LOG_FILE

        if command -v yay &> /dev/null; then
            print_msg "yay installed successfully." -s
            cd ..
            gum spin --spinner line --title "Updating system packages..." -- yay --save --answerdiff None --answerclean None --removemake --noconfirm >> $LOG_FILE
            print_msg "System packages updated successfully." -s
        else
            print_msg "yay install failed. Impossible to continue." -f
        fi
    fi
}

# Function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if yay -Q $1 &>>/dev/null; then
        print_msg "$1 is already installed." -k
    else
        gum spin --spinner line --title "Installing $1..." -- yay -S --noconfirm $1 >> $LOG_FILE

        # Test to make sure package installed
        if yay -Q $1 &>>/dev/null; then
            print_msg "$1 installed successfully." -s
        else
            print_msg "Failed to install $1." -e
        fi
    fi
}

# Function that copy configs files
copy_configs() {
    # Check for existing config folders and backup
    for DIR in hypr ghostty zsh btop
    do
        DIRPATH=~/.config/$DIR
        if [ -d "$DIRPATH" ]; then
            mv $DIRPATH $DIRPATH-backup
        fi

        # Make new empty folders
        mkdir -p $DIRPATH
        cp -ra configs/$DIR/. $DIRPATH/
    done

    # Add the Nvidia env file to the config (if needed)
    # if [[ "$ISNVIDIA" == true ]]; then
    #     echo -e "\nsource = ~/.config/hypr/configs/env_nvidia.conf" >> ~/.config/hypr/configs/env.conf
    # fi

    # Coping .desktops files to hide some unused applications
    APPSDIR=~/.local/share/applications
    if ! [ -d "$APPSDIR" ]; then
        mkdir -p $APPSDIR
    fi
    cp -r configs/desktops/* $APPSDIR

    # Creating home directories
    mkdir ~/Downloads
    mkdir ~/Templates
    mkdir ~/Public
    mkdir ~/Documents
    mkdir ~/Music
    mkdir ~/Pictures
    mkdir ~/Videos

    # Coping greetd config
    sudo cp -f configs/greetd.toml /etc/greetd/config.toml

    # Coping polkit gnome service file
    sudo cp configs/polkit-gnome.service /usr/lib/systemd/user/

    # Coping starship config
    cp configs/starship.toml ~/.config/

    # Coping user-dirs config
    cp -f configs/user-dirs.dirs ~/.config/

    # Coping lessfilter config
    cp configs/.lessfilter ~/

    # Coping wallpaper
    cp configs/wallpaper.jpg ~/Pictures/
}

# Function that setting up ZSH
set_zsh() {
    cp configs/.zshenv ~/.zshenv
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep
    chsh -s $(which zsh)
}

# Function that setting up cursor theme
set_cursor() {
    if ! [ -d "~/.local/share/icons" ]; then
        mkdir -p ~/.local/share/icons
    fi
    for COLOR in Black Dark Light
    do
        wget https://github.com/ful1e5/BreezeX_Cursor/releases/latest/download/BreezeX-$COLOR.tar.xz
        tar -xf BreezeX-$COLOR.tar.xz
        hyprcursor-util -x BreezeX-$COLOR
        hyprcursor-util -c extracted_BreezeX-$COLOR
        mv BreezeX-$COLOR ~/.local/share/icons/BreezeX-$COLOR
        cp -R theme_Extracted\ Theme ~/.local/share/icons/BreezeX-$COLOR-Hyprcursor
        rm -Rf theme_Extracted\ Theme
    done
}

# Function that enable services
enable_services() {
    sudo systemctl enable paccache.timer

    sudo systemctl enable greetd.service

    systemctl --user enable polkit-gnome.service

    systemctl --user enable --now hypridle.service

    systemctl --user enable --now hyprpaper.service

    # sudo systemctl enable --now bluetooth.service
}

main() {
    initial_setup

    print_banner

    # Set some expectations for the user
    print_msg "This script was designed for a fresh minimal installation of Arch Linux with git installed." -w
    print_msg "If your scenario is different from this, make sure you know what you are doing." -w
    # Give the user an option to exit out
    gum confirm "Would you like to continue?"

    install_yay

    # # Setup Nvidia if it was found
    # if [[ "$ISNVIDIA" == true ]]; then
    # echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
    # for SOFTWR in ${nvidia_stage[@]}; do
    #     install_software $SOFTWR
    # done

    # # Update config
    # sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    # sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
    # echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $LOG_FILE
    # fi

    # Install the correct hyprland version
    print_msg "Installing Hyprland, this may take a while..." -i
    if [[ "$ISNVIDIA" == true ]]; then
        install_software hyprland-nvidia
    else
        install_software hyprland
    fi

    # Install packages
    print_msg "Installing packages, this may take a while..." -i
    for SOFTWR in ${pkgs[@]}; do
        install_software $SOFTWR
    done

    gum spin --spinner line --title "Copying config files..." -- copy_configs >> $LOG_FILE
    print_msg "Config files copied successfully." -s

    gum spin --spinner line --title "Setting up ZSH..." -- set_zsh >> $LOG_FILE
    print_msg "ZSH setted up successfully." -s

    gum spin --spinner line --title "Setting up cursor theme..." -- set_cursor >> $LOG_FILE
    print_msg "Cursor theme setted up successfully." -s

    # # Setup the first look and feel preferences
    # # gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    # # gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
    # # gsettings set org.gnome.desktop.interface icon-theme "Tela"
    # # gsettings set org.nemo.desktop show-desktop-icons false
    # # gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
    # # cp configs/user-dirs.dirs ~/.config/user-dirs.dirs

    gum spin --spinner line --title "Enabling services..." -- enable_services >> $LOG_FILE
    print_msg "Services enabled successfully." -s

    # Script is done
    print_msg "Script had completed!" -s
    print_msg "You can safely delete the Simple-Hypr folder" -i
    print_msg "Please type 'reboot' at the prompt and hit Enter when ready." -i
    exit
}

main
