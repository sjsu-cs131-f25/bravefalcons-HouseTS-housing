#!/usr/bin/env python3
import pandas as pd

print("Loading dataset...")
df = pd.read_csv("data/archive/HouseTS.csv")

# Only keep necessary columns
cols = ["zipcode", "median_sale_price"]
df = df[cols].dropna()

# Compute summary stats
summary = (
    df.groupby("zipcode")["median_sale_price"]
    .agg(["count", "mean", "median"])
    .reset_index()
    .sort_values("count", ascending=False)
)

# Save to TSV
summary.to_csv("out/cluster_outcomes.tsv", sep="\t", index=False)

print("cluster_outcomes.tsv created in out/")

