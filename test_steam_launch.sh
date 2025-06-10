#!/bin/bash

echo "Testing Steam launch functionality..."

# Define paths
WINE_PREFIX="$HOME/Library/Application Support/kimiz/gptk-bottles/default"
STEAM_EXE="$WINE_PREFIX/drive_c/Program Files (x86)/Steam/steam.exe"
WINE_PATH="/opt/homebrew/bin/wine"

echo "Wine prefix: $WINE_PREFIX"
echo "Steam executable: $STEAM_EXE"
echo "Wine path: $WINE_PATH"

# Check if Steam executable exists
if [ -f "$STEAM_EXE" ]; then
    echo "✓ Steam executable found"
else
    echo "✗ Steam executable not found"
    exit 1
fi

# Check if Wine exists
if [ -f "$WINE_PATH" ]; then
    echo "✓ Wine found"
else
    echo "✗ Wine not found"
    exit 1
fi

# Set environment variables
export WINEPREFIX="$WINE_PREFIX"
export WINE_LARGE_ADDRESS_AWARE=1
export STEAM_WEBHELPER_RENDERING=disabled
export STEAM_USE_WEBHELPER=0
export STEAM_DISABLE_BROWSER_SANDBOX=1
export STEAM_DISABLE_GPU_ACCELERATION=1
export WINEDEBUG=-all

echo "Environment variables set"

# Test Steam launch with a timeout
echo "Attempting to launch Steam with 10 second timeout..."
timeout 10s "$WINE_PATH" "$STEAM_EXE" --help > steam_output.log 2>&1

EXIT_CODE=$?
echo "Exit code: $EXIT_CODE"

if [ $EXIT_CODE -eq 124 ]; then
    echo "Steam launch timed out (this might be normal)"
elif [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Steam launched successfully"
else
    echo "✗ Steam launch failed with exit code $EXIT_CODE"
fi

echo "Steam output:"
cat steam_output.log

# Cleanup
rm -f steam_output.log

echo "Test completed"
