.PHONY: all clean install test

# Build both binaries
all: shortscan-enhanced shortutil

shortscan-enhanced:
	go build -o shortscan-enhanced cmd/shortscan/main.go

shortutil:
	go build -o shortutil cmd/shortutil/main.go

# Install to GOPATH/bin
install:
	go install ./cmd/shortscan
	go install ./cmd/shortutil

# Clean build artifacts
clean:
	rm -f shortscan-enhanced shortutil

# Build and test
test: all
	@echo "Testing shortscan-enhanced..."
	@./shortscan-enhanced --help | grep -q "scan-timeout" && echo "✓ Enhanced features present"
	@echo "Testing shortutil..."
	@./shortutil --help | grep -q "wordlist" && echo "✓ Shortutil working"

# Quick rainbow table generation (example)
rainbow:
	@echo "Generating rainbow table from built-in wordlist..."
	@./shortutil wordlist pkg/shortscan/resources/wordlist.txt > custom.rainbow
	@echo "✓ Rainbow table created: custom.rainbow"
