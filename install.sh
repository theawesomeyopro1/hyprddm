#!/bin/bash

# SDDM Astronaut Theme Selector with YAD GUI
# A script to select and apply themes for SDDM using the sddm-astronaut-theme project.

# Define paths
# Use ORIGINAL_HOME if set (after elevation), otherwise use HOME
HYPRDDM_DIR="${ORIGINAL_HOME:-$HOME}/hyprddm"
THEMES_PATH="/usr/share/sddm/themes/sddm-astronaut-theme"
FONTS_PATH="/usr/share/fonts"
METADATA_FILE="$THEMES_PATH/metadata.desktop"
SDDM_CONF="/etc/sddm.conf"
VIRTUAL_KBD_CONF="/etc/sddm.conf.d/virtualkbd.conf"
TEMP_DIR="/tmp/sddm-previews-$USER"
SCRIPT_PATH="$HYPRDDM_DIR/install.sh"

# Function to log messages without debug clutter
log() {
    echo "$1"
}

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
    log "Detected distribution: $DISTRO"
}

# Function to install dependencies
install_dependencies() {
    log "Installing required dependencies..."
    case $DISTRO in
        arch)
            pkexec pacman -S --noconfirm --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg yad polkit xorg-xwayland imagemagick curl git
            ;;
        void)
            pkexec xbps-install -Sy sddm qt6-svg qt6-virtualkeyboard qt6-multimedia yad polkit xwayland imagemagick curl git
            ;;
        fedora)
            pkexec dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia yad polkit xorg-x11-server-Xwayland imagemagick curl git
            ;;
        opensuse)
            pkexec zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia yad polkit xorg-x11-server imagemagick curl git
            ;;
        *)
            log "Unsupported distribution. Please install dependencies manually."
            log "Required packages: sddm, qt6-svg, qt6-virtualkeyboard, qt6-multimedia, yad, polkit, xwayland, imagemagick, curl, git"
            ;;
    esac
}

# Function to check and install theme files
check_and_install_theme() {
    # Ensure the parent directory exists
    log "Ensuring parent directory /usr/share/sddm/themes exists..."
    pkexec mkdir -p /usr/share/sddm/themes
    if [ $? -ne 0 ]; then
        log "Error: Failed to create /usr/share/sddm/themes directory."
        exit 1
    fi

    # Check if the themes directory exists and contains files
    if [ -d "$THEMES_PATH" ] && [ -n "$(ls -A "$THEMES_PATH")" ]; then
        log "Warning: $THEMES_PATH already exists. Removing it to ensure a clean installation..."
        pkexec rm -rf "$THEMES_PATH"
        if [ $? -ne 0 ]; then
            log "Error: Failed to remove $THEMES_PATH. Please check permissions and try again."
            exit 1
        fi
        log "Successfully removed $THEMES_PATH."
    fi

    # Explicitly create the target directory
    log "Creating target directory $THEMES_PATH..."
    pkexec mkdir -p "$THEMES_PATH"
    if [ $? -ne 0 ]; then
        log "Error: Failed to create $THEMES_PATH directory."
        exit 1
    fi

    # Proceed with installation
    log "Installing SDDM Astronaut Theme from local repository..."
    log "Copying repository contents from $HYPRDDM_DIR to $THEMES_PATH..."
    pkexec cp -r "$HYPRDDM_DIR/"* "$THEMES_PATH/"
    
    if [ $? -ne 0 ]; then
        log "Error: Failed to copy repository contents to $THEMES_PATH."
        exit 1
    fi
    
    if [ -d "$THEMES_PATH/Fonts" ]; then
        log "Copying fonts from $THEMES_PATH/Fonts to $FONTS_PATH..."
        pkexec mkdir -p "$FONTS_PATH"
        pkexec cp -r "$THEMES_PATH/Fonts/"* "$FONTS_PATH/"
        log "Updating font cache..."
        pkexec fc-cache -f
    fi
    
    log "Configuring SDDM theme..."
    echo "[Theme]
Current=sddm-astronaut-theme" | pkexec tee "$SDDM_CONF"
    
    log "Enabling virtual keyboard..."
    pkexec mkdir -p /etc/sddm.conf.d/
    echo "[General]
InputMethod=qtvirtualkeyboard" | pkexec tee "$VIRTUAL_KBD_CONF"
    
    log "SDDM Astronaut Theme installed successfully."
}

