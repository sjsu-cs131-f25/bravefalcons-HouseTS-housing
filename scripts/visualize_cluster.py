#!/usr/bin/env python3
import networkx as nx
import matplotlib.pyplot as plt
import random

# Load edges
edges_file = "out/edges_thresholded.tsv"
edges = [line.strip().split("\t") for line in open(edges_file) if "\t" in line]

# Choose one random ZIP cluster
clusters = {}
for left, right in edges:
    clusters.setdefault(left, []).append(right)

sample_zip = random.choice(list(clusters.keys()))
sample_edges = [(sample_zip, f) for f in clusters[sample_zip]]

print(f"Visualizing cluster for ZIP: {sample_zip} ({len(sample_edges)} features)")

# Build graph
G = nx.Graph()
G.add_edges_from(sample_edges)

plt.figure(figsize=(8,8))
nx.draw_networkx(
    G,
    node_size=500,
    with_labels=True,
    font_size=8,
    node_color="lightblue",
    edge_color="gray"
)
plt.title(f"Cluster Visualization for ZIP {sample_zip}")
plt.axis("off")
plt.tight_layout()
plt.savefig("out/cluster_viz.png")
print("cluster_viz.png saved in out/")

