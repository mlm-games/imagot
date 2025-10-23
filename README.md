# Imagot

An PoC image viewer in Godot

<div align="center">

[![GitHub Release](https://img.shields.io/github/v/release/mlm-games/imagot?style=for-the-badge&logo=github&label=GitHub&color=181717)](https://github.com/mlm-games/imagot/releases/latest)
<!--[![Flathub Version](https://img.shields.io/flathub/v/io.github.mlm_games.imagot?style=for-the-badge&logo=flathub&label=Flathub&color=4a86cf)](https://flathub.org/apps/io.github.mlm_games.imagot)
-->
[![AUR Version](https://img.shields.io/aur/version/imagot-bin?style=for-the-badge&logo=archlinux&label=AUR&color=1793d1)](https://aur.archlinux.org/packages/imagot-bin)

<!--[![Snap Version](https://img.shields.io/snapcraft/v/imagot?style=for-the-badge&logo=snapcraft&label=Snap&color=82BEA0)](https://snapcraft.io/imagot)
-->
[![Chocolatey Version](https://img.shields.io/chocolatey/v/imagot?style=for-the-badge&logo=chocolatey&label=Chocolatey&color=80b5e3)](https://community.chocolatey.org/packages/imagot)
[![WinGet Version](https://img.shields.io/badge/WinGet-Available-blue?style=for-the-badge&logo=microsoft)](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/MLMGames/Imagot)

</div>

## 🖼️ Screenshots

<div align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2.png" width="30%">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3.png" width="30%">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/4.png" width="30%">
</div>

## Features

- **Format Support** - PNG, JPG, JPEG, WebP, BMP, TGA, SVG, EXR, HDR
- **Basic Operations** - Zoom, pan, rotate, flip
- **Keyboard Navigation** - Browse images in folder with arrow keys
- **Drag & Drop** - Open images by dragging onto window
- **Lightweight** - Fast startup and minimal resource usage

## Installation

### Windows

```powershell
# WinGet
winget install MLMGames.Imagot

# Chocolatey
choco install imagot

# Scoop
scoop bucket add mlm-games https://github.com/mlm-games/buckets-scoop
scoop install imagot
```

### Linux

```bash
# Flatpak (Flathub)
flatpak install flathub io.github.mlm_games.imagot

# Snap
sudo snap install imagot

# AUR (Arch Linux)
yay -S imagot-bin
```

### macOS & Others

Download from [GitHub Releases](https://github.com/mlm-games/imagot/releases/latest)

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open File | `Ctrl+O` |
| Zoom In/Out | `Ctrl+`/`Ctrl-` |
| Fit to Window | `Ctrl+0` |
| Actual Size | `Ctrl+1` |
| Rotate Left/Right | `Ctrl+L`/`Ctrl+R` |
| Flip Horizontal/Vertical | `H`/`V` |
| Next/Previous Image | `→`/`←` or `D`/`A` |
| Image Properties | `Ctrl+I` |
| Toggle Fullscreen | `F11` |

## Building from Source

Requirements:
- Godot 4.5+
- Git

```bash
# Clone repository
git clone https://github.com/mlm-games/imagot
cd imagot

# Open in Godot Editor
godot project.godot

# Or build from command line
godot --export-release "Linux" builds/imagot
```

## Version Trackers

| Platform   | Version |
|:-----------|:--------|
| F-Droid    |  There are better alts for mobiles |
| Flathub    | [![Flathub Version](https://img.shields.io/flathub/v/io.github.mlm_games.imagot)](https://flathub.org/apps/io.github.mlm_games.imagot) |
| Snap Store | [![Snapcraft Version](https://img.shields.io/snapcraft/v/imagot/latest/stable)](https://snapcraft.io/imagot) |
| AUR        | [![AUR Version](https://img.shields.io/aur/version/imagot-bin)](https://aur.archlinux.org/packages/imagot-bin) |
| WinGet     | ![WinGet Package Version](https://img.shields.io/winget/v/MLMGames.Imagot) |
| Chocolatey | [![Chocolatey Version](https://img.shields.io/chocolatey/v/imagot)](https://community.chocolatey.org/packages/imagot) |
| Scoop      | [![Scoop Version](https://img.shields.io/scoop/v/imagot?bucket=https://github.com/mlm-games/buckets-scoop)](https://github.com/mlm-games/buckets-scoop) |

## License

[GPL-3.0](LICENSE)

---

<div align="center">

Made with Godot Engine

</div>
