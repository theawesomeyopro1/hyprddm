#!/bin/bash

# SDDM Astronaut Theme Selector with YAD GUI
# A script to select and apply themes for SDDM using the sddm-astronaut-theme project.

THEMES_PATH="/usr/share/sddm/themes/sddm-astronaut-theme"
FONTS_PATH="/usr/share/fonts"
METADATA_FILE="$THEMES_PATH/metadata.desktop"
SDDM_CONF="/etc/sddm.conf"
VIRTUAL_KBD_CONF="/etc/sddm.conf.d/virtualkbd.conf"
TEMP_DIR="/tmp/sddm-previews-$USER"
TEMP_SCRIPT="/tmp/install-hyprddm-$USER.sh"

# Enable debug output
set -x

# Function to detect distribution
detect_distribution() {
    if [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/void-release ]; then
        DISTRO="void"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/opensuse-release ] || [ -f /etc/SuSE-release ]; then
        DISTRO="opensuse"
    else
        DISTRO="unknown"
    fi
    echo "Detected distribution: $DISTRO"
}

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    case $DISTRO in
        arch)
            sudo pacman -S --noconfirm --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg yad polkit xorg-xwayland imagemagick curl git
            ;;
        void)
            sudo xbps-install -Sy sddm qt6-svg qt6-virtualkeyboard qt6-multimedia yad polkit xwayland imagemagick curl git
            ;;
        fedora)
            sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia yad polkit xorg-x11-server-Xwayland imagemagick curl git
            ;;
        opensuse)
            sudo zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia yad polkit xorg-x11-server imagemagick curl git
            ;;
        *)
            echo "Unsupported distribution. Please install dependencies manually."
            echo "Required packages: sddm, qt6-svg, qt6-virtualkeyboard, qt6-multimedia, yad, polkit, xwayland, imagemagick, curl, git"
            ;;
    esac
}

# Function to check and install theme files
check_and_install_theme() {
    # Check if the themes directory exists and contains files
    if [ -d "$THEMES_PATH" ] && [ -n "$(ls -A "$THEMES_PATH")" ]; then
        echo "Warning: $THEMES_PATH already exists and contains files."
        echo "This may indicate a previous installation of sddm-astronaut-theme."
        echo "To avoid conflicts, the script will not overwrite the existing files."
        echo "If you want to reinstall, please remove the directory manually with:"
        echo "  sudo rm -rf $THEMES_PATH"
        echo "Then rerun this script."
        exit 1
    fi

    # If the directory is empty or doesn't exist, proceed with installation
    echo "SDDM Astronaut Theme files are missing or directory is empty. Installing from nomadxxxx's fork..."
    sudo mkdir -p /usr/share/sddm/themes
    echo "Cloning repository from https://github.com/nomadxxxx/hyprddm.git to $THEMES_PATH..."
    sudo git clone -b master --depth 1 --progress https://github.com/nomadxxxx/hyprddm.git "$THEMES_PATH" 2>&1
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the repository. Please check your internet connection and try again."
        exit 1
    fi
    
    if [ -d "$THEMES_PATH/Fonts" ]; then
        echo "Copying fonts from $THEMES_PATH/Fonts to $FONTS_PATH..."
        sudo mkdir -p "$FONTS_PATH"
        sudo cp -r "$THEMES_PATH/Fonts/"* "$FONTS_PATH/"
        echo "Updating font cache..."
        sudo fc-cache -f
    fi
    
    echo "Configuring SDDM theme..."
    echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee "$SDDM_CONF"
    
    echo "Enabling virtual keyboard..."
    sudo mkdir -p /etc/sddm.conf.d/
    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee "$VIRTUAL_KBD_CONF"
    
    echo "SDDM Astronaut Theme installed successfully."
}

