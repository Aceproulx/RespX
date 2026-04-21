# RespX

RespX is a simple CLI tool that extracts Base64-encoded HTTP responses from Burp Suite XML exports, decodes them, and saves them as readable files.

It automatically names output files based on the request URL and formats HTTP headers as comments depending on file type.

---
# How to export files in Burp Suite
- Go to the Logger tab
- Select the requests which you would like to export the responses
- Right click then click "Save items"
- Give it a name then click on "Save"
-  To turn the exported file to files like js files, html files for some sort of analysis use respx
## Features

- Extracts Base64 responses from Burp Suite XML export files
- Decodes HTTP response bodies automatically
- Uses URL path as filename (e.g. `/challenge` → `challenge`)
- Formats headers as comments based on file type:
  - `//` for `.js`
  - `<!-- -->` for `.html` or files without extension
- No external dependencies

---

## Usage

```bash
./respx char
```

---

## Example

Input URL:

```
https://challenge-0426.intigriti.io/challenge
```

Output file:

```
challenge
```

---

## Notes

- `char` is a Burp Suite export file containing captured HTTP requests and responses.
- RespX focuses on decoding only Base64-encoded responses.
- Designed for CTFs, bug bounty recon, and quick response analysis.

---

## Why RespX?

RespX = Response Extractor.

Short, fast, and built for hacking workflows.

