#!/bin/bash

# SDDM Astronaut Theme Selector with YAD GUI
# A script to select and apply themes for SDDM using the sddm-astronaut-theme project.

THEMES_PATH="/usr/share/sddm/themes/sddm-astronaut-theme"
FONTS_PATH="/usr/share/fonts"
METADATA_FILE="$THEMES_PATH/metadata.desktop"
SDDM_CONF="/etc/sddm.conf"
VIRTUAL_KBD_CONF="/etc/sddm.conf.d/virtualkbd.conf"
TEMP_DIR="/tmp/sddm-previews-$USER"
SCRIPT_PATH=$(readlink -f "$0")

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
}

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    case $DISTRO in
        arch)
            sudo pacman -S --noconfirm --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg yad polkit xorg-xwayland imagemagick curl
            ;;
        void)
            sudo xbps-install -Sy sddm qt6-svg qt6-virtualkeyboard qt6-multimedia yad polkit xwayland imagemagick curl
            ;;
        fedora)
            sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia yad polkit xorg-x11-server-Xwayland imagemagick curl
            ;;
        opensuse)
            sudo zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia yad polkit xorg-x11-server imagemagick curl
            ;;
        *)
            echo "Unsupported distribution. Please install dependencies manually."
            echo "Required packages: sddm, qt6-svg, qt6-virtualkeyboard, qt6-multimedia, yad, polkit, xwayland, imagemagick, curl"
            ;;
    esac
}

# Function to check and install theme files
check_and_install_theme() {
    if [ ! -d "$THEMES_PATH" ] || [ ! -f "$THEMES_PATH/Themes/astronaut.conf" ]; then
        echo "SDDM Astronaut Theme files are missing. Installing from nomadxxxx's fork..."
        sudo git clone -b master --depth 1 https://github.com/nomadxxxx/sddm-astronaut-theme.git "$THEMES_PATH"
        
        if [ -d "$THEMES_PATH/Fonts" ]; then
            sudo mkdir -p "$FONTS_PATH"
            sudo cp -r "$THEMES_PATH/Fonts/"* "$FONTS_PATH/"
            sudo fc-cache -f
        fi
        
        echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee "$SDDM_CONF"
        
        sudo mkdir -p /etc/sddm.conf.d/
        echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee "$VIRTUAL_KBD_CONF"
        
        echo "SDDM Astronaut Theme installed successfully."
    fi
}

# Function to handle self-elevation with proper display permissions
self_elevate() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Elevating privileges..."
        
        export ORIGINAL_USER=$(whoami)
        export ORIGINAL_UID=$(id -u)
        export ORIGINAL_DISPLAY=${DISPLAY:-":1"}
        export ORIGINAL_XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-"/run/user/$ORIGINAL_UID"}
        export ORIGINAL_XAUTHORITY=${XAUTHORITY:-"$HOME/.Xauthority"}
        
        [ -f "$ORIGINAL_XAUTHORITY" ] || touch "$ORIGINAL_XAUTHORITY"
        xauth generate "$ORIGINAL_DISPLAY" . trusted 2>/dev/null
        
        if ! DISPLAY="$ORIGINAL_DISPLAY" XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" XAUTHORITY="$ORIGINAL_XAUTHORITY" yad --title="Test" --text="Pre-elevation test" --timeout=1 2>/dev/null; then
            echo "Warning: Pre-elevation XWayland test failed. Display may not work correctly."
        fi
        
        xhost +SI:localuser:root >/dev/null 2>&1
        sudo -E env DISPLAY="$ORIGINAL_DISPLAY" \
            XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" \
            XAUTHORITY="$ORIGINAL_XAUTHORITY" \
            ORIGINAL_USER="$ORIGINAL_USER" \
            ORIGINAL_UID="$ORIGINAL_UID" \
            "$SCRIPT_PATH"
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
    rm -rf "$TEMP_DIR"
}

# Register cleanup function to run on exit
trap cleanup EXIT

# Function to prepare thumbnails
prepare_thumbnails() {
    mkdir -p "$TEMP_DIR"
    chmod -R 755 "$TEMP_DIR"
    
    declare -A theme_previews
    theme_previews=(
        ["chainsaw_fury"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/chainsaw_fury.png"
        ["cloud"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/cloud.png"
        ["neon_jinx"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/neon_jinx.png"
        ["savage"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/savage.png"
        ["starman"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/starman.png"
        ["astronaut"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/astronaut.png"
        ["black_hole"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/black_hole.png"
        ["cyberpunk"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/cyberpunk.png"
        ["hyprland_kath"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/hyprland_kath.png"
        ["jake_the_dog"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/jake_the_dog.png"
        ["japanese_aesthetic"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/japanese_aesthetic.png"
        ["pixel_sakura"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/pixel_sakura_static.png"
        ["post-apocalyptic_hacker"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/post-apocalyptic_hacker.png"
        ["purple_leaves"]="https://github.com/nomadxxxx/sddm-astronaut-theme/raw/master/Backgrounds/purple_leaves.png"
    )
    
    for theme in "${!theme_previews[@]}"; do
        local_file="$THEMES_PATH/Backgrounds/$theme.png"
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$local_file" ]; then
            magick "$local_file" -resize 200x150 "$preview_file"
        elif [ ! -f "$preview_file" ]; then
            url="${theme_previews[$theme]}"
            curl -s -L "$url" -o "$preview_file"
            magick "$preview_file" -resize 200x150 "$preview_file"
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
    # Elevate privileges if needed
    self_elevate
    
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
main