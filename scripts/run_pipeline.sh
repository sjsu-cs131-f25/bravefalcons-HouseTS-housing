#!/bin/bash
# Master pipeline script — runs all steps for HouseTS PA3 (updated for speed)

set -e  # stop on first error

echo "===== STEP 1: Build edges.tsv ====="
bash scripts/make_edges.sh

echo "===== STEP 2: Filter significant clusters (FAST Python version) ====="
python3 scripts/filter_clusters_fast.py

echo "===== STEP 3: Generate histogram ====="
bash scripts/make_histogram.sh

echo "===== STEP 4: Top-30 tokens ====="
bash scripts/top_tokens.sh

echo "===== STEP 5: Visualize cluster ====="
python3 scripts/visualize_cluster.py

echo "===== STEP 6: Summary statistics ====="
python3 scripts/summary_stats.py

echo "===== PIPELINE COMPLETE ====="