# Function to handle self-elevation with proper display permissions
self_elevate() {
    if [ "$(id -u)" -ne 0 ]; then
        log "Elevating privileges..."

        export ORIGINAL_USER=$(whoami)
        export ORIGINAL_UID=$(id -u)
        export ORIGINAL_HOME="$HOME"
        export ORIGINAL_HYPRDDM_DIR="$HYPRDDM_DIR"
        export ORIGINAL_DISPLAY=${DISPLAY:-":1"}
        export ORIGINAL_XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-"/run/user/$ORIGINAL_UID"}
        export ORIGINAL_XAUTHORITY=${XAUTHORITY:-"$HOME/.Xauthority"}
        
        log "Setting up Xauthority..."
        [ -f "$ORIGINAL_XAUTHORITY" ] || touch "$ORIGINAL_XAUTHORITY"
        xauth generate "$ORIGINAL_DISPLAY" . trusted 2>/dev/null
        
        log "Testing XWayland access..."
        if ! DISPLAY="$ORIGINAL_DISPLAY" XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" XAUTHORITY="$ORIGINAL_XAUTHORITY" yad --title="Test" --text="Pre-elevation test" --timeout=1 2>/dev/null; then
            log "Warning: Pre-elevation XWayland test failed. Display may not work correctly."
        fi
        
        log "Granting root access to X server..."
        xhost +SI:localuser:root >/dev/null 2>&1
        
        log "Executing pkexec to elevate privileges..."
        pkexec env DISPLAY="$ORIGINAL_DISPLAY" \
            XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR" \
            XAUTHORITY="$ORIGINAL_XAUTHORITY" \
            ORIGINAL_USER="$ORIGINAL_USER" \
            ORIGINAL_UID="$ORIGINAL_UID" \
            ORIGINAL_HOME="$ORIGINAL_HOME" \
            ORIGINAL_HYPRDDM_DIR="$ORIGINAL_HYPRDDM_DIR" \
            "$SCRIPT_PATH"
        
        log "Revoking root access to X server..."
        xhost -SI:localuser:root >/dev/null 2>&1
        
        exit $?
    fi
    
    if [ -n "$ORIGINAL_USER" ] && [ "$ORIGINAL_USER" != "root" ]; then
        export XDG_RUNTIME_DIR="$ORIGINAL_XDG_RUNTIME_DIR"
        export DISPLAY="$ORIGINAL_DISPLAY"
        export XAUTHORITY="$ORIGINAL_XAUTHORITY"
        export HYPRDDM_DIR="$ORIGINAL_HYPRDDM_DIR"
    fi
}

# Function to clean up temporary files
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Register cleanup function to run on exit
trap cleanup EXIT

