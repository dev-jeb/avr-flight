# AVR Flight Project Makefile

.PHONY: build clean reports run help

# Default target
help:
	@echo "Available targets:"
	@echo "  build     - Build the project"
	@echo "  clean     - Clean build artifacts and reports"
	@echo "  reports   - Generate inspection reports"
	@echo "  run       - Build and run with simavr"
	@echo "  help      - Show this help"

# Build the project
build:
	cargo build

# Clean everything
clean:
	@echo "🧹 Cleaning Rust build artifacts..."
	cargo clean
	@echo "🧹 Cleaning reports directory..."
	rm -rf reports/
	@echo "✅ All clean!"

# Generate reports
reports: build
	./generate_reports.sh

# Build and run
run: build
	cargo run

# Build, generate reports, and run
all: build reports 