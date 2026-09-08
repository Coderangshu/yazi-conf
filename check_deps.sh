#!/usr/bin/env bash
set -e

# Core tools needed for Yazi workflow
tools=(nvim glow unar pdftoppm)
missing_cmds=()

for cmd in "${tools[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_cmds+=("$cmd")
    fi
done

if [ ${#missing_cmds[@]} -eq 0 ]; then
    echo "All core Yazi dependencies present: ${tools[*]}"
    exit 0
fi

echo "Missing dependencies: ${missing_cmds[*]}"

# Map command names to package names per package manager
detect_and_install() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Detected macOS (Homebrew)..."
        local pkgs=()
        for c in "${missing_cmds[@]}"; do
            case "$c" in
                nvim) pkgs+=(neovim) ;;
                pdftoppm) pkgs+=(poppler) ;;
                *) pkgs+=("$c") ;;
            esac
        done
        brew install "${pkgs[@]}"
    elif command -v paru >/dev/null 2>&1; then
        echo "Detected Arch Linux (paru)..."
        local pkgs=()
        for c in "${missing_cmds[@]}"; do
            case "$c" in
                nvim) pkgs+=(neovim) ;;
                pdftoppm) pkgs+=(poppler) ;;
                *) pkgs+=("$c") ;;
            esac
        done
        paru -S --needed "${pkgs[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected Arch Linux (pacman)..."
        local pkgs=()
        for c in "${missing_cmds[@]}"; do
            case "$c" in
                nvim) pkgs+=(neovim) ;;
                pdftoppm) pkgs+=(poppler) ;;
                *) pkgs+=("$c") ;;
            esac
        done
        sudo pacman -S --needed "${pkgs[@]}"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "Detected Debian/Ubuntu (apt)..."
        local pkgs=()
        for c in "${missing_cmds[@]}"; do
            case "$c" in
                nvim) pkgs+=(neovim) ;;
                pdftoppm) pkgs+=(poppler-utils) ;;
                glow)
                    # glow requires charm repo on Debian/Ubuntu
                    if ! apt-cache show glow >/dev/null 2>&1; then
                        echo "Adding Charm repo for glow..."
                        sudo mkdir -p /etc/apt/keyrings
                        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
                    fi
                    pkgs+=(glow)
                    ;;
                *) pkgs+=("$c") ;;
            esac
        done
        sudo apt-get update
        sudo apt-get install -y "${pkgs[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        echo "Detected Fedora (dnf)..."
        local pkgs=()
        for c in "${missing_cmds[@]}"; do
            case "$c" in
                nvim) pkgs+=(neovim) ;;
                pdftoppm) pkgs+=(poppler-utils) ;;
                *) pkgs+=("$c") ;;
            esac
        done
        sudo dnf install -y "${pkgs[@]}"
    else
        echo "Unknown package manager. Please install manually: ${missing_cmds[*]}"
        exit 1
    fi
}

detect_and_install
echo "Dependencies installed successfully."

# Install tracked Yazi plugins from package.toml
if command -v ya >/dev/null 2>&1 && [ -f "$HOME/.config/yazi/package.toml" ]; then
    echo "Installing Yazi plugins from package.toml..."
    ya pkg install
fi
