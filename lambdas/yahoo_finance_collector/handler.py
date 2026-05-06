"""
Lambda handler that collects historical stock prices from Yahoo Finance
public chart endpoint and writes raw JSON to S3, partitioned by date.

No third-party dependencies — uses only the Python standard library plus
boto3 (provided by the Lambda runtime).
"""

import json
import logging
import os
import urllib.error
import urllib.request
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3 = boto3.client("s3")

DATA_BUCKET = os.environ["DATA_BUCKET"]
DATA_PREFIX = os.environ.get("DATA_PREFIX", "raw/yahoo_finance")
TICKERS = [t.strip() for t in os.environ.get("TICKERS", "AAPL,MSFT,GOOGL").split(",") if t.strip()]
DATA_RANGE = os.environ.get("DATA_RANGE", "5d")
INTERVAL = os.environ.get("INTERVAL", "1d")

YAHOO_URL = (
    "https://query1.finance.yahoo.com/v8/finance/chart/{ticker}"
    "?interval={interval}&range={range}"
)
USER_AGENT = "Mozilla/5.0 (compatible; terraform-aws-data-platform/1.0)"


def fetch_chart(ticker: str) -> dict:
    url = YAHOO_URL.format(ticker=ticker, interval=INTERVAL, range=DATA_RANGE)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def write_to_s3(ticker: str, payload: dict, run_date: str) -> str:
    key = f"{DATA_PREFIX}/dt={run_date}/{ticker}.json"
    S3.put_object(
        Bucket=DATA_BUCKET,
        Key=key,
        Body=json.dumps(payload).encode("utf-8"),
        ContentType="application/json",
    )
    return key


def lambda_handler(event, context):  # noqa: ARG001 - signature required by AWS
    run_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    written: list[str] = []
    failed: list[dict] = []

    for ticker in TICKERS:
        try:
            data = fetch_chart(ticker)
            key = write_to_s3(ticker, data, run_date)
            written.append(key)
            logger.info("ok ticker=%s key=%s", ticker, key)
        except (urllib.error.URLError, json.JSONDecodeError, KeyError) as exc:
            logger.exception("failed ticker=%s", ticker)
            failed.append({"ticker": ticker, "error": str(exc)})

    return {
        "run_date": run_date,
        "written": written,
        "failed": failed,
        "success_count": len(written),
        "failure_count": len(failed),
    }
