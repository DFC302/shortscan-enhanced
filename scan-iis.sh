#!/bin/bash
#
# IIS Shortname Scanner - Wrapper Script
# Combines shortutil + enhanced shortscan for easy scanning
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHORTSCAN="$SCRIPT_DIR/shortscan-enhanced"
SHORTUTIL="$SCRIPT_DIR/shortutil"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS] <targets-file|domain>

OPTIONS:
    -w, --wordlist FILE     Custom wordlist (will generate rainbow table)
    -d, --save-dir DIR      Directory to save vulnerable results
    -t, --timeout DURATION  Scan timeout per domain (default: 10m)
    -h, --help             Show this help

EXAMPLES:
    # Scan single domain with default settings
    $0 example.com

    # Scan from file with results saved
    $0 -d ./results targets.txt

    # Use custom wordlist with 5 minute timeout
    $0 -w ~/wordlists/custom.txt -t 5m -d ./results targets.txt

    # Pipe domains directly
    cat domains.txt | $0 -d ./results

EOF
    exit 1
}

# Parse arguments
WORDLIST=""
SAVE_DIR=""
TIMEOUT="10m"
INPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--wordlist)
            WORDLIST="$2"
            shift 2
            ;;
        -d|--save-dir)
            SAVE_DIR="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            INPUT="$1"
            shift
            ;;
    esac
done

# Build tools if not present
if [[ ! -f "$SHORTSCAN" ]] || [[ ! -f "$SHORTUTIL" ]]; then
    echo -e "${YELLOW}Building tools...${NC}"
    cd "$SCRIPT_DIR"
    make all
fi

# Generate rainbow table if custom wordlist provided
RAINBOW_TABLE=""
if [[ -n "$WORDLIST" ]]; then
    if [[ ! -f "$WORDLIST" ]]; then
        echo "Error: Wordlist not found: $WORDLIST"
        exit 1
    fi

    RAINBOW_TABLE="/tmp/shortscan-rainbow-$$.txt"
    echo -e "${YELLOW}Generating rainbow table from wordlist...${NC}"
    "$SHORTUTIL" wordlist "$WORDLIST" > "$RAINBOW_TABLE"
    echo -e "${GREEN}✓ Rainbow table created${NC}"
fi

# Build shortscan command
SCAN_ARGS=()
SCAN_ARGS+=("--scan-timeout" "$TIMEOUT")

if [[ -n "$SAVE_DIR" ]]; then
    SCAN_ARGS+=("--save-dir" "$SAVE_DIR")
fi

if [[ -n "$RAINBOW_TABLE" ]]; then
    SCAN_ARGS+=("-w" "$RAINBOW_TABLE")
fi

# Run scan
if [[ -n "$INPUT" ]]; then
    # Input from file or single domain
    if [[ -f "$INPUT" ]]; then
        echo -e "${GREEN}Scanning targets from: $INPUT${NC}"
        cat "$INPUT" | "$SHORTSCAN" "${SCAN_ARGS[@]}"
    else
        echo -e "${GREEN}Scanning domain: $INPUT${NC}"
        echo "$INPUT" | "$SHORTSCAN" "${SCAN_ARGS[@]}"
    fi
else
    # Input from stdin
    echo -e "${GREEN}Scanning targets from stdin...${NC}"
    "$SHORTSCAN" "${SCAN_ARGS[@]}"
fi

# Cleanup temporary rainbow table
if [[ -n "$RAINBOW_TABLE" ]]; then
    rm -f "$RAINBOW_TABLE"
fi

echo -e "${GREEN}✓ Scan complete${NC}"
