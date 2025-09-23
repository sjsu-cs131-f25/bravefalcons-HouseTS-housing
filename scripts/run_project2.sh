#!/usr/bin/env bash
# run_project2.sh - macOS-ready updated version
# Usage: ./scripts/run_project2.sh <dataset_path> <delimiter> <sample_size>
# Example: ./scripts/run_project2.sh data/archive/HouseTS.csv , 1000

set -euo pipefail

# Parameters & Defaults
DATA_PATH=${1:-"data/archive/HouseTS.csv"}
DELIM=${2:-","}
SAMPLE_SIZE=${3:-1000}

# Prepare directories
mkdir -p data/samples out


# 1: Create sample

echo "Creating 1k sample..."
head -n1 "$DATA_PATH" > data/samples/sample.csv

if command -v gshuf >/dev/null 2>&1; then
    tail -n +2 "$DATA_PATH" | gshuf -n "$SAMPLE_SIZE" >> data/samples/sample.csv
elif command -v shuf >/dev/null 2>&1; then
    tail -n +2 "$DATA_PATH" | shuf -n "$SAMPLE_SIZE" >> data/samples/sample.csv
else
    echo " 'shuf' or 'gshuf' not found, using head instead (non-random sample)."
    tail -n +2 "$DATA_PATH" | head -n "$SAMPLE_SIZE" >> data/samples/sample.csv
fi

echo "Sample created: $(wc -l < data/samples/sample.csv) lines"


# 2: Frequency tables

echo "Creating frequency of cities..."
cut -d"$DELIM" -f14 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr | tee out/freq_city.txt > /dev/null

echo "Creating frequency of years..."
cut -d"$DELIM" -f16 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr | tee out/freq_years.txt > /dev/null

echo "Creating frequency of zipcodes..."
cut -d"$DELIM" -f15 data/samples/sample.csv | tail -n +2 | sort | uniq -c | sort -nr | tee out/freq_zipcode.txt > /dev/null

echo "Saving top 20 zipcodes..."
head -n 20 out/freq_zipcode.txt | tee out/top_zipcode.txt > /dev/null

# 3: Skinny table

echo "Creating skinny table (zipcode, city, price)..."
cut -d"$DELIM" -f15,14,38 data/samples/sample.csv | sort -u | head -n 100 | tee out/skinny_zip_city_price.csv > /dev/null


# 4: Grep examples

echo "Searching for rows with 'sale'..."
grep -i "sale" data/samples/sample.csv > out/grep_sale_examples.txt 2> out/grep_sale_errors.txt

echo "Searching for rows without 'sale'..."
grep -vi "sale" data/samples/sample.csv > out/grep_no_sale_examples.txt 2>> out/grep_sale_errors.txt


# 5: Session log
echo "Capturing session log..."
script -q out/project2_session.txt <<EOF
head -n 5 data/samples/sample.csv
wc -l data/samples/sample.csv
head -n 10 out/freq_city.txt
head -n 10 out/freq_years.txt
head -n 10 out/freq_zipcode.txt
head -n 5 out/top_zipcode.txt
head -n 5 out/skinny_zip_city_price.csv
head -n 5 out/grep_sale_examples.txt
head -n 5 out/grep_no_sale_examples.txt
EOF


# 6: Verification summary
echo
echo "Verification Summary:"
echo "Sample lines: $(wc -l < data/samples/sample.csv)"
echo "Top cities (sample):"
head -n 5 out/freq_city.txt
echo
echo "Top years (sample):"
head -n 5 out/freq_years.txt
echo
echo "Top zipcodes (sample):"
head -n 5 out/top_zipcode.txt
echo
echo "Skinny table (sample):"
head -n 5 out/skinny_zip_city_price.csv
echo
echo "Grep 'sale' examples:"
head -n 3 out/grep_sale_examples.txt
echo
echo "Grep no 'sale' examples:"
head -n 3 out/grep_no_sale_examples.txt
echo
echo "Session log saved to out/project2_session.txt"
echo "All outputs saved in out/"