# Function to prepare thumbnails
prepare_thumbnails() {
    log "Preparing thumbnails..."
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
        ["cyberpunk"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cyberpunk.png"
        ["hyprland_kath"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/hyprland_kath.png"
        ["jake_the_dog"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/jake_the_dog.png"
        ["japanese_aesthetic"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/japanese_aesthetic.png"
        ["pixel_sakura"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/pixel_sakura_static.png"
        ["post-apocalyptic_hacker"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/post-apocalyptic_hacker.png"
        ["purple_leaves"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/purple_leaves.png"
        ["renzu"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/renzu.png"
        ["cybermonk"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cybermonk.png"
        ["ghost"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/ghost.png"
    )
    
    for theme in "${!theme_previews[@]}"; do
        local_file="$THEMES_PATH/Backgrounds/$theme.png"
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$local_file" ]; then
            log "Generating thumbnail for $theme from local file $local_file..."
            magick "$local_file" -resize 200x150 "$preview_file"
        elif [ ! -f "$preview_file" ]; then
            url="${theme_previews[$theme]}"
            log "Downloading preview for $theme from $url..."
            curl -s -L --progress-bar "$url" -o "$preview_file"
            if [ $? -ne 0 ]; then
                log "Warning: Failed to download preview for $theme from $url."
            else
                log "Generating thumbnail for $theme..."
                magick "$preview_file" -resize 200x150 "$preview_file"
            fi
        fi
    done
}

# Function to apply selected theme
apply_theme() {
    local theme="$1"
    log "Applying theme: $theme"
    pkexec sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    echo "[Theme]
Current=sddm-astronaut-theme" | pkexec tee "$SDDM_CONF" > /dev/null
    log "Theme applied successfully."
}

# Function to test theme
test_theme() {
    local theme="$1"
    log "Testing theme: $theme"
    # Backup current metadata.desktop
    pkexec cp "$METADATA_FILE" "$METADATA_FILE.bak"
    # Set the theme for testing
    pkexec sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    # Run the test with full environment
    pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" sddm-greeter-qt6 --test-mode --theme "$THEMES_PATH"
    # Restore original metadata.desktop
    pkexec mv "$METADATA_FILE.bak" "$METADATA_FILE"
    log "Test completed."
}

# Function to download the repository
download_repository() {
    log "Checking for existing hyprddm directory in ${ORIGINAL_HOME:-$HOME}..."
    if [ -d "$HYPRDDM_DIR" ]; then
        log "Directory $HYPRDDM_DIR already exists. Removing it to ensure a clean download..."
        rm -rf "$HYPRDDM_DIR"
    fi

    log "Creating hyprddm directory in ${ORIGINAL_HOME:-$HOME}..."
    mkdir -p "$HYPRDDM_DIR"

    log "Cloning repository from https://github.com/nomadxxxx/hyprddm.git to $HYPRDDM_DIR..."
    git clone -b master --depth 1 --progress https://github.com/nomadxxxx/hyprddm.git "$HYPRDDM_DIR" 2>&1
    
    if [ $? -ne 0 ]; then
        log "Error: Failed to clone the repository. Please check your internet connection and try again."
        exit 1
    fi

    log "Setting execute permissions on $SCRIPT_PATH..."
    chmod +x "$SCRIPT_PATH"
}

# Main function
main() {
    log "Starting main function..."
    # Elevate privileges if needed
    self_elevate
    
    log "Proceeding after privilege elevation..."
    # Detect distribution
    detect_distribution
    
    # Install dependencies and theme
    install_dependencies
    check_and_install_theme
    
    # Prepare thumbnails
    prepare_thumbnails
    
    # List of available themes (new themes at the top, removed black_hole)
    THEMES=(
        "renzu"
        "cybermonk"
        "ghost"
        "chainsaw_fury"
        "cloud"
        "neon_jinx"
        "savage"
        "starman"
        "astronaut"
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
    log "Launching theme selector GUI..."
    yad "${yad_args[@]}" --print-column=2 > /tmp/yad_output 2>&1
    RET=$?
    SELECTION=$(cat /tmp/yad_output | grep -v "gtk-" | tr -d '|' | head -n 1)
    
    case $RET in
        0)  # Apply
            if [ -n "$SELECTION" ]; then
                apply_theme "$SELECTION"
                yad --title="Success" \
                    --text="Theme '$SELECTION' applied successfully!" \
                    --button="OK:0" \
                    --width=300 \
                    --height=100 \
                    --center
            else
                log "Error: No theme selected for Apply."
            fi
            ;;
        2)  # Test
            if [ -n "$SELECTION" ]; then
                test_theme "$SELECTION"
            else
                log "Error: No theme selected for Test."
            fi
            ;;
        1|252)  # Cancel or closed
            log "Operation cancelled."
            ;;
        *)  # Unexpected exit code
            log "Error: Unexpected exit code $RET from YAD."
            ;;
    esac
}

# Execute script
log "Starting script execution..."

# Check if we're running from the hyprddm directory
if [ "$(pwd)" != "$HYPRDDM_DIR" ]; then
    log "Not running from $HYPRDDM_DIR. Downloading repository..."
    download_repository
    log "Repository downloaded. Executing script from $HYPRDDM_DIR..."
    cd "$HYPRDDM_DIR"
    exec "$SCRIPT_PATH"
else
    log "Already in $HYPRDDM_DIR. Proceeding with installation..."
    main
fi