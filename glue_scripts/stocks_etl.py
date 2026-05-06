"""
Glue ETL: read raw Yahoo Finance chart JSON from S3 and write a tidy
stock prices table in Parquet, partitioned by ticker and year.

Expected raw structure (per file):
  chart.result[0].meta.symbol
  chart.result[0].timestamp                          (array of unix seconds)
  chart.result[0].indicators.quote[0].open/high/low/close/volume   (arrays)
  chart.result[0].indicators.adjclose[0].adjclose                  (array)

Job arguments:
  --raw_path       s3://bucket/raw/yahoo_finance/
  --curated_path   s3://bucket/curated/stocks/
"""

import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import (
    arrays_zip,
    col,
    explode,
    from_unixtime,
    to_date,
    year,
)

ARGS = getResolvedOptions(sys.argv, ["JOB_NAME", "raw_path", "curated_path"])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(ARGS["JOB_NAME"], ARGS)

raw_df = spark.read.json(ARGS["raw_path"])

# Each input file has chart.result as a single-element array — flatten it.
result_df = raw_df.select(explode(col("chart.result")).alias("r"))

# Pull the symbol, the timestamp array and the parallel arrays of OHLCV + adjclose.
flat = result_df.select(
    col("r.meta.symbol").alias("ticker"),
    col("r.timestamp").alias("ts_arr"),
    col("r.indicators.quote")[0].alias("q"),
    col("r.indicators.adjclose")[0].alias("ac"),
)

# Zip the arrays so each timestamp is paired with its OHLCV + adj_close.
zipped = flat.select(
    "ticker",
    explode(
        arrays_zip(
            col("ts_arr").alias("ts"),
            col("q.open").alias("open"),
            col("q.high").alias("high"),
            col("q.low").alias("low"),
            col("q.close").alias("close"),
            col("q.volume").alias("volume"),
            col("ac.adjclose").alias("adj_close"),
        )
    ).alias("z"),
)

final = (
    zipped.select(
        col("ticker"),
        to_date(from_unixtime(col("z.ts"))).alias("date"),
        col("z.open").cast("double").alias("open"),
        col("z.high").cast("double").alias("high"),
        col("z.low").cast("double").alias("low"),
        col("z.close").cast("double").alias("close"),
        col("z.volume").cast("bigint").alias("volume"),
        col("z.adj_close").cast("double").alias("adj_close"),
    )
    .filter(col("date").isNotNull())
    .dropDuplicates(["ticker", "date"])
    .withColumn("year", year(col("date")))
)

(
    final.write.mode("overwrite")
    .partitionBy("ticker", "year")
    .parquet(ARGS["curated_path"])
)

job.commit()
