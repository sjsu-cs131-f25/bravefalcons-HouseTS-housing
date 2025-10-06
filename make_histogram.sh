#!/bin/bash

echo "Computing histogram of cluster sizes ..."

mkdir -p out

# Compute cluster sizes (number of features per ZIP)
cut -f1 out/edges_thresholded.tsv | sort | uniq -c > out/cluster_sizes.tsv

# Use pandas to plot histogram safely
python3 << EOF
import pandas as pd
import matplotlib.pyplot as plt

# Read TSV; skip any non-numeric rows
df = pd.read_csv("out/cluster_sizes.tsv", sep='\s+', header=None, names=['count', 'zipcode'])

# Expand counts into a list of sizes
sizes = []
for _, row in df.iterrows():
    try:
        sizes.extend([int(row['zipcode'])] * int(row['count']))
    except:
        continue  # skip any bad rows

# Plot histogram
plt.hist(sizes, bins=range(min(sizes), max(sizes)+2), edgecolor='black')
plt.xlabel("Cluster Size (# of features)")
plt.ylabel("Number of Clusters")
plt.title("Histogram of Cluster Sizes")
plt.savefig("out/cluster_histogram.png")
EOF

echo "cluster_sizes.tsv and cluster_histogram.png created in out/"

