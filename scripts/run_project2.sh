#!/usr/bin/env bash
# Project 2 entry script
# Usage: ./scripts/run_project2.sh data/archive/HouseTS.csv 1000

set -euo pipefail

DATA_PATH="$1"
SAMPLE_SIZE="$2"

mkdir -p data/samples out

echo "Creating sample..."

# Header first
head -n1 "$DATA_PATH" > data/samples/sample.csv

# Try random sample, fallback to head
if command -v shuf >/dev/null 2>&1; then
    tail -n +2 "$DATA_PATH" | shuf -n "$SAMPLE_SIZE" >> data/samples/sample.csv
else
    echo " 'shuf' not found, using head instead (non-random sample)."
    tail -n +2 "$DATA_PATH" | head -n "$SAMPLE_SIZE" >> data/samples/sample.csv
fi

echo "Generating frequency tables..."

# City frequency
cut -d',' -f4 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr \
    | tee out/freq_city.txt

# Year frequency
cut -d',' -f3 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr \
    | tee out/freq_years.txt

# Zip frequency
cut -d',' -f2 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr \
    | tee out/freq_zip.txt

echo "Creating Top-N table..."
head -n 20 out/freq_zip.txt > out/top_zipcode.txt

echo "Creating skinny table (zip, city, price)..."
cut -d',' -f2,4,5 data/samples/sample.csv | tee out/skinny_zip_city_price.csv >/dev/null

echo "Running grep examples..."
# Case-insensitive search for 'new york'
grep -i "new york" data/samples/sample.csv > out/ny_rows.txt
# Exclude rows with 'new york'
grep -v "new york" data/samples/sample.csv > out/not_ny_rows.txt

echo "Capturing errors (if any)..."
ls does_not_exist &> out/errors.log || true

echo "All steps complete "
