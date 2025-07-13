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

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log file setup
LOG_FILE="install-$(date +%Y%m%d-%H%M%S).log"

# Spinner animation for visual feedback
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to print colored output with logging
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING: $1"
}

print_skip() {
    echo -e "${CYAN}[SKIP]${NC} $1"
    log_message "SKIP: $1"
}

# Function to start spinner
start_spinner() {
    local message="$1"
    (
        local i=0
        while true; do
            printf "\r${YELLOW}${SPINNER_CHARS:$i:1}${NC} $message"
            i=$(( (i + 1) % ${#SPINNER_CHARS} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

# Function to stop spinner
stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        printf "\r"
        SPINNER_PID=""
    fi
}

# Find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    ISNVIDIA=true
else
    ISNVIDIA=false
fi

# Function to setup logging
setup_logging() {
    echo "=====================================" | tee "$LOG_FILE"
    echo "Started: $(date)" | tee -a "$LOG_FILE"
    echo "=====================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Function to update system before installation
update_system() {
    start_spinner "Updating system packages..."

    if sudo pacman -Syu --noconfirm &>> $LOG_FILE; then
        stop_spinner
        print_success "System updated successfully"
    else
        stop_spinner
        print_warning "System update failed, continuing with installation..."
    fi
}

# Function to install paru
install_paru() {
    if ! command -v paru &> /dev/null; then
        start_spinner "Configuring Paru..."
        git clone https://aur.archlinux.org/paru.git &>>$LOG_FILE
        cd paru
        makepkg -si --noconfirm &>>$LOG_FILE

        if command -v paru &> /dev/null; then
            stop_spinner
            print_success "Paru installed successfully."
            cd ..
        else
            # If this is hit then a package is missing, exit to review log
            print_error "paru install failed, please check the install.log."
            exit
        fi
    fi
}

# Function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if paru -Q $1 &>>/dev/null; then
        print_skip "$1 is already installed."
    else
        # Create a temporary file to capture paru output
        local temp_log=$(mktemp)

        # Start spinner for installation
        start_spinner "Installing $1..."

        # No package found so installing
        paru -S --noconfirm $1 > "$temp_log"

        stop_spinner

        # Test to make sure package installed
        if paru -Q $1 &>>/dev/null; then
            print_success "$1 installed successfully."

            # Log the installation details
            echo "=== Installation details for $1 ===" >> "$LOG_FILE"
            cat "$temp_log" >> "$LOG_FILE"
            echo "=== End of installation for $1 ===" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"
        else
            print_error "Failed to install $1."

            # Log the error details
            echo "=== ERROR: Installation failed for $1 ===" >> "$LOG_FILE"
            cat "$temp_log" >> "$LOG_FILE"
            echo "=== End of error for $1 ===" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"
        fi

        # Clean up temp file
        rm -f "$temp_log"
    fi
}

# Function that copy configs files
copy_configs() {
    start_spinner "Copying config files..."

    # Check for existing config folders and backup
    for DIR in hypr ghostty zsh btop
    do
        DIRPATH=~/.config/$DIR
        if [ -d "$DIRPATH" ]; then
            mv $DIRPATH $DIRPATH-backup &>> $LOG_FILE
        fi

        # Make new empty folders
        mkdir -p $DIRPATH &>> $LOG_FILE
        cp -ra configs/$DIR/. $DIRPATH/ &>> $LOG_FILE
    done

    # Add the Nvidia env file to the config (if needed)
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "\nsource = ~/.config/hypr/configs/env_nvidia.conf" >> ~/.config/hypr/configs/env.conf
    fi

    # Coping .desktops files to hide some unused applications
    APPSDIR=~/.local/share/applications
    if ! [ -d "$APPSDIR" ]; then
        mkdir -p $APPSDIR &>> $LOG_FILE
    fi
    cp -r configs/desktops/* $APPSDIR &>> $LOG_FILE

    # Creating home directories
    mkdir ~/Downloads
    mkdir ~/Templates
    mkdir ~/Public
    mkdir ~/Documents
    mkdir ~/Music
    mkdir ~/Pictures
    mkdir ~/Videos

    # Coping greetd config
    sudo cp -f configs/greetd.toml /etc/greetd/config.toml &>> $LOG_FILE

    # Coping polkit gnome service file
    sudo cp configs/polkit-gnome.service /usr/lib/systemd/user/ &>> $LOG_FILE

    # Coping starship config
    cp configs/starship.toml ~/.config/ &>> $LOG_FILE

    # Coping user-dirs config
    cp -f configs/user-dirs.dirs ~/.config/ &>> $LOG_FILE

    # Coping lessfilter config
    cp configs/.lessfilter ~/ &>> $LOG_FILE

    # Coping wallpaper
    cp configs/wallpaper.jpg ~/Pictures/ &>> $LOG_FILE

    stop_spinner
    print_success "Configs copied successfully."
}

# Function that setting up ZSH
set_zsh() {
    start_spinner "Setting up ZSH..."

    cp configs/.zshenv ~/.zshenv &>> $LOG_FILE
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep &>> $LOG_FILE
    chsh -s $(which zsh)

    stop_spinner
    print_success "ZSH setted up successfully."
}

# Function that setting up cursor theme
set_cursor() {
    start_spinner "Setting up cursor theme..."

    if ! [ -d "~/.local/share/icons" ]; then
        mkdir -p ~/.local/share/icons &>> $LOG_FILE
    fi
    for COLOR in Black Dark Light
    do
        wget https://github.com/ful1e5/BreezeX_Cursor/releases/latest/download/BreezeX-$COLOR.tar.xz &>> $LOG_FILE
        tar -xf BreezeX-$COLOR.tar.xz &>> $LOG_FILE
        hyprcursor-util -x BreezeX-$COLOR &>> $LOG_FILE
        hyprcursor-util -c extracted_BreezeX-$COLOR &>> $LOG_FILE
        mv BreezeX-$COLOR ~/.local/share/icons/BreezeX-$COLOR &>> $LOG_FILE
        cp -R theme_Extracted\ Theme ~/.local/share/icons/BreezeX-$COLOR-Hyprcursor &>> $LOG_FILE
        rm -Rf theme_Extracted\ Theme &>> $LOG_FILE
    done

    stop_spinner
    print_success "Cursor theme setted up successfully."
}

# Function that enable services
enable_services() {
    start_spinner "Enabling services..."

    sudo systemctl enable paccache.timer &>>$LOG_FILE

    sudo systemctl enable greetd.service &>>$LOG_FILE

    systemctl --user enable polkit-gnome.service &>>$LOG_FILE

    systemctl --user enable --now hypridle.service &>>$LOG_FILE

    systemctl --user enable --now hyprpaper.service &>>$LOG_FILE

    # sudo systemctl enable --now bluetooth.service &>> $LOG_FILE

    stop_spinner
    print_success "Services enabled successfully."
}

main() {
    # Set some expectations for the user
    print_status "You are about to execute a script that would attempt to setup Hyprland.
    This script was designed for a fresh minimal installation of Arch Linux with git installed,
    if your scenario is different from this, make sure you know what you are doing."
    sleep 3

    # Give the user an option to exit out
    read -rep $'Would you like to continue with the install (y,n) ' CONTINST
    if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
        sudo touch /tmp/simplehypr.tmp
    else
        print_skip "This script will now exit, no changes were made to your system."
        exit
    fi

    print_status "Getting started (you will be asked for your password a few times during the process)."
    sleep 3

    update_system

    install_paru

    # Setup Nvidia if it was found
    if [[ "$ISNVIDIA" == true ]]; then
    echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
    for SOFTWR in ${nvidia_stage[@]}; do
        install_software $SOFTWR
    done

    # Update config
    sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
    echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $LOG_FILE
    fi

    # Install the correct hyprland version
    print_status "Installing Hyprland, this may take a while..."
    if [[ "$ISNVIDIA" == true ]]; then
        install_software hyprland-nvidia
    else
        install_software hyprland
    fi

    # Install packages
    print_status "Installing packages, this may take a while..."
    for SOFTWR in ${pkgs[@]}; do
        install_software $SOFTWR
    done

    copy_configs

    set_zsh

    set_cursor

    # Setup the first look and feel preferences
    # gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    # gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
    # gsettings set org.gnome.desktop.interface icon-theme "Tela"
    # gsettings set org.nemo.desktop show-desktop-icons false
    # gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
    # cp configs/user-dirs.dirs ~/.config/user-dirs.dirs

    enable_services

    # Script is done
    echo -e "$CNT - Script had completed!
    (you can safely delete the Simple-Hypr folder)
    Please type 'reboot' at the prompt and hit Enter when ready."
    exit
}

main
