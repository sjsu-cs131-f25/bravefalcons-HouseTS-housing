#!/bin/bash

mkdir -p out

echo "Computing histogram of cluster sizes ..."

# Create cluster_sizes.tsv → each line: cluster_size <tab> number_of_clusters
cut -f2 out/entity_counts.tsv | sort -n | uniq -c | awk '{print $2 "\t" $1}' > out/cluster_sizes.tsv

echo " cluster_sizes.tsv created."

# plot using Python + Matplotlib
python3 - <<'EOF'
import matplotlib.pyplot as plt

sizes = []
with open("out/cluster_sizes.tsv") as f:
    for line in f:
        parts = line.strip().split("\t")
        if len(parts) == 2:
            size = int(parts[0])
            count = int(parts[1])
            sizes += [size] * count

plt.hist(sizes, bins=range(min(sizes), max(sizes)+2), edgecolor='black')
plt.xlabel("Cluster Size (# of features per ZIP)")
plt.ylabel("Number of Clusters (ZIPs)")
plt.title("Histogram of Cluster Sizes - HouseTS Dataset")
plt.tight_layout()
plt.savefig("out/cluster_histogram.png")
EOF

echo "cluster_histogram.png created in out/"

