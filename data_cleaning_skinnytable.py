from pyspark.sql import SparkSession, functions as F

spark = (
    SparkSession.builder
    .appName("DataPrep_Sprint_Housing")
    .config("spark.sql.shuffle.partitions", "64")
    .config("spark.driver.memory", "4g")
    .getOrCreate()
)

RAW = "data.csv"
df = (spark.read
      .option("header", True)
      .option("inferSchema", True)
      .csv(RAW))

print("Rows (raw):", df.count())
df.printSchema()

for c in df.columns:
    df = df.withColumnRenamed(c, c.strip().lower().replace(" ", "_"))

if "date" in df.columns:
    df = df.withColumn("date", F.to_date("date"))

if "zipcode" in df.columns:
    df = df.withColumn("zipcode", F.regexp_replace(F.col("zipcode").cast("string"), "[^0-9]", ""))
    df = df.withColumn("zipcode", F.when(F.length("zipcode") >= 5, F.substring("zipcode", 1, 5))
                                .otherwise(F.lpad("zipcode", 5, "0")))

numeric_cols = [
    "median_sale_price","median_list_price","median_ppsf","median_list_ppsf",
    "homes_sold","pending_sales","new_listings","inventory","median_dom",
    "avg_sale_to_list","sold_above_list","off_market_in_two_weeks",
    "year","bank","bus","hospital","mall","park","restaurant","school","station",
    "supermarket","total_population","median_age","per_capita_income",
    "total_families_below_poverty","total_housing_units","median_rent",
    "median_home_value","total_labor_force","unemployed_population",
    "total_school_age_population","total_school_enrollment","median_commute_time",
    "price"
]

for c in numeric_cols:
    if c in df.columns:
        df = df.withColumn(c, F.col(c).cast("double"))

required = [c for c in ["date", "city", "zipcode"] if c in df.columns]
n0 = df.count()
df = df.dropna(subset=required)
n_after_keys = df.count()
print(f"Dropped for missing keys ({required}): {n0 - n_after_keys}")

nonneg_cols = [c for c in numeric_cols if c in df.columns]
cond = F.lit(True)
for c in nonneg_cols:
    cond = cond & (F.col(c).isNull() | (F.col(c) >= 0))

if "median_dom" in df.columns:
    df = df.withColumn("median_dom", F.when(F.col("median_dom") > 0, F.col("median_dom")))

price_col = "median_sale_price" if "median_sale_price" in df.columns else ("price" if "price" in df.columns else None)
if price_col:
    cond = cond & (F.col(price_col).isNotNull()) & (F.col(price_col) > 0)

n1 = df.count()
df = df.filter(cond)
n2 = df.count()
print(f"Dropped for invalid values: {n1 - n2}")

keep_cols = []
for c in ["date","year","city","city_full","zipcode"]:
    if c in df.columns: keep_cols.append(c)

metric_cols = [c for c in [
    "median_sale_price","median_list_price","median_ppsf","homes_sold",
    "pending_sales","new_listings","inventory","median_dom","avg_sale_to_list",
    "sold_above_list","off_market_in_two_weeks"
] if c in df.columns]

skinny = df.select(*(keep_cols + metric_cols))

if "date" in skinny.columns:
    skinny = skinny.withColumn("year_month", F.date_format("date", "yyyy-MM"))

print("Skinny schema:")
skinny.printSchema()
print("Skinny sample:")
skinny.show(10, truncate=False)

skinny.write.mode("overwrite").parquet("skinny_table.parquet")
print("Wrote skinny_table.parquet")

spark.stop()

