#!/bin/bash
#pipeline script — runs all steps for HouseTS PA3

set -e  # stop on first error

echo "1. Build edges.tsv"
bash scripts/make_edges.sh

echo "2. Filter significant clusters"
python3 scripts/filter_clusters_fast.py

echo "3. Generate histogram"
bash scripts/make_histogram.sh

echo "4. Top-30 tokens"
bash scripts/top_tokens.sh

echo "5. Visualize cluster"
python3 scripts/visualize_cluster.py

echo "6. Summary statistics"
python3 scripts/summary_stats.py

echo "===== Pipeline Done ====="

