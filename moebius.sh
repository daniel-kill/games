#!/usr/bin/env bash
# ========================================================
# Moebius: The Orb of Celestial Harmony (1987)
# WSL Bash Launcher Script
# ========================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$DIR/moebius"
PORT=3085

# Ensure node is in PATH (handle NVM / local installations)
if ! command -v node &> /dev/null; then
    if [ -f "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"
    elif [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Parse Arguments
for arg in "$@"; do
    case $arg in
        --test|-t|--smoketest)
            echo "Running Moebius Automated Smoke Test Suite..."
            cd "$GAME_DIR"
            node test.js
            exit $?
            ;;
        --help|-h)
            echo "Usage: ./moebius.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --test, -t        Run headless automated smoke tests"
            echo "  --port <PORT>     Run server on custom port (default: 3085)"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
    esac
done

# Check port argument
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--port" && -n "$2" ]]; then
        PORT="$2"
        shift 2
    else
        shift
    fi
done

cd "$GAME_DIR"

echo "============================================================"
echo "    MOEBIUS: THE ORB OF CELESTIAL HARMONY (1987)            "
echo "    [Work-in-Progress Conversion / Early Engine Build]      "
echo "============================================================"
echo " Note: Core engine playable; quests & dungeons in progress."
echo " Starting game server on http://localhost:$PORT ..."
echo " Open http://localhost:$PORT in your web browser to play."
echo " Press Ctrl+C to terminate."
echo "============================================================"

# Try to launch default Windows browser if inside WSL
if command -v wslview &> /dev/null; then
    (sleep 1 && wslview "http://localhost:$PORT") &
elif command -v cmd.exe &> /dev/null; then
    (sleep 1 && cmd.exe /c start "http://localhost:$PORT" 2>/dev/null) &
fi

exec node server.js --port "$PORT"
