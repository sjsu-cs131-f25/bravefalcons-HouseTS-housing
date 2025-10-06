#!/bin/bash
# Step 2 — Filter significant clusters (HouseTS)

mkdir -p out

echo "Counting features per ZIP ..."

# Count number of edges (features) for each ZIP
cut -f1 out/edges.tsv | sort | uniq -c | awk '{print $2 "\t" $1}' | sort -k2,2nr > out/entity_counts.tsv

echo "entity_counts.tsv created."

# Filter threshold: ZIPs with >= 10 features
THRESHOLD=10
echo "Filtering ZIPs with >= $THRESHOLD features ..."

awk -v t=$THRESHOLD '$2 >= t {print $1}' out/entity_counts.tsv > out/keep_zips.txt

# Keep only edges where left entity (ZIP) is in keep_zips.txt
grep -Fwf out/keep_zips.txt out/edges.tsv > out/edges_thresholded.tsv

echo "edges_thresholded.tsv created with threshold $THRESHOLD"

