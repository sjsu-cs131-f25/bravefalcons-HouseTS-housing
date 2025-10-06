#!/bin/bash
# Step 4 — Top-30 frequent tokens inside clusters vs overall

mkdir -p out

echo "Computing Top-30 tokens inside clusters..."

# Count frequency of each feature in thresholded edges
cut -f2 out/edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 | awk '{print $2}' > out/top30_clusters.txt
echo " top30_clusters.txt created."

echo "Computing Top-30 overall tokens..."
cut -f2 out/edges.tsv | sort | uniq -c | sort -nr | head -30 | awk '{print $2}' > out/top30_overall.txt
echo "top30_overall.txt created."

echo "Comparing differences..."
grep -Fxv -f out/top30_overall.txt out/top30_clusters.txt > out/diff_top30.txt || true
echo "diff_top30.txt created."

