# 🌀 Shortscan Enhanced

An enhanced version of the IIS short filename enumeration tool with additional features for penetration testing and security assessments.

**Based on the original [Shortscan](https://github.com/bitquark/shortscan) by bitquark**

## ✨ New Features

This enhanced version adds three major features while maintaining 100% backward compatibility:

### 1. 📥 Stdin Support
Pipe domain lists directly into shortscan:
```bash
cat targets.txt | shortscan-enhanced -V
```

### 2. ⏱️ Per-Domain Scan Timeout
Prevent scans from hanging indefinitely on slow servers:
```bash
shortscan-enhanced --scan-timeout 5m example.com
```
- Default: 10 minutes per domain
- Supports formats: `30s`, `5m`, `1h`, etc.
- Independent from per-request timeout (`-t` flag)

### 3. 💾 Automatic File Organization
Automatically save and organize results for vulnerable domains:
```bash
shortscan-enhanced --save-dir ./results example.com
```

**File Structure:**
```
results/
├── iis.log                    # Summary log
├── e/
│   ├── example_com.ss         # Scan results
│   └── example_org.ss
└── g/
    └── google_com.ss
```

**Features:**
- Only saves results for vulnerable domains (ignores non-vulnerable)
- Organizes by first letter of domain into subdirectories
- Creates `iis.log` with tab-separated domain/line-count entries
- Thread-safe for concurrent scanning

## 📦 Installation

### Quick Install (Recommended)

```bash
go install github.com/DFC302/shortscan-enhanced/cmd/shortscan@latest
```

This installs both `shortscan` and the `shortutil` helper tool to your `$GOPATH/bin`.

### Install Specific Version

```bash
go install github.com/DFC302/shortscan-enhanced/cmd/shortscan@v1.0.0
```

### Build from Source

```bash
git clone https://github.com/DFC302/shortscan-enhanced.git
cd shortscan-enhanced
make all
```

This creates:
- `shortscan-enhanced` - Main scanner binary
- `shortutil` - Rainbow table generator
- `scan-iis.sh` - Convenience wrapper script

## 🚀 Usage

### Basic Scanning

```bash
# Single domain
shortscan-enhanced example.com

# Multiple domains from file
shortscan-enhanced @targets.txt

# Pipe from stdin
cat domains.txt | shortscan-enhanced

# Quick vulnerability check
echo "example.com" | shortscan-enhanced -V
```

### Enhanced Features

```bash
# Scan with 2-minute timeout per domain
cat targets.txt | shortscan-enhanced --scan-timeout 2m -V

# Save vulnerable results automatically
cat targets.txt | shortscan-enhanced --save-dir ./results

# Combine all features
cat targets.txt | shortscan-enhanced \
    --scan-timeout 5m \
    --save-dir ./iis-results \
    --fullurl -p 1 -c 10
```

### Using the Wrapper Script

The `scan-iis.sh` wrapper makes it even easier:

```bash
# Simple scan with auto-save
./scan-iis.sh -d ./results targets.txt

# With custom wordlist (auto-generates rainbow table)
./scan-iis.sh -w ~/wordlists/custom.txt -d ./results targets.txt

# Pipe input with timeout
cat domains.txt | ./scan-iis.sh -d ./results -t 5m
```

## 🛠️ Shortutil - Rainbow Table Generator

Generate rainbow tables for improved filename detection:

```bash
# Build rainbow table from wordlist
shortutil wordlist input.txt > output.rainbow

# Use with shortscan
shortscan-enhanced -w output.rainbow example.com

# Generate one-off checksum
shortutil checksum index.html
```

## 🎯 Complete Options

```
Options:
  --wordlist FILE, -w FILE       Combined wordlist + rainbow table
  --header HEADER, -H HEADER     Custom header (use multiple times)
  --concurrency NUM, -c NUM      Concurrent requests [default: 20]
  --timeout SECONDS, -t SECONDS  Per-request timeout [default: 10]
  --output FORMAT, -o FORMAT     Output format (human/json) [default: human]
  --verbosity LEVEL, -v LEVEL    Noise level (0-2) [default: 0]
  --fullurl, -F                  Display full URLs
  --norecurse, -n                Don't recurse into subdirectories
  --stabilise, -s                Handle unstable servers (more requests)
  --patience LEVEL, -p LEVEL     Patience level (0-1) [default: 0]
  --characters CHARS, -C CHARS   Characters to enumerate
  --autocomplete MODE, -a MODE   Autocomplete mode (auto/method/status/distance/none)
  --isvuln, -V                   Only check vulnerability
  --scan-timeout DURATION        Per-domain timeout [default: 10m] ✨ NEW
  --save-dir DIR                 Auto-save vulnerable results ✨ NEW
```

## 📊 Example Workflow

```bash
# 1. Generate rainbow table from your wordlist
shortutil wordlist ~/wordlists/iis-common.txt > iis.rainbow

# 2. Scan targets with all features
cat targets.txt | shortscan-enhanced \
    -w iis.rainbow \
    --save-dir ./scan-results \
    --scan-timeout 3m \
    --fullurl \
    -p 1 \
    -c 10

# 3. Review results
cat ./scan-results/iis.log
ls -la ./scan-results/*/
```

## 🔄 Differences from Original

| Feature | Original | Enhanced |
|---------|----------|----------|
| Stdin input | ❌ | ✅ |
| Per-domain timeout | ❌ | ✅ (default 10m) |
| Auto-save vulnerable | ❌ | ✅ (optional) |
| File organization | ❌ | ✅ (letter-based dirs) |
| Vulnerability logging | ❌ | ✅ (iis.log) |
| All original features | ✅ | ✅ (100% compatible) |

## 🧪 Testing

Comprehensive testing performed:
- ✅ 27 test scenarios across all features
- ✅ Backward compatibility verified
- ✅ Thread-safety validated
- ✅ Production-ready

See [TESTING_REPORT.md](TESTING_REPORT.md) for details.

## 📝 Credits

**Original Tool:** [Shortscan by bitquark](https://github.com/bitquark/shortscan)

**IIS Short Filename Research:** [Soroush Dalili](https://soroush.secproject.com/downloadable/microsoft_iis_tilde_character_vulnerability_feature.pdf)

**Enhancements:** DFC302 (2025)
- Stdin support
- Per-domain timeout
- Automatic file organization
- Production hardening

## 📄 License

Same as original Shortscan project.

## 🤝 Contributing

This is an enhanced fork. For core functionality issues, please check the [original repository](https://github.com/bitquark/shortscan).

For enhancement-specific issues, please open an issue on this repository.
