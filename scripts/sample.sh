#!/bin/bash
# sample.sh - Create a random 1,000-row sample from the dataset
# Usage: ./scripts/sample.sh data/archive/HouseTS.csv

set -e  # stop if any command fails

INPUT=$1
OUTPUT="data/samples/sample1k.csv"

if [ ! -f "$INPUT" ]; then
  echo "Error: Input file $INPUT not found!"
  exit 1
fi

echo "Generating 1,000-row sample from $INPUT..."

# Extract header
head -n 1 "$INPUT" > "$OUTPUT"

# Append 1000 random rows using awk
tail -n +2 "$INPUT" | awk 'BEGIN{srand()} {if (rand() <= 0.001) print $0}' | head -n 1000 >> "$OUTPUT"

echo "Sample saved to $OUTPUT"
ls -lh "$OUTPUT"
wc -l "$OUTPUT"

