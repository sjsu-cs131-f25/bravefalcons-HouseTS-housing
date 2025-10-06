#!/bin/bash
# Step 1 — Build edges.tsv for HouseTS

mkdir -p out

echo "Building edges.tsv from HouseTS.csv ..."

# Left entity = zipcode
# Right entities = feature columns (parks, schools, income, etc.)

awk -F',' '
NR==1 {
  for (i=1; i<=NF; i++) header[i]=$i; 
  next
}
{
  zip=$15   # zipcode is the 15th column
  for (i=1; i<=NF; i++) {
    # skip the zipcode and date columns, focus on feature columns
    if (i != 1 && i != 15 && i != 14 && i != 16 && $i != "" && $i != "NA" && $i != "null") {
      print zip "\t" header[i]
    }
  }
}' data/archive/HouseTS.csv | sort -k1,1 > out/edges.tsv

echo "edges.tsv created in out/"

