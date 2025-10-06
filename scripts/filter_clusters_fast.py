#!/usr/bin/env python3
import pandas as pd

print("Loading edges.tsv ...")
df = pd.read_csv("out/edges.tsv", sep="\t", header=None, names=["zipcode","feature"])

# Count number of features per ZIP
counts = df.groupby("zipcode").size().reset_index(name="count")
counts.to_csv("out/entity_counts.tsv", sep="\t", index=False)
print(" entity_counts.tsv created")

# Keep only ZIPs with >=10 features
keep = counts[counts["count"] >= 10]["zipcode"]
df_filtered = df[df["zipcode"].isin(keep)]
df_filtered.to_csv("out/edges_thresholded.tsv", sep="\t", index=False, header=False)
print("edges_thresholded.tsv created (threshold >=10)")

