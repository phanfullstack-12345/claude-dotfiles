# Reference: data-engineering-guide
# Load this file when working on tasks matching this domain.

## 📊 Data Engineering

### Core Concepts
- **ELT over ETL**: load raw data first, transform in warehouse — cheaper, more flexible.
- **Idempotency**: every pipeline run must be safe to re-run — no duplicates, no data loss.
- **Immutable raw layer**: never modify raw/bronze data — always re-derive from source.
- **Data contracts**: agree on schema + SLA with data producers before building pipelines.
- **Lineage**: track where data came from and how it was transformed — essential for debugging.

### Data Architecture Layers (Medallion)
```
Bronze (Raw)    → Exact copy of source data, immutable, partitioned by ingest date
Silver (Clean)  → Validated, deduplicated, typed, standardized schemas
Gold (Curated)  → Business-ready aggregates, denormalized for query performance
```

### Pipeline Orchestration

#### Apache Airflow
```python
from airflow.decorators import dag, task
from datetime import datetime, timedelta

@dag(
    schedule="0 2 * * *",           # 2am daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={"retries": 3, "retry_delay": timedelta(minutes=5)},
    tags=["orders", "daily"],
)
def orders_pipeline():
    @task()
    def extract() -> list[dict]:
        return fetch_orders_from_api()

    @task()
    def transform(raw: list[dict]) -> list[dict]:
        return [clean_order(o) for o in raw]

    @task()
    def load(clean: list[dict]):
        bulk_insert_to_warehouse(clean)

    load(transform(extract()))

orders_pipeline()
```

- Use `@task` decorator (TaskFlow API) — cleaner than classic Operators.
- **Sensors**: wait for S3 file, DB condition, external DAG completion.
- Set `catchup=False` for most pipelines — re-runs of missed intervals cause data duplication.
- Use `pool` to limit concurrent DB connections.
- XCom for small values only (<48KB) — large data passes through storage (S3/GCS).

#### Prefect / Dagster (Modern Alternatives)
```python
# Prefect 2 — Python-native, no YAML
from prefect import flow, task

@task(retries=3, cache_key_fn=task_input_hash)
def extract_orders(date: str) -> list:
    return fetch(date)

@flow(name="orders-daily")
def orders_flow(date: str = "today"):
    raw = extract_orders(date)
    clean = transform(raw)
    load(clean)
```

### Data Transformation — dbt

```sql
-- models/orders/orders_daily.sql
{{ config(materialized='incremental', unique_key='order_date') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
    {% if is_incremental() %}
    WHERE created_at >= (SELECT MAX(order_date) FROM {{ this }})
    {% endif %}
),
transformed AS (
    SELECT
        DATE(created_at)        AS order_date,
        COUNT(*)                AS total_orders,
        SUM(amount)             AS revenue,
        COUNT(DISTINCT user_id) AS unique_customers
    FROM source
    GROUP BY 1
)
SELECT * FROM transformed
```

```bash
dbt run --select orders/        # run orders models
dbt test --select orders/       # test data quality
dbt docs generate && dbt docs serve   # auto-generated lineage docs
```

- **Materialization**: `table` (full refresh), `incremental` (append/merge new rows), `view` (no storage).
- **Sources**: define upstream tables; dbt tracks freshness with `dbt source freshness`.
- **Tests**: `unique`, `not_null`, `accepted_values`, `relationships` — run in CI.
- **Packages**: `dbt-utils`, `dbt-expectations` for extra test macros.

### Streaming Data

#### Apache Kafka (Producer/Consumer)
```python
# Producer
from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "kafka:9092"})
producer.produce(
    topic="orders",
    key=order_id.encode(),
    value=json.dumps(order).encode(),
    callback=delivery_report
)
producer.flush()

# Consumer (idempotent processing)
consumer = Consumer({
    "bootstrap.servers": "kafka:9092",
    "group.id": "order-processor",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,       # manual commit after processing
})
consumer.subscribe(["orders"])
while True:
    msg = consumer.poll(1.0)
    if msg and not msg.error():
        process(msg.value())
        consumer.commit()              # only commit after successful process
```

#### Apache Flink / Spark Streaming
```python
# PySpark Structured Streaming
from pyspark.sql import SparkSession
from pyspark.sql.functions import window, count

spark = SparkSession.builder.getOrCreate()

orders = (spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", "kafka:9092")
    .option("subscribe", "orders")
    .load())

windowed = (orders
    .withWatermark("timestamp", "10 minutes")   # late data tolerance
    .groupBy(window("timestamp", "5 minutes"), "product_id")
    .agg(count("*").alias("order_count")))

query = (windowed.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/checkpoints/orders")
    .start())
```

### Data Warehouse Patterns

#### Star Schema
```sql
-- Fact table: large, append-only, foreign keys
CREATE TABLE fact_orders (
    order_id        BIGINT,
    order_date_key  INT REFERENCES dim_date(date_key),
    customer_key    INT REFERENCES dim_customer(customer_key),
    product_key     INT REFERENCES dim_product(product_key),
    quantity        INT,
    revenue         DECIMAL(10,2)
);

-- Dimension: descriptive, slowly changing (SCD)
CREATE TABLE dim_customer (
    customer_key  SERIAL PRIMARY KEY,
    customer_id   VARCHAR,
    name          VARCHAR,
    segment       VARCHAR,
    valid_from    DATE,
    valid_to      DATE,   -- SCD Type 2: track history
    is_current    BOOLEAN
);
```

#### BigQuery / Snowflake Best Practices
```sql
-- BigQuery: partition + cluster for cost/performance
CREATE TABLE orders_partitioned
PARTITION BY DATE(created_at)
CLUSTER BY customer_id, status
AS SELECT * FROM raw_orders;

-- Avoid SELECT * — only select needed columns (columnar storage)
SELECT customer_id, SUM(revenue) FROM orders_partitioned
WHERE DATE(created_at) BETWEEN '2024-01-01' AND '2024-01-31'  -- partition pruning
GROUP BY 1;
```

### Data Quality & Testing
```python
# Great Expectations
import great_expectations as gx

context = gx.get_context()
suite = context.add_expectation_suite("orders_suite")

validator = context.get_validator(batch_request=batch_request, expectation_suite=suite)
validator.expect_column_values_to_not_be_null("order_id")
validator.expect_column_values_to_be_between("amount", min_value=0, max_value=100000)
validator.expect_column_pair_values_A_to_be_greater_than_B("delivered_at", "ordered_at")
validator.save_expectation_suite()
results = validator.validate()
```

### Feature Store (ML Engineering)
```python
# Feast feature store
from feast import FeatureStore

store = FeatureStore(repo_path=".")

# Retrieve features for training
training_df = store.get_historical_features(
    entity_df=entity_df,
    features=["user_stats:lifetime_value", "user_stats:order_count"]
).to_df()

# Real-time retrieval for inference
features = store.get_online_features(
    features=["user_stats:lifetime_value"],
    entity_rows=[{"user_id": 123}]
).to_dict()
```

---

