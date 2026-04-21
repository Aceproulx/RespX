# RespX

RespX is a simple CLI tool that extracts Base64-encoded HTTP responses from Burp Suite XML exports, decodes them, and saves them as readable files.
It automatically names output files based on the request URL and formats HTTP headers as comments depending on file type.

---

## How to export files in Burp Suite

1. Go to the **Logger** tab or the **Sitemap** under the **Target** tab
2. Select the requests/URLs whose responses you want to export
3. Right-click and select **"Save items"**
4. Give it a filename (e.g., `selectedItems.xml`) and click **"Save"**
   - The file will be in XML format (Burp's native export format)

**Next:** Use RespX to decode and extract individual responses from the XML file.

---

## Features

- Extracts Base64 responses from Burp Suite XML export files
- Decodes HTTP response bodies automatically
- Uses URL path as filename (e.g. `/challenge` → `challenge`)
- Formats headers as comments based on file type:
  - `//` for `.js` files
  - `<!-- -->` for `.html` or files without extension
- Handles duplicate filenames with MD5 hash suffixes (optional)
- Optionally preserves query parameters in filenames
- No external dependencies

---

## Usage

**Basic (auto-creates `respx-output/` directory):**
```bash
./respx_commented.sh selectedItems.xml
```

**Custom output directory:**
```bash
./respx_commented.sh selectedItems.xml ./my-responses
```

**With flags:**
```bash
# Keep query parameters in filenames
./respx_commented.sh selectedItems.xml --with-params

# Disable MD5 hash for duplicates (overwrites instead)
./respx_commented.sh selectedItems.xml --no-hash

# Combine flags
./respx_commented.sh selectedItems.xml ./out --with-params --no-hash
```

**Output:**
- Each response → separate file
- HTTP headers → commented (// for .js, <!-- --> for HTML)
- Blank line separator between headers and body
- Duplicates → appended with MD5 hash (unless `--no-hash`)
- Query params → stripped by default (unless `--with-params`)

---

## Example

**Input:** Burp XML export with request to `https://challenge-0426.intigriti.io/challenge`

**Command:**
```bash
./respx_commented.sh selectedItems.xml
```

**Output file:** `respx-output/challenge`
```html
<!--
HTTP/2 200 OK
Content-Type: text/html
Content-Length: 6082
X-Powered-By: Express
-->

<!DOCTYPE html>
<html lang="en">
...
```

---

## Notes

- RespX works with Burp Suite XML export files (generated via "Save items" → `.xml`)
- Focuses on decoding Base64-encoded HTTP responses
- Automatically separates HTTP headers from response body
- Designed for CTFs, bug bounty recon, and quick response analysis
- Multiple requests to the same endpoint? Use `--no-hash` to overwrite or rely on hash suffixes to keep all versions

---

## Why RespX?

**RespX** = **Response Extractor**

Short, fast, and built for hacking workflows. No manual Base64 decoding, no jumping between files—just extracted, readable responses ready for analysis.
