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

```csv
date,median_sale_price,median_list_price,median_ppsf,median_list_ppsf,homes_sold,pending_sales,new_listings,inventory,median_dom,avg_sale_to_list,sold_above_list
2014-12-31,177000.0,186200.0,102.9047,107.4369,98.0,101.0,90.0,92.0,55.0,0.9853,0.2143
2018-05-31,756050.0,799000.0,519.9378,523.9207,82.0,76.0,91.0,46.0,18.0,1.0359,0.5732
2018-10-31,362450.0,349900.0,306.3448,300.9706,72.0,71.0,86.0,54.0,45.0,0.9744,0.0556
2022-06-30,347500.0,314500.0,173.2069,173.1302,56.0,62.0,79.0,47.0,19.0,1.0151,0.5714
2018-01-31,139250.0,134900.0,94.4613,91.4127,72.0,69.0,51.0,96.0,113.0,0.9541,0.1250

## Grep No 'sale' Examples

date,median_sale_price,median_list_price,median_ppsf,median_list_ppsf,homes_sold,pending_sales,new_listings,inventory,median_dom,avg_sale_to_list,sold_above_list
2013-01-31,202000.0,331950.0,190.973,223.1820,19.0,22.0,20.0,21.0,91.0,0.9466,0.0
2017-09-30,150000.0,109000.0,67.5556,68.1250,5.0,5.0,1.0,1.0,105.5,0.9652,0.2
2013-02-28,115000.0,109900.0,89.8674,81.1952,45.0,61.0,40.0,43.0,52.0,0.9787,0.2667
2014-06-30,500000.0,527000.0,318.1818,327.5585,119.0,142.0,192.0,107.0,21.0,0.9894,0.2605
2023-02-28,295000.0,245000.0,230.0289,236.4249,10.0,9.0,7.0,2.0,57.0,1.0167,0.5


## Observations
- NY has the most records in the sample.
- 2017 and 2022 are the top years for records.
- Some zipcodes have multiple entries with varying average prices.
- The 'sale' vs 'no sale' grep examples show the diversity in the dataset.