# Function to handle self-elevation with proper display permissions
self_elevate() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Elevating privileges..."
        echo "Current shell: $0"
        echo "Checking if script is piped..."

        # If the script is being piped (e.g., via curl | sh), save it to a temporary file
        if [ ! -f "$0" ] || [ "$0" = "sh" ] || [ "$0" = "bash" ] || [[ "$0" =~ ^/.*sh$ ]]; then
            echo "Script is being piped. Saving to temporary file: $TEMP_SCRIPT"
            cat - > "$TEMP_SCRIPT"
            chmod +x "$TEMP_SCRIPT"
            SCRIPT_TO_RUN="$TEMP_SCRIPT"
        else
            echo "Script is not piped. Using original path: $0"
            SCRIPT_TO_RUN="$0"
        fi

        export ORIGINAL_USER=$(whoami)
        export ORIGINAL_UID=$(id -u)
        export ORIGINAL_DISPLAY=${DISPLAY:-":1"}
        export ORIGINAL_XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-"/run/user/$ORIGINAL_UID"}
        export ORIGINAL_XAUTHORITY=${XAUTHORITY:-"$HOME/.Xauthority"}
        
        echo "Setting up Xauthority..."
        [ -f "$ORIGINAL_XAUTHORITY" ] || touch "$ORIGINAL_XAUTHORITY"
        xauth generate "$ORIGINAL_DISPLAY" . trusted 2>/dev/null
        
        echo "Testing XWayland access..."
        if ! DISPLAY="$ORIGINAL_DISPLAY" XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" XAUTHORITY="$ORIGINAL_XAUTHORITY" yad --title="Test" --text="Pre-elevation test" --timeout=1 2>/dev/null; then
            echo "Warning: Pre-elevation XWayland test failed. Display may not work correctly."
        fi
        
        echo "Granting root access to X server..."
        xhost +SI:localuser:root >/dev/null 2>&1
        
        echo "Executing sudo command to elevate privileges..."
        sudo -E env DISPLAY="$ORIGINAL_DISPLAY" \
            XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" \
            XAUTHORITY="$ORIGINAL_XAUTHORITY" \
            ORIGINAL_USER="$ORIGINAL_USER" \
            ORIGINAL_UID="$ORIGINAL_UID" \
            "$SCRIPT_TO_RUN"
        
        echo "Revoking root access to X server..."
        xhost -SI:localuser:root >/dev/null 2>&1
        
        exit $?
    fi
    
    if [ -n "$ORIGINAL_USER" ] && [ "$ORIGINAL_USER" != "root" ]; then
        export XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR"
        export DISPLAY="$ORIGINAL_DISPLAY"
        export XAUTHORITY="$ORIGINAL_XAUTHORITY"
    fi
}

# Function to clean up temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    rm -f "$TEMP_SCRIPT"
}

# Register cleanup function to run on exit
trap cleanup EXIT

