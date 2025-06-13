#!/bin/bash

# Check for clean flag
if [ "$1" = "clean" ]; then
    echo "🧹 Cleaning Rust build artifacts..."
    cargo clean
    echo "🧹 Cleaning reports directory..."
    rm -rf reports/
    echo "✅ All clean!"
    exit 0
fi

# Get the ELF file path
ELF_FILE=${1:-"target/avr-none/debug/avr-flight.elf"}
REPORT_DIR="reports"

# Create reports directory
mkdir -p $REPORT_DIR

echo "Generating inspection files for: $ELF_FILE"

# Check if ELF file exists
if [ ! -f "$ELF_FILE" ]; then
    echo "Error: ELF file not found: $ELF_FILE"
    echo "Try running 'cargo build' first, or use './generate_reports.sh clean' to clean everything"
    exit 1
fi

# 1. Generate Map file (shows memory layout, symbols, sections)
echo "Generating map file..."
avr-objdump -h -S "$ELF_FILE" > "$REPORT_DIR/memory_map.txt"

# 2. Generate complete disassembly
echo "Generating disassembly..."
avr-objdump -d "$ELF_FILE" > "$REPORT_DIR/disassembly.s"

# 3. Generate assembly listing with source code intermixed
echo "Generating source listing..."
avr-objdump -S "$ELF_FILE" > "$REPORT_DIR/source_listing.s"

# 4. Generate symbol table
echo "Generating symbol table..."
avr-nm -n "$ELF_FILE" > "$REPORT_DIR/symbols.txt"

# 5. Generate section headers and sizes
echo "Generating section info..."
avr-objdump -h "$ELF_FILE" > "$REPORT_DIR/sections.txt"

# 6. Generate size breakdown
echo "Generating size report..."
avr-size "$ELF_FILE" > "$REPORT_DIR/size_summary.txt"
avr-size -A "$ELF_FILE" > "$REPORT_DIR/size_detailed.txt"

# 7. Generate hex file for flashing
echo "Generating hex file..."
avr-objcopy -O ihex "$ELF_FILE" "$REPORT_DIR/firmware.hex"

# 8. Generate binary file
echo "Generating binary file..."
avr-objcopy -O binary "$ELF_FILE" "$REPORT_DIR/firmware.bin"

# 9. Generate detailed ELF info
echo "Generating ELF info..."
avr-readelf -a "$ELF_FILE" > "$REPORT_DIR/elf_info.txt"

# 10. Create a summary report
echo "Generating summary report..."
cat > "$REPORT_DIR/build_summary.txt" << EOF
=== Build Summary ===
ELF File: $ELF_FILE
Generated: $(date)

=== Memory Usage ===
$(avr-size "$ELF_FILE")

=== Section Breakdown ===
$(avr-size -A "$ELF_FILE")

=== File Sizes ===
ELF: $(ls -lh "$ELF_FILE" | awk '{print $5}')
HEX: $(ls -lh "$REPORT_DIR/firmware.hex" | awk '{print $5}')
BIN: $(ls -lh "$REPORT_DIR/firmware.bin" | awk '{print $5}')

=== Generated Files ===
- memory_map.txt      : Memory layout and symbol map
- disassembly.s       : Complete disassembly
- source_listing.s    : Assembly with source code
- symbols.txt         : Symbol table (sorted by address)
- sections.txt        : Section headers
- size_summary.txt    : Basic size info
- size_detailed.txt   : Detailed size breakdown
- firmware.hex        : Intel HEX format (for flashing)
- firmware.bin        : Raw binary
- elf_info.txt        : Complete ELF information

=== Usage ===
./generate_reports.sh       : Generate reports
./generate_reports.sh clean : Clean everything
EOF

echo "✅ All reports generated in: $REPORT_DIR/"
echo ""
echo "Quick summary:"
avr-size "$ELF_FILE" 