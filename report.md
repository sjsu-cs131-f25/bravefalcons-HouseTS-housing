# HouseTS Project 2 Summary

**Objective:** Process HouseTS dataset to create samples, frequency tables, skinny tables, and grep examples for analysis.  

**Date:** 2025-09-23  
---

## Summary of Sample

- Sample size: **1001 lines**  
- Source file: `data/archive/HouseTS.csv`  
- Sample file: `data/samples/sample.csv`  

---

## Top Cities in Sample

| City | Count |
|------|-------|
| NY   | 134   |
| DC   | 61    |
| PGH  | 58    |
| CHI  | 58    |
| BOS  | 56    |

---

## Top Years in Sample

| Year | Count |
|------|-------|
| 2017 | 98    |
| 2022 | 97    |
| 2020 | 91    |
| 2015 | 91    |
| 2023 | 88    |

---

## Top Zipcodes in Sample

| Zipcode | Count |
|---------|-------|
| 98146   | 3     |
| 94965   | 3     |
| 91316   | 3     |
| 63116   | 3     |
| 55109   | 3     |

---

## Skinny Table Sample (zipcode, city, price)

| City | Zipcode | Avg Price |
|------|---------|-----------|
| ATL  | 30019   | 404986.62 |
| ATL  | 30030   | 503734.27 |
| ATL  | 30041   | 326766.06 |
| ATL  | 30056   | 205663.02 |
| ATL  | 30093   | 305556.88 |

---

## Grep 'sale' Example

| Date       | Median Sale Price | Median List Price | Median PPSF | Median List PPSF | Homes Sold | Pending Sales | New Listings |
|------------|------------------:|------------------:|-------------:|------------------:|-----------:|---------------:|-------------:|
| 2014-12-31 | 177000.0          | 182000.0          | 102.9        | 107.4             | 369.0      | 98.0           | 101.0        |
| 2018-05-31 | 765684.0          | 799000.0          | 519.9        | 537.8             | 522.0      | 87.0           | 91.0         |
| 2022-08-30 | 347500.0          | 314580.0          | 173.3        | 173.1             | 362.0      | 62.0           | 79.0         |

## Grep No 'sale' Examples

| Date       | Median Sale Price | Median List Price | Median PPSF | Median List PPSF | Homes Sold | Pending Sales | New Listings |
|------------|------------------:|------------------:|-------------:|------------------:|-----------:|---------------:|-------------:|
| 2013-01-31 | 202000.0          | 213950.0          | 109.7        | 113.2             | 182.0      | 19.0           | 22.0         |
| 2017-09-30 | 150000.0          | 160000.0          | 85.6         | 88.1              | 62.0       | 5.0            | 5.0          |
| 2022-08-30 | 115000.0          | 109000.0          | 87.8         | 87.4              | 152.0      | 45.0           | 61.0         |


## Observations
- NY has the most records in the sample.
- 2017 and 2022 are the top years for records.
- Some zipcodes have multiple entries with varying average prices.
- The 'sale' vs 'no sale' grep examples show the diversity in the dataset.

## Limitations
- The dataset has missing or sparse values for some years/zipcodes.  
- Aggregating by averages hides variation within cities and zipcodes.  
- The frequency tables and skinny table are built from a sample, not the full dataset, so they may not represent the entire population.  