# Function to prepare thumbnails
prepare_thumbnails() {
    echo "Preparing thumbnails..."
    mkdir -p "$TEMP_DIR"
    chmod -R 755 "$TEMP_DIR"
    
    declare -A theme_previews
    theme_previews=(
        ["chainsaw_fury"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/chainsaw_fury.png"
        ["cloud"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cloud.png"
        ["neon_jinx"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/neon_jinx.png"
        ["savage"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/savage.png"
        ["starman"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/starman.png"
        ["astronaut"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/astronaut.png"
        ["black_hole"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/black_hole.png"
        ["cyberpunk"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cyberpunk.png"
        ["hyprland_kath"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/hyprland_kath.png"
        ["jake_the_dog"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/jake_the_dog.png"
        ["japanese_aesthetic"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/japanese_aesthetic.png"
        ["pixel_sakura"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/pixel_sakura_static.png"
        ["post-apocalyptic_hacker"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/post-apocalyptic_hacker.png"
        ["purple_leaves"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/purple_leaves.png"
    )
    
    for theme in "${!theme_previews[@]}"; do
        local_file="$THEMES_PATH/Backgrounds/$theme.png"
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$local_file" ]; then
            echo "Generating thumbnail for $theme from local file $local_file..."
            magick "$local_file" -resize 200x150 "$preview_file"
        elif [ ! -f "$preview_file" ]; then
            url="${theme_previews[$theme]}"
            echo "Downloading preview for $theme from $url..."
            curl -s -L --progress-bar "$url" -o "$preview_file"
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to download preview for $theme from $url."
            else
                echo "Generating thumbnail for $theme..."
                magick "$preview_file" -resize 200x150 "$preview_file"
            fi
        fi
    done
}

# Function to apply selected theme
apply_theme() {
    local theme="$1"
    echo "Applying theme: $theme"
    sudo sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee "$SDDM_CONF" > /dev/null
    echo "Theme applied successfully."
}

# Function to test theme
test_theme() {
    local theme="$1"
    echo "Testing theme: $theme"
    # Backup current metadata.desktop
    sudo cp "$METADATA_FILE" "$METADATA_FILE.bak"
    # Set the theme for testing
    sudo sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    # Run the test with full environment
    sudo env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" sddm-greeter-qt6 --test-mode --theme "$THEMES_PATH"
    # Restore original metadata.desktop
    sudo mv "$METADATA_FILE.bak" "$METADATA_FILE"
    echo "Test completed."
}

# Main function
main() {
    echo "Starting main function..."
    # Elevate privileges if needed
    self_elevate
    
    echo "Proceeding after privilege elevation..."
    # Detect distribution
    detect_distribution
    
    # Install dependencies and theme
    install_dependencies
    check_and_install_theme
    
    # Prepare thumbnails
    prepare_thumbnails
    
    # List of available themes (new themes at the top)
    THEMES=(
        "chainsaw_fury"
        "cloud"
        "neon_jinx"
        "savage"
        "starman"
        "astronaut"
        "black_hole"
        "cyberpunk"
        "hyprland_kath"
        "jake_the_dog"
        "japanese_aesthetic"
        "pixel_sakura"
        "post-apocalyptic_hacker"
        "purple_leaves"
    )
    
    # Build YAD list with previews
    yad_args=()
    yad_args+=("--title" "SDDM Astronaut Theme Selector")
    yad_args+=("--width" "800")
    yad_args+=("--height" "600")
    yad_args+=("--center")
    yad_args+=("--text" "Select an SDDM Theme")
    yad_args+=("--list")
    yad_args+=("--column" "Preview:IMG")
    yad_args+=("--column" "Theme:TEXT")
    yad_args+=("--column" "Description:TEXT")
    
    # Add each theme as a row
    for theme in "${THEMES[@]}"; do
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$preview_file" ]; then
            yad_args+=("$preview_file")
            yad_args+=("$theme")
            yad_args+=("SDDM $theme theme")
        else
            yad_args+=("/usr/share/icons/hicolor/48x48/apps/sddm.png")
            yad_args+=("$theme")
            yad_args+=("SDDM $theme theme - preview unavailable")
        fi
    done
    
    yad_args+=("--button=Apply:0")
    yad_args+=("--button=Test:2")
    yad_args+=("--button=Cancel:1")
    
    # Launch YAD GUI and capture output
    echo "Launching theme selector GUI..."
    yad "${yad_args[@]}" --print-column=2 > /tmp/yad_output 2>&1
    RET=$?
    SELECTION=$(cat /tmp/yad_output | grep -v "gtk-" | tr -d '|' | head -n 1)
    
    case $RET in
        0) # Apply
            if [ -n "$SELECTION" ]; then
                apply_theme "$SELECTION"
                yad --title="Success" \
                    --text="Theme '$SELECTION' applied successfully!" \
                    --button="OK:0" \
                    --width=300 --height=100 \
                    --center
            else
                echo "Error: No theme selected for Apply."
            fi
            ;;
        2) # Test
            if [ -n "$SELECTION" ]; then
                test_theme "$SELECTION"
            else
                echo "Error: No theme selected for Test."
            fi
            ;;
        1|252) # Cancel or closed
            echo "Operation cancelled."
            ;;
        *)
            echo "Error: Unexpected exit code $RET from YAD."
            ;;
    esac
}

# Execute main function
echo "Starting script execution..."
main