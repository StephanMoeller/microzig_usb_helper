
#!/bin/bash
clear
set -e  # Exit on any error

echo "Building firmware..."
zig build

MOUNT_POINT="/run/media/stephan/RPI-RP2"
FIRMWARE="zig-out/firmware/he_poc.uf2"
TARGET="$MOUNT_POINT/he_poc.uf2"

echo "Waiting for USB drive to appear at $MOUNT_POINT..."
while [ ! -d "$MOUNT_POINT" ]; do
    sleep 0.2
done
echo "USB drive detected..."
sleep 0.5 # Ensure actually ready

echo "Copying firmware..."
cp "$FIRMWARE" "$TARGET"
echo "Firmware copied to $TARGET"
