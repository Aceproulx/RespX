#!/bin/bash

# RespX — Extract + decode + comment Burp XML responses (multi-item support)
# Usage: ./respx.sh <burp_export.xml> [output_dir]

if [ -z "$1" ]; then
    echo "Usage: $0 <burp_export.xml> [output_dir]"
    exit 1
fi

FILE="$1"
OUTDIR="${2:-.}"

mkdir -p "$OUTDIR"
[ ! -f "$FILE" ] && echo "Error: File not found: $FILE" && exit 1

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
    
    echo "✓ $FILENAME"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
OUTFILES=$(ls -1 "$OUTDIR" 2>/dev/null | wc -l)
echo "Extracted $OUTFILES files → $OUTDIR/"
