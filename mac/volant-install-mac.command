#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# --- APPLICATION CONFIG ---
VOLANT_REPO="https://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@github.com/D3V-D/volant-core.git"
VOLANT_SOURCE="volant-core"
VOLANT_LAUNCH="launch-mac.command"

cat <<'EOF'


                        ,--,                               ___
       ,---.          ,--.'|                             ,--.'|_
      /__./|   ,---.  |  | :                     ,---,   |  | :,'
 ,---.;  ; |  '   ,'\ :  : '                 ,-+-. /  |  :  : ' :
/___/ \  | | /   /   ||  ' |     ,--.--.    ,--.'|'   |.;__,'  /
\   ;  \ ' |.   ; ,. :'  | |    /       \  |   |  ,"' ||  |   |
 \   \  \: |'   | |: :|  | :   .--.  .-. | |   | /  | |:__,'| :
  ;   \  ' .'   | .; :'  : |__  \__\/: . . |   | |  | |  '  : |__
   \   \   '|   :    ||  | '.'| ," .--.; | |   | |  |/   |  | '.'|
    \   `  ; \   \  / ;  :    ;/  /  ,.  | |   | |--'    ;  :    ;
     :   \ |  `----'  |  ,   /;  :   .'   \|   |/        |  ,   /
      '---"            ---`-' |  ,     .-./'---'          ---`-'
                               `--`---'

=================================
 Volant - Installation and Setup
=================================

EOF

export PATH="$PATH:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin"

require_command() {
    command -v "$1" >/dev/null 2>&1
}

fail() {
    echo "[X] $1"
    exit 1
}

# ===================================================
# 1. SYSTEM DEPENDENCY CHECK
# ===================================================

if ! require_command git; then
    if require_command brew; then
        echo "[+] Installing Git..."
        brew install git
    else
        echo "[!] Git was not found."
        echo "    macOS can install Git through the Xcode Command Line Tools."
        echo "    Follow the prompt, then re-run this installer:"
        xcode-select --install >/dev/null 2>&1 || true
        exit 1
    fi
fi

require_command git || fail "Git is still not available after install. Install Git manually from https://git-scm.com/download/mac and re-run this installer."

if ! require_command uv; then
    echo "[+] Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$PATH:$HOME/.local/bin"
fi

require_command uv || fail "uv is still not available after install. Open a new terminal and run 'uv --version', or install uv manually from https://docs.astral.sh/uv/ and re-run this installer."

# ===================================================
# 2. PROJECT REPOSITORY SETUP
# ===================================================

if [[ ! -f "$VOLANT_SOURCE/$VOLANT_LAUNCH" ]]; then
    if [[ -d "$VOLANT_SOURCE" ]]; then
        echo "[!] Folder \"$VOLANT_SOURCE\" exists but $VOLANT_LAUNCH was not found."
        echo "    Remove \"$VOLANT_SOURCE\" or fix the repo, then run this installer again."
        exit 1
    fi

    echo "[+] Cloning Volant repository..."
    echo "    $VOLANT_REPO"
    git clone "$VOLANT_REPO" "$VOLANT_SOURCE" || {
        echo
        echo "[X] Clone failed. Check:"
        echo "    - VOLANT_REPO at the top of this file points to the correct repo"
        echo "    - Git is installed and you have access (Credential Manager or SSH)"
        exit 1
    }
fi

echo "[+] Repository verified."

# ===================================================
# 3. PYTHON RUNTIME + PROJECT DEPENDENCIES (via uv)
# ===================================================

(
    cd "$VOLANT_SOURCE"

    echo "[+] Ensuring a managed Python runtime is installed..."
    uv python install || fail "uv could not install Python. Check your internet connection and retry."

    echo "[+] Installing Python dependencies (Streamlit, ...)..."
    uv sync || fail "uv sync failed. Check the output above for details."
)

# ===================================================
# 4. DESKTOP SHORTCUT CREATOR
# ===================================================

TARGET_SCRIPT="$PWD/$VOLANT_SOURCE/$VOLANT_LAUNCH"
SHORTCUT_PATH="$HOME/Desktop/Volant.command"

if [[ ! -f "$TARGET_SCRIPT" ]]; then
    fail "Launch script not found: $TARGET_SCRIPT. Add $VOLANT_LAUNCH to the repository root, then re-run this installer."
fi

chmod +x "$TARGET_SCRIPT"

echo "[+] Creating desktop shortcut..."
mkdir -p "$HOME/Desktop"
{
    printf '#!/usr/bin/env bash\n'
    printf 'cd %q\n' "$PWD/$VOLANT_SOURCE"
    printf 'exec %q\n' "$TARGET_SCRIPT"
} > "$SHORTCUT_PATH"
chmod +x "$SHORTCUT_PATH"

cat <<EOF

=====================================================
 Volant installed successfully!
 A shortcut has been created on your Desktop.
 Use it to launch Volant from: $VOLANT_SOURCE

 IMPORTANT: If you move this installation folder,
 delete the old folder and run this installer again
 from the new location so the shortcut stays valid.
=====================================================

EOF
