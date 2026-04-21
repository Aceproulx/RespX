#!/bin/bash

# Usage:
#   ./extract_and_save_with_comments.sh file_name

if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

FILE="$1"

# 1. Extract URL
URL=$(grep -Po '(?<=<url><!\[CDATA\[).*?(?=\]\]></url>)' "$FILE")

# 2. Get basename
BASENAME=$(basename "$URL")

# fallback
[ -z "$BASENAME" ] && BASENAME="output"

OUTFILE="$BASENAME"

# 3. Extract + decode response
RAW=$(grep -Po '(?<=<response base64="true"><!\[CDATA\[).*?(?=\]\]></response>)' "$FILE" | base64 -d)

# 4. Split headers + body
HEADERS=$(echo "$RAW" | sed '/^\r$/q')
BODY=$(echo "$RAW" | sed '1,/^\r$/d')

# fallback if \r isn't detected
if [ -z "$BODY" ]; then
    HEADERS=$(echo "$RAW" | sed '/^$/q')
    BODY=$(echo "$RAW" | sed '1,/^$/d')
fi

# 5. Decide comment style
if [[ "$OUTFILE" == *.js ]]; then
    COMMENT_PREFIX="// "
    COMMENT_WRAP_START=""
    COMMENT_WRAP_END=""
elif [[ "$OUTFILE" == *.html ]] || [[ "$OUTFILE" != *.* ]]; then
    COMMENT_PREFIX=""
    COMMENT_WRAP_START="<!--"
    COMMENT_WRAP_END="-->"
else
    COMMENT_PREFIX="# "
    COMMENT_WRAP_START=""
    COMMENT_WRAP_END=""
fi

# 6. Write output
{
    if [ -n "$COMMENT_WRAP_START" ]; then
        echo "$COMMENT_WRAP_START"
    fi

    while IFS= read -r line; do
        echo "${COMMENT_PREFIX}${line}"
    done <<< "$HEADERS"

    if [ -n "$COMMENT_WRAP_END" ]; then
        echo "$COMMENT_WRAP_END"
    fi

    echo "$BODY"
} > "$OUTFILE"

echo "Saved response as: $OUTFILE"
