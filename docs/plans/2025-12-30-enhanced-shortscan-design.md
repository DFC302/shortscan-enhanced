# Enhanced Shortscan Design

**Date:** 2025-12-30
**Status:** Approved

## Overview

Enhance the shortscan IIS shortname enumeration tool with features from the existing bash wrapper script (iis-bs.sh): automatic file organization, vulnerability-based saving, logging, stdin input support, and per-domain scan timeout.

## Goals

1. Add per-domain scan timeout (default 10 minutes, configurable)
2. Support stdin input for domain lists (piped/redirected)
3. Optionally save scan results only for vulnerable domains
4. Organize saved files into letter-based directory structure
5. Log vulnerable domains with result counts
6. Maintain 100% backward compatibility with existing shortscan behavior

## New Command-Line Flags

### --scan-timeout (string, default: "10m")
- Limits total scan time per individual domain
- Accepts Go duration format: "600s", "10m", "1h"
- Independent from `-t` (per-request timeout)
- Graceful cancellation: stops scan, outputs partial results, continues to next domain
- Parsed with `time.ParseDuration()`, validated at startup

### --save-dir (string, optional)
- When specified, enables file saving for vulnerable domains only
- Creates letter-based subdirectories (e.g., `results/e/` for example.com)
- Saves output to `.ss` files with sanitized domain names
- Creates `iis.log` in save-dir with tab-separated format: `{domain}\t\t{line_count}`
- When not specified, current behavior unchanged (stdout only)

## Input Handling

### Stdin Support
**Priority logic:**
1. If positional URL arguments provided: use them (existing behavior)
2. If no arguments and stdin has data: read from stdin
3. Otherwise: show error (no URLs provided)

**Implementation:**
- Use `os.Stdin.Stat()` to detect pipe/redirect
- Read line-by-line with `bufio.Scanner`
- Trim whitespace, skip empty lines
- Preserve `@file.txt` syntax support

**Usage examples:**
```bash
shortscan example.com --fullurl -p 1          # existing
shortscan @targets.txt --fullurl -p 1         # existing
cat targets.txt | shortscan --fullurl -p 1    # new
shortscan --fullurl -p 1 < targets.txt        # new
```

## File Saving and Organization

### Output Capture
- Duplicate all output to in-memory buffer during scan
- Preserve real-time stdout for user visibility
- After scan completion, analyze buffer for vulnerability status

### Vulnerability Detection
- Search for "Vulnerable: Yes" (human format) or `"vulnerable":true` (JSON format)
- Only save files when vulnerability detected
- No files created for non-vulnerable domains

### Directory Structure
```
save-dir/
├── iis.log                    # Log of all vulnerable domains
├── e/
│   ├── example_com.ss         # Sanitized domain name
│   └── example_org.ss
├── g/
│   └── google_com.ss
└── ...
```

### Filename Sanitization
1. Convert domain to lowercase
2. Strip `https://` and `http://` prefixes
3. Remove trailing slashes
4. Replace dots with underscores: `example.com` → `example_com`
5. Add `.ss` extension

### Log File Format
- Location: `{save-dir}/iis.log`
- Format: `{domain}\t\t{line_count}` (tab-separated)
- Appended for each vulnerable domain
- Mutex-protected for concurrent writes

## Scan Timeout Implementation

### Context-Based Cancellation
- Use `context.WithTimeout` per domain in `Scan()` function
- Pass context through scan pipeline: `Scan()` → `enumerate()` → `fetch()`
- Update HTTP requests to use `http.NewRequestWithContext()`

### Graceful Timeout Handling
When timeout occurs:
1. Cancel in-flight HTTP requests
2. Stop character enumeration goroutines
3. Output partial results found so far
4. Log timeout event (debug level)
5. Continue to next domain

### User Feedback
- Human output: display timeout warning if scan incomplete
- JSON output: add optional `"timeout":true` field to status object
- Partial results still saved if vulnerable

## Implementation Changes

### Modified Files
- `pkg/shortscan/shortscan.go`: primary changes
- `cmd/shortscan/main.go`: no changes needed

### New Functions
- `sanitizeDomainName(url string) string`: domain to filename conversion
- `saveResult(saveDir, domain, output string)`: handle file/directory creation and saving
- `logVulnerable(saveDir, domain string, lineCount int)`: append to iis.log
- `captureOutput() *OutputBuffer`: wrapper for dual stdout/buffer output
- `detectStdin() ([]string, error)`: stdin detection and reading

### Modified Functions
- `Scan()`: add context parameter, timeout wrapper per URL, output capture
- `enumerate()`: check context.Done() in goroutine loop
- `fetch()`: use `http.NewRequestWithContext()` for cancellation
- `Run()`: add stdin detection, parse new flags, validate scan-timeout

### New Structures
```go
type OutputBuffer struct {
    buffer bytes.Buffer
    mu     sync.Mutex
}
```

## Error Handling

### Scan Timeout
- Invalid duration format: fatal error at startup with clear message
- Timeout too short (< 1s): warn but allow

### File System
- Cannot create save-dir: fatal error with helpful message
- Cannot create subdirectory: log error, skip saving this domain
- Cannot write file: log error, continue to next domain
- Disk full: log error, attempt to continue

### Stdin
- Detection fails: require URL arguments
- Empty stdin: show error (no URLs provided)
- Read errors: log warning, use URLs read so far

### Edge Cases
- Duplicate domains: scan each occurrence
- Very long domain names: truncate filename if exceeds filesystem limit
- Special characters in domains: sanitize to safe characters
- Empty vulnerability results: don't create empty files

## Backward Compatibility

All changes are additive and non-breaking:
- Existing CLI usage works identically
- New flags are optional
- Stdin only activates when no URLs in arguments
- Default behavior unchanged when `--save-dir` not specified
- All existing flags, options, and output formats preserved

## Testing Considerations

1. Per-domain timeout with fast/slow targets
2. Stdin input from various sources (pipe, redirect, file)
3. File saving for vulnerable vs non-vulnerable domains
4. Directory creation and organization
5. Concurrent iis.log writes
6. Filename sanitization edge cases
7. Timeout during various scan phases
8. Backward compatibility with existing usage patterns

## Example Usage

```bash
# Default behavior (unchanged)
shortscan example.com --fullurl -p 1

# With new features - piped input, 5min timeout, save results
cat targets.txt | shortscan --scan-timeout 5m --save-dir results --fullurl -p 1

# Quick vulnerability check with 30s timeout
shortscan example.com --scan-timeout 30s -V

# Save results with default 10min timeout
shortscan @targets.txt --save-dir ./iis-results
```
