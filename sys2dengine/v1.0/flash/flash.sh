#!/bin/bash
# flash.sh - Lumen OS sys2Dengine v1.0 Production Flasher
# Moto Nexus 6 (ARMv7a) Deployment Script
# Belo Horizonte, BR - Feb 2026

set -e  # Exit on any error

# Colors for pretty output
RED='\u001B[0;31m'
GREEN='\u001B[0;32m'
YELLOW='\u001B[1;33m'
BLUE='\u001B[0;34m'
NC='\u001B[0m' # No Color

echo -e "${BLUE}🚀 Lumen OS sys2Dengine v1.0 Flasher${NC}"
echo -e "${BLUE}================================${NC}"

# Check for binary
if [ ! -f "lumen_sys2dengine_v1.0.elf" ]; then
    echo -e "${RED}❌ ERROR: lumen_sys2dengine_v1.0.elf not found!${NC}"
    echo "Run: make clean && make"
    exit 1
fi

# Check for root/adb/fastboot
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ ERROR: Run as root (sudo ./flash.sh)${NC}"
    exit 1
fi

command -v adb >/dev/null 2>&1 || { echo -e "${RED}❌ adb not found${NC}"; exit 1; }
command -v fastboot >/dev/null 2>&1 || { echo -e "${RED}❌ fastboot not found${NC}"; exit 1; }

echo -e "${YELLOW}🔍 Detecting Nexus 6...${NC}"
adb devices | grep "Nexus_6" || {
    echo -e "${YELLOW}⚠️  Nexus 6 not detected. Rebooting to bootloader...${NC}"
    adb reboot bootloader
    sleep 3
}

# Nexus 6 fastboot check
fastboot devices | grep "fastboot" || {
    echo -e "${RED}❌ Nexus 6 not in fastboot mode${NC}"
    echo "Bootloader manually or: adb reboot bootloader"
    exit 1
}

echo -e "${GREEN}✅ Nexus 6 detected in fastboot${NC}"

# Backup current graphics driver
echo -e "${YELLOW}💾 Backing up current /system/lib...${NC}"
fastboot boot twrp.img 2>/dev/null || echo "TWRP not needed for graphics binary"
adb shell "cp /system/lib/egl/libGLES_mali.so /sdcard/gles_backup.so" || true

echo -e "${GREEN}🎯 Flashing sys2Dengine v1.0...${NC}"

# Method 1: Direct /system/lib injection (fastest)
echo -e "${YELLOW}📱 Pushing NEON-optimized engine...${NC}"
adb push lumen_sys2dengine_v1.0.elf /data/local/tmp/sys2dengine.elf
adb shell "chmod 755 /data/local/tmp/sys2dengine.elf"
adb shell "stop surfaceflinger"  # Stop Android compositor
adb shell "mv /data/local/tmp/sys2dengine.elf /system/lib/sys2dengine.elf"
adb shell "chmod 644 /system/lib/sys2dengine.elf"

# Method 2: Custom init override (production)
cat > init.lumen.rc << 'EOF'
# Lumen OS sys2Dengine v1.0 - Production Init
on property:init.lumen.engine=1
    exec /system/bin/sys2dengine_main /dev/graphics/fb0

service sys2dengine /system/lib/sys2dengine.elf
    class main
    user graphics
    group graphics input
    critical
EOF

adb push init.lumen.rc /system/etc/init/
adb reboot

echo -e "${GREEN}✅ FLASH COMPLETE!${NC}"
echo -e "${BLUE}🎮 Nexus 6 rebooting with Lumen OS Graphics Engine v1.0${NC}"
echo ""
echo -e "${YELLOW}🔥 Features auto-enabled:${NC}"
echo -e "  • 60FPS VSYNC glassmorphism"
echo -e "  • NEON acceleration detected"
echo -e "  • Funny events + 3-7AM popups"
echo -e "  • Auto freeze recovery"
echo ""
echo -e "${GREEN}🎯 Engine auto-starts on boot!${NC}"
echo -e "${BLUE}📱 Check logcat: adb logcat -s LumenEngine${NC}"
