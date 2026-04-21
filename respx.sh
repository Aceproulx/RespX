#!/bin/bash

# RespX — Extract + decode + comment Burp XML responses (multi-item support)
# Usage: ./respx.sh <burp_export.xml> [output_dir] [--with-params] [--no-hash]
#
# Options:
#   --with-params    Include URL query parameters in filenames
#                    (default: strip params, e.g. "challenge?foo=bar" → "challenge")
#   --no-hash        Don't append MD5 hash to duplicate filenames
#                    (default: append hash for duplicates, e.g. "challenge_HASH")

INCLUDE_PARAMS=0
DISABLE_HASH=0

# Parse arguments
FILE=""
OUTDIR="."

for arg in "$@"; do
    case "$arg" in
        --with-params)
            INCLUDE_PARAMS=1
            ;;
        --no-hash)
            DISABLE_HASH=1
            ;;
        -*)
            echo "Unknown option: $arg"
            exit 1
            ;;
        *)
            if [ -z "$FILE" ]; then
                FILE="$arg"
            else
                OUTDIR="$arg"
            fi
            ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Usage: $0 <burp_export.xml> [output_dir] [--with-params] [--no-hash]"
    echo ""
    echo "Options:"
    echo "  --with-params    Include URL query parameters in filenames"
    echo "  --no-hash        Don't append MD5 hash to duplicate filenames"
    exit 1
fi

mkdir -p "$OUTDIR"
[ ! -f "$FILE" ] && echo "Error: File not found: $FILE" && exit 1

# Track seen filenames to handle duplicates
declare -A SEEN_FILES

# Find all <item> start lines and process each
grep -n "<item>" "$FILE" | cut -d: -f1 | while read START_LINE; do
    # Find the closing </item> for THIS item
    CLOSE_LINE=$(sed -n "${START_LINE},\$p" "$FILE" | grep -n '</item>' | head -1 | cut -d: -f1)
    [ -z "$CLOSE_LINE" ] && continue
    CLOSE_LINE=$((START_LINE + CLOSE_LINE - 1))
    
    # Extract this item block only
    ITEM=$(sed -n "${START_LINE},${CLOSE_LINE}p" "$FILE")
    [ -z "$ITEM" ] && continue
    
    # Extract URL
    URL=$(echo "$ITEM" | grep -oP '(?<=<url><!\[CDATA\[).*?(?=\]\]></url>)')
    [ -z "$URL" ] && continue
    
    # Get filename from URL
    FILENAME=$(basename "$URL")
    
    # Strip query parameters by default (unless --with-params flag is set)
    if [ "$INCLUDE_PARAMS" -eq 0 ]; then
        FILENAME="${FILENAME%%\?*}"  # Remove everything from ? onwards
    fi
    
    [ -z "$FILENAME" ] && FILENAME="response"
    
    # Extract & decode response
    ENCODED=$(echo "$ITEM" | grep -oP '(?<=<response base64="true"><!\[CDATA\[).*?(?=\]\]></response>)')
    [ -z "$ENCODED" ] && continue
    
    DECODED=$(echo "$ENCODED" | base64 -d 2>/dev/null)
    [ $? -ne 0 ] && continue
    
    # Split headers from body on blank line (\r\n\r\n or \n\n)
    # Remove \r chars first, then split on blank line
    DECODED_CLEAN=$(echo "$DECODED" | tr -d '\r')
    HEADERS=$(printf '%s\n' "$DECODED_CLEAN" | awk '/^$/{exit} {print}')
    BODY=$(printf '%s\n' "$DECODED_CLEAN" | awk '/^$/{flag=1; next} flag {print}')
    
    # Determine comment style by file extension
    case "$FILENAME" in
        *.js)
            COMMENT_PREFIX="//"
            WRAP_OPEN=""
            WRAP_CLOSE=""
            ;;
        *.html|*.htm)
            COMMENT_PREFIX=""
            WRAP_OPEN="<!--"
            WRAP_CLOSE="-->"
            ;;
        *)
            # No extension or other types → HTML comment style
            COMMENT_PREFIX=""
            WRAP_OPEN="<!--"
            WRAP_CLOSE="-->"
            ;;
    esac
    
    OUTFILE="$OUTDIR/$FILENAME"
    
    # Check for duplicate filenames and add MD5 hash if needed (unless --no-hash is set)
    if [ "$DISABLE_HASH" -eq 0 ] && [ -f "$OUTFILE" ]; then
        # Calculate MD5 hash of the body content (first 16 chars)
        CONTENT_HASH=$(echo "$BODY" | md5sum | awk '{print $1}' | cut -c1-16)
        
        # Insert hash before file extension (if any)
        if [[ "$FILENAME" =~ \. ]]; then
            # Has extension: challenge.js → challenge_HASH.js
            FILENAME_BASE="${FILENAME%.*}"
            FILENAME_EXT=".${FILENAME##*.}"
            OUTFILE="$OUTDIR/${FILENAME_BASE}_${CONTENT_HASH}${FILENAME_EXT}"
        else
            # No extension: challenge → challenge_HASH
            OUTFILE="$OUTDIR/${FILENAME}_${CONTENT_HASH}"
        fi
    fi
    
    # Write output: comment ONLY headers, body is raw
    {
        # Opening comment tag (if wrapping style)
        [ -n "$WRAP_OPEN" ] && echo "$WRAP_OPEN"
        
        # Comment each HEADER line only
        while IFS= read -r line; do
            if [ -n "$COMMENT_PREFIX" ]; then
                # For .js: prefix headers with //
                echo "$COMMENT_PREFIX $line"
            else
                # For HTML/no-ext: just output headers (wrapped in <!-- -->)
                echo "$line"
            fi
        done <<< "$HEADERS"
        
        # Closing comment tag (if wrapping style)
        [ -n "$WRAP_CLOSE" ] && echo "$WRAP_CLOSE"
        
        # Blank line separator between headers and body
        echo ""
        
        # Body content - output AS-IS, NO comments
        [ -n "$BODY" ] && printf '%s\n' "$BODY"
    } > "$OUTFILE"
    
    # Display the actual final filename (may include hash)
    FINAL_FILENAME=$(basename "$OUTFILE")
    echo "✓ $FINAL_FILENAME"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
OUTFILES=$(ls -1 "$OUTDIR" 2>/dev/null | wc -l)
echo "Extracted $OUTFILES files → $OUTDIR/"
