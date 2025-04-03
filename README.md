<p align="center">
  <img src="https://github.com/nomadxxxx/hyprddm/blob/master/Previews/hyprddm.png" />
</p>
<p align="center">
HyprDDM is a fork of the sddm-astronaut-theme by Keyitdev with new themes and YAD-based gui.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/-Linux-ff7a18?style=flat-square&logo=linux&logoColor=white" alt="Linux Badge">
  <img src="https://img.shields.io/github/stars/nomadxxxx/hyprddm?style=flat-square&color=ff7a18" alt="GitHub Repo stars">
  <img src="https://img.shields.io/github/forks/nomadxxxx/hyprddm?style=flat-square&color=ff7a18" alt="GitHub Forks">
</p>

### Automatic Installation with Theme Selector

The easiest way to install hyprDDM and use the theme selector is to run the `install.sh` script:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nomadxxxx/hyprddm/master/install.sh)"
```
## Detailed Previews

| **Chainsaw Fury** | **Cloud** |
|:--:|:--:|
| <img src="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/chainsaw_fury.png" width="500"> | <img src="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cloud.png" width="500"> |

| **Neon Jinx** | **Savage** |
|:--:|:--:|
| <img src="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/neon_jinx.png" width="500"> | <img src="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/savage.png" width="500"> |

| **Starman** | **Astronaut** |
|:--:|:--:|
| <img src="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/starman.png" width="500"> | <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/astronaut.png" width="500"> |

| **Black Hole** | **Cyberpunk** |
|:--:|:--:|
| <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/black_hole.png" width="500"> | <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/cyberpunk.png" width="500"> |

| **Hyprland Kath** | **Jake the Dog** |
|:--:|:--:|
| <img src="https://github.com/Keyitdev/screenshots/blob/master/sddm-astronaut-theme/master/frame_hyprland_kath.png" width="500"> | <img src="https://github.com/Keyitdev/screenshots/blob/master/sddm-astronaut-theme/master/frame_jake_the_dog.png" width="500"> |

| **Japanese Aesthetic** | **Pixel Sakura** |
|:--:|:--:|
| <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/japanese_aesthetic.png" width="500"> | <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/pixel_sakura_static.png" width="500"> |

| **Post-Apocalyptic Hacker** | **Purple Leaves** |
|:--:|:--:|
| <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/post-apocalyptic_hacker.png" width="500"> | <img src="https://github.com/Keyitdev/screenshots/raw/master/sddm-astronaut-theme/master/purple_leaves.png" width="500"> |


### Preview of Themes

![All Themes Preview](https://github.com/nomadxxxx/hyprddm/raw/master/Previews/previews.gif)

## This auto-install script will:

Install dependencies.
Clone the HyprDDM repository.
Set up the theme and virtual keyboard.
Launch a GUI to preview and apply themes.

### Manual Installation

1. Clone the repository
```sh
sudo git clone -b master --depth 1 https://github.com/nomadxxxx/hyprddm.git /usr/share/sddm/themes/sddm-astronaut-theme
```
2. Install Dependencies
```sh
# Arch
sudo pacman -S yad polkit xorg-xwayland imagemagick curl

# Void
sudo xbps-install -S yad polkit xwayland imagemagick curl

# Fedora
sudo dnf install yad polkit xorg-x11-server-Xwayland imagemagick curl

# OpenSUSE
sudo zypper install yad polkit xorg-x11-server imagemagick curl
```
3. Copy Fonts
```sh
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
sudo fc-cache -f
```
4. Configure SDDM
Edit /etc/sddm.conf
```sh
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
```
5. Enable Virtual Keyboard
Edit or create /etc/sddm.conf.d/virtualkbd.conf:
```sh
sudo mkdir -p /etc/sddm.conf.d/
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
```
6. Selecting a Theme

The install.sh script provides a GUI to preview and apply themes. If you installed manually, you can select a theme by editing /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop replacing this line with your desired theme e.g. astronaut.conf, cloud.conf, savage.conf etc
```sh
ConfigFile=Themes/astronaut.conf
```
### Previewing a Theme
```sh
To preview a theme without logging out, run:
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/
```
