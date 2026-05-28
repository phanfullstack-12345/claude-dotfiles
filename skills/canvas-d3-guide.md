# Reference: canvas-d3-guide
# Load this file when working on tasks matching this domain.

## 🎨 Canvas API (HTML5)

### Setup & Context
- Always check context availability before using:
```js
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
if (!ctx) throw new Error("Canvas 2D context not supported");
```
- Set canvas dimensions via JS properties, not CSS (CSS scales, JS sets actual pixel buffer):
```js
canvas.width = 800;   // actual pixel buffer
canvas.height = 600;
// CSS can scale the display size separately
```
- For sharp rendering on HiDPI/Retina screens:
```js
const dpr = window.devicePixelRatio ?? 1;
canvas.width = width * dpr;
canvas.height = height * dpr;
canvas.style.width = `${width}px`;
canvas.style.height = `${height}px`;
ctx.scale(dpr, dpr);
```

### Drawing Patterns
- Always `ctx.save()` before changing state; `ctx.restore()` after — never leave dirty state.
- Draw order matters: background → midground → foreground (painter's algorithm).
- Batch similar draw calls — minimize state changes (fillStyle, strokeStyle, font) between draws.
- Use `ctx.beginPath()` before every new path — forgetting it accumulates paths silently.
- `ctx.clearRect(0, 0, canvas.width, canvas.height)` to clear before each animation frame.

```js
// ✅ Correct pattern
ctx.save();
ctx.fillStyle = "#ff6b6b";
ctx.beginPath();
ctx.arc(x, y, radius, 0, Math.PI * 2);
ctx.fill();
ctx.restore();
```

### Animation Loop
- Always use `requestAnimationFrame` — never `setInterval` for animation.
- Store the frame ID to cancel on cleanup.
- Calculate delta time for frame-rate-independent movement.

```js
let frameId;
let lastTime = 0;

function animate(timestamp) {
  const delta = timestamp - lastTime;
  lastTime = timestamp;

  ctx.clearRect(0, 0, canvas.width, canvas.height);
  update(delta);   // move things
  draw();          // draw things

  frameId = requestAnimationFrame(animate);
}

frameId = requestAnimationFrame(animate);

// Cleanup
cancelAnimationFrame(frameId);
```

### Performance
- Use `OffscreenCanvas` for heavy rendering in Web Workers.
- Cache expensive paths: pre-draw static elements to an offscreen canvas, blit with `drawImage`.
- Avoid reading pixels (`getImageData`) in hot loops — it forces GPU→CPU sync and stalls rendering.
- Group fills/strokes of the same color — each state change has overhead.
- Use integer coordinates for pixel-snapped drawing (no sub-pixel blur on straight lines).
- `ctx.imageSmoothingEnabled = false` for pixel art / sharp image scaling.

### Text
```js
ctx.font = "bold 16px 'Inter', sans-serif";
ctx.textAlign = "center";    // left | right | center | start | end
ctx.textBaseline = "middle"; // top | hanging | middle | alphabetic | bottom
ctx.fillText("Hello", x, y);

// Measure before draw
const metrics = ctx.measureText("Hello");
const textWidth = metrics.width;
```

### Hit Detection
- Use `ctx.isPointInPath(path, x, y)` for shape hit testing.
- For complex scenes: maintain a logical model of objects with bounding boxes; test mouse coords against model, not canvas pixels.

---

## 📊 D3.js (v7+)

### Core Philosophy
- D3 is **not a chart library** — it's a data transformation + DOM binding toolkit. Think in data joins, not draw calls.
- D3 manipulates SVG, Canvas, or HTML — choose SVG for interactive/zoomable charts; Canvas for 10k+ data points.
- D3 = **Data → DOM** mapping via selections and joins. Master this mental model first.

### Setup
```js
import * as d3 from "d3";              // full library
import { select, scaleLinear } from "d3"; // tree-shakeable imports (preferred)
```
- D3 v7 is fully modular — import only what you need to keep bundle small.
- Use `d3@7` — not v5/v6; API changed significantly.

### The Data Join Pattern (Core Mental Model)
```js
// The fundamental D3 pattern: select → data → join → enter/update/exit
const circles = svg
  .selectAll("circle")           // select (even if empty)
  .data(dataset, d => d.id)      // bind data, key by id for stable joins
  .join(
    enter => enter.append("circle")   // new data points
      .attr("r", 0)
      .call(enter => enter.transition().attr("r", d => scale(d.value))),
    update => update                   // existing data points
      .call(update => update.transition().attr("cx", d => xScale(d.x))),
    exit => exit                       // removed data points
      .call(exit => exit.transition().attr("r", 0).remove())
  );
```
- Always provide a **key function** to `.data()` for stable element identity during updates.
- Use `.join()` (v5+) over `.enter()` / `.exit()` — cleaner and handles all three cases.

### Scales
```js
// Linear scale — continuous numeric
const xScale = d3.scaleLinear()
  .domain([0, d3.max(data, d => d.value)])  // input range
  .range([margin.left, width - margin.right]) // output range
  .nice(); // round domain to nice values

// Band scale — categorical (bar charts)
const yScale = d3.scaleBand()
  .domain(data.map(d => d.category))
  .range([margin.top, height - margin.bottom])
  .padding(0.2);

// Time scale
const timeScale = d3.scaleTime()
  .domain(d3.extent(data, d => d.date))
  .range([0, width]);

// Color scales
const colorScale = d3.scaleOrdinal(d3.schemeTableau10);
const sequentialColor = d3.scaleSequential(d3.interpolateViridis).domain([0, 100]);
```

### Axes
```js
// Always render axes into a <g> element
const xAxis = d3.axisBottom(xScale)
  .ticks(6)
  .tickFormat(d => d3.format(".2s")(d)); // SI prefix: 1.2k, 3.4M

svg.append("g")
  .attr("class", "x-axis")
  .attr("transform", `translate(0, ${height - margin.bottom})`)
  .call(xAxis)
  .call(g => g.select(".domain").remove()) // remove axis line if desired
  .call(g => g.selectAll(".tick line").attr("stroke", "#ccc"));
```

### Transitions & Animation
```js
// Chain transitions for smooth updates
selection
  .transition()
  .duration(500)
  .ease(d3.easeCubicOut)
  .attr("cx", d => xScale(d.x))
  .attr("cy", d => yScale(d.y));

// Staggered entrance
selection
  .transition()
  .delay((d, i) => i * 50) // stagger by index
  .duration(300)
  .attr("opacity", 1);
```

### Interactivity
```js
// Tooltip pattern
const tooltip = d3.select("body").append("div")
  .attr("class", "tooltip")
  .style("opacity", 0)
  .style("position", "absolute")
  .style("pointer-events", "none");

selection
  .on("mouseover", (event, d) => {
    tooltip.transition().duration(200).style("opacity", 1);
    tooltip.html(`<strong>${d.name}</strong>: ${d.value}`)
      .style("left", `${event.pageX + 12}px`)
      .style("top", `${event.pageY - 28}px`);
  })
  .on("mouseout", () => tooltip.transition().duration(300).style("opacity", 0));

// Zoom & Pan
const zoom = d3.zoom()
  .scaleExtent([0.5, 10])
  .on("zoom", (event) => {
    g.attr("transform", event.transform);
  });
svg.call(zoom);
```

### Responsive Charts
```js
// Use ResizeObserver to redraw on container resize
const container = document.getElementById("chart");
const ro = new ResizeObserver(entries => {
  const { width } = entries[0].contentRect;
  redraw(width); // recalculate scales, re-render
});
ro.observe(container);

// Or viewBox approach — scales automatically with CSS
svg.attr("viewBox", `0 0 ${width} ${height}`)
   .attr("preserveAspectRatio", "xMidYMid meet")
   .style("width", "100%")
   .style("height", "auto");
```

### D3 + React Integration
```tsx
// Approach 1: D3 for math, React for DOM (preferred in React projects)
function BarChart({ data }) {
  const xScale = d3.scaleLinear().domain([0, d3.max(data, d => d.value)]).range([0, width]);
  return (
    <svg width={width} height={height}>
      {data.map(d => (
        <rect key={d.id} x={0} y={yScale(d.name)} width={xScale(d.value)} height={yScale.bandwidth()} />
      ))}
    </svg>
  );
}

// Approach 2: D3 owns the DOM — use useRef, run D3 in useEffect
function D3Chart({ data }) {
  const svgRef = useRef(null);
  useEffect(() => {
    const svg = d3.select(svgRef.current);
    // ... full D3 imperative code here
    return () => svg.selectAll("*").remove(); // cleanup
  }, [data]);
  return <svg ref={svgRef} />;
}
```
- Prefer Approach 1 in React — let React own the DOM; use D3 only for scales, shapes, and math.
- Use Approach 2 only for complex D3 graphs (force layouts, geographic projections, zoomable trees) where D3 DOM control is essential.

### Common Patterns
```js
// Line chart path
const line = d3.line()
  .x(d => xScale(d.date))
  .y(d => yScale(d.value))
  .curve(d3.curveMonotoneX); // smooth curve
svg.append("path").datum(data).attr("d", line).attr("fill", "none").attr("stroke", "#4f46e5");

// Area chart
const area = d3.area()
  .x(d => xScale(d.date))
  .y0(height - margin.bottom)
  .y1(d => yScale(d.value))
  .curve(d3.curveMonotoneX);

// Pie / Donut
const pie = d3.pie().value(d => d.value).sort(null);
const arc = d3.arc().innerRadius(60).outerRadius(100); // innerRadius > 0 = donut
const arcs = svg.selectAll("path").data(pie(data)).join("path").attr("d", arc);

// Force-directed graph
const simulation = d3.forceSimulation(nodes)
  .force("link", d3.forceLink(links).id(d => d.id).distance(80))
  .force("charge", d3.forceManyBody().strength(-300))
  .force("center", d3.forceCenter(width / 2, height / 2));
```

---

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

## 🔌 Embedded Systems

### Core Principles
- **No dynamic allocation on MCU**: avoid `malloc`/`free` — fragmentation causes hard-to-debug crashes. Use static allocation or memory pools.
- **Deterministic behavior**: embedded systems must be predictable — avoid unbounded loops, use watchdog timers.
- **Resource constraints**: RAM in KB, flash in KB/MB, CPU in MHz — every byte and cycle matters.
- **Hardware abstraction**: isolate hardware-specific code in HAL (Hardware Abstraction Layer).
- **Fail safe**: hardware fails — always handle: no sensor response, corrupted data, power loss mid-write.

### C for Embedded (Best Practices)
```c
/* Use fixed-width integer types — sizes are platform-defined otherwise */
#include <stdint.h>
#include <stdbool.h>

uint8_t  sensor_val;    /* 0-255, 1 byte */
uint16_t adc_reading;   /* 0-65535, 2 bytes */
uint32_t timestamp_ms;  /* milliseconds uptime */
int32_t  temperature;   /* signed, millidegrees */

/* Volatile for hardware registers and ISR-shared variables */
volatile uint32_t tick_count = 0;

/* Bit manipulation — common in embedded */
#define LED_PIN   (1 << 5)          /* Pin 5 */
GPIOA->ODR |= LED_PIN;              /* Set high */
GPIOA->ODR &= ~LED_PIN;             /* Set low */
GPIOA->ODR ^= LED_PIN;              /* Toggle */

/* Circular buffer — ISR-safe ring buffer */
typedef struct {
    uint8_t  buf[64];
    uint8_t  head;
    uint8_t  tail;
} RingBuf;
```

### RTOS (FreeRTOS)
```c
/* Tasks — don't use bare super-loops for complex systems */
void sensor_task(void *pvParameters) {
    TickType_t xLastWakeTime = xTaskGetTickCount();
    for (;;) {
        read_sensor();
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(100)); /* 100ms periodic */
    }
}

/* Inter-task communication via queues */
QueueHandle_t xQueue = xQueueCreate(10, sizeof(uint16_t));

/* In producer task (or ISR) */
uint16_t reading = read_adc();
xQueueSendFromISR(xQueue, &reading, &xHigherPriorityTaskWoken);

/* In consumer task */
uint16_t val;
if (xQueueReceive(xQueue, &val, portMAX_DELAY) == pdPASS) {
    process(val);
}

/* Mutex for shared resources */
SemaphoreHandle_t xMutex = xSemaphoreCreateMutex();
if (xSemaphoreTake(xMutex, pdMS_TO_TICKS(100)) == pdPASS) {
    /* access shared resource */
    xSemaphoreGive(xMutex);
}
```

### Hardware Interfaces
```c
/* I2C — for sensors (temp, IMU, OLED) */
HAL_I2C_Master_Transmit(&hi2c1, DEVICE_ADDR << 1, &reg, 1, HAL_MAX_DELAY);
HAL_I2C_Master_Receive(&hi2c1, DEVICE_ADDR << 1, data, 2, HAL_MAX_DELAY);

/* SPI — for fast peripherals (displays, flash) */
HAL_GPIO_WritePin(CS_GPIO, CS_PIN, GPIO_PIN_RESET);  /* CS low */
HAL_SPI_TransmitReceive(&hspi1, tx_buf, rx_buf, len, HAL_MAX_DELAY);
HAL_GPIO_WritePin(CS_GPIO, CS_PIN, GPIO_PIN_SET);    /* CS high */

/* UART — for debug, GPS, BLE modules */
HAL_UART_Transmit(&huart2, (uint8_t*)"Hello\r\n", 7, HAL_MAX_DELAY);

/* ADC — analog sensors */
HAL_ADC_Start(&hadc1);
HAL_ADC_PollForConversion(&hadc1, HAL_MAX_DELAY);
uint32_t val = HAL_ADC_GetValue(&hadc1);

/* PWM — motors, LEDs */
HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, duty_cycle);  /* 0–ARR */
```

### Arduino / ESP32 (Rapid Prototyping)
```cpp
// ESP32 + FreeRTOS tasks
void wifi_task(void *param) {
    WiFi.begin(SSID, PASSWORD);
    while (WiFi.status() != WL_CONNECTED) { delay(500); }
    for (;;) {
        send_telemetry();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

void setup() {
    xTaskCreatePinnedToCore(wifi_task, "WiFi", 4096, NULL, 1, NULL, 0);  /* Core 0 */
    xTaskCreatePinnedToCore(sensor_task, "Sensor", 2048, NULL, 2, NULL, 1); /* Core 1 */
}
```

### Power Management
```c
/* STM32 low-power modes */
HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);  /* light sleep */
HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI); /* deep sleep */
HAL_PWR_EnterSTANDBYMode();   /* lowest power, RAM lost */

/* Wake sources: RTC alarm, GPIO interrupt, UART */
/* Design for: measure → sleep → wake → transmit → sleep (duty cycling) */
```

### OTA Firmware Update
```c
/* ESP32 OTA via HTTPS */
esp_https_ota_config_t config = {
    .http_config = &http_config,
    .partial_http_download = true,
    .max_http_request_size = 4096,
};
esp_err_t ret = esp_https_ota(&config);
if (ret == ESP_OK) esp_restart();
```

### Debugging Embedded Systems
```bash
# OpenOCD + GDB for ARM Cortex-M
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg &
arm-none-eabi-gdb firmware.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load                    # flash firmware
(gdb) break main
(gdb) continue

# Logic analyzer (sigrok/PulseView)
sigrok-cli -d fx2lafw --config samplerate=1m --samples 1m \
  --channels D0,D1 --triggers D0=r > capture.sr

# Serial debug output
screen /dev/ttyUSB0 115200
picocom -b 115200 /dev/ttyUSB0
```

### MISRA C (Safety-Critical)
- Mandatory in automotive (AUTOSAR), medical, aerospace.
- Key rules: no dynamic memory, no recursion, all switch cases have default, no `goto`.
- Static analysis: **PC-lint**, **Polyspace**, **Parasoft C/C++test**.
- For hobbyist/IoT: follow spirit — initialize all variables, check return values, avoid UB.

---

## 🎮 Game Development

### Game Loop Architecture
```ts
// Fixed timestep game loop — physics runs at constant rate
let accumulator = 0;
const FIXED_DT = 1000 / 60;  // 60 physics updates/sec

function gameLoop(timestamp: number) {
    const frameTime = Math.min(timestamp - lastTime, 250);  // cap at 250ms (tab unfocus)
    lastTime = timestamp;
    accumulator += frameTime;

    while (accumulator >= FIXED_DT) {
        update(FIXED_DT);        // physics/game logic — fixed step
        accumulator -= FIXED_DT;
    }

    const alpha = accumulator / FIXED_DT;  // interpolation factor
    render(alpha);               // render between states for smooth visuals

    requestAnimationFrame(gameLoop);
}
```

### Entity Component System (ECS)
```ts
// ECS separates data (components) from logic (systems)
// Entities are just IDs; components are plain data; systems operate on components

// Components — pure data, no logic
interface Position { x: number; y: number; }
interface Velocity { dx: number; dy: number; }
interface Health   { current: number; max: number; }

// System — operates on all entities with matching components
function movementSystem(world: World, dt: number) {
    for (const [entity, [pos, vel]] of world.query<[Position, Velocity]>()) {
        pos.x += vel.dx * dt;
        pos.y += vel.dy * dt;
    }
}

// Entity is just an ID
const player = world.createEntity();
world.addComponent(player, Position, { x: 0, y: 0 });
world.addComponent(player, Velocity, { dx: 1, dy: 0 });
world.addComponent(player, Health,   { current: 100, max: 100 });
```

### Unity (C#) — Key Patterns
```csharp
// MonoBehaviour lifecycle
public class Player : MonoBehaviour {
    [SerializeField] private float speed = 5f;
    private Rigidbody2D rb;

    void Awake() { rb = GetComponent<Rigidbody2D>(); }  // init refs

    void Update() {            // every frame — input, animation
        float x = Input.GetAxis("Horizontal");
        float y = Input.GetAxis("Vertical");
        rb.velocity = new Vector2(x, y) * speed;
    }

    void FixedUpdate() { }     // fixed timestep — physics

    void OnTriggerEnter2D(Collider2D other) {
        if (other.CompareTag("Enemy")) TakeDamage(10);
    }
}

// Object pooling — reuse instead of Instantiate/Destroy
public class BulletPool : MonoBehaviour {
    private Queue<GameObject> pool = new();

    public GameObject Get() {
        if (pool.Count > 0) {
            var obj = pool.Dequeue();
            obj.SetActive(true);
            return obj;
        }
        return Instantiate(prefab);
    }

    public void Return(GameObject obj) {
        obj.SetActive(false);
        pool.Enqueue(obj);
    }
}
```

### Unreal Engine (C++) — Key Patterns
```cpp
// Actor lifecycle
UCLASS()
class AMyActor : public AActor {
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Stats")
    float Health = 100.0f;

protected:
    virtual void BeginPlay() override;  // game start
    virtual void Tick(float DeltaTime) override;

public:
    UFUNCTION(BlueprintCallable)
    void TakeDamage(float Amount);
};

// Gameplay Ability System (GAS) for complex games
// GameplayTags for flexible state management (not enums)
// Replication: UPROPERTY(Replicated) for networked properties
```

### Game AI

#### Finite State Machine
```ts
enum EnemyState { Idle, Patrol, Chase, Attack, Flee }

class EnemyAI {
    state = EnemyState.Idle;

    update(dt: number, distToPlayer: number) {
        switch (this.state) {
            case EnemyState.Idle:
                if (distToPlayer < ALERT_RANGE) this.state = EnemyState.Chase;
                break;
            case EnemyState.Chase:
                if (distToPlayer < ATTACK_RANGE) this.state = EnemyState.Attack;
                if (distToPlayer > LOSE_RANGE)   this.state = EnemyState.Patrol;
                break;
            case EnemyState.Attack:
                this.attack();
                if (this.health < 20) this.state = EnemyState.Flee;
                break;
        }
    }
}
```

#### Behavior Trees
```
Root
└── Selector (?)           ← first succeeding child wins
    ├── Sequence (→)       ← all must succeed (attack)
    │   ├── IsPlayerVisible
    │   ├── IsInRange
    │   └── AttackPlayer
    └── Sequence (→)       ← fallback (patrol)
        ├── HasPatrolPath
        └── MoveToNextWaypoint
```

#### Pathfinding (A*)
```ts
function aStar(start: Node, goal: Node, grid: Grid): Node[] {
    const open = new PriorityQueue<Node>();
    const gScore = new Map([[start, 0]]);
    const fScore = new Map([[start, heuristic(start, goal)]]);
    open.push(start, fScore.get(start)!);

    while (!open.isEmpty()) {
        const current = open.pop();
        if (current === goal) return reconstructPath(current);

        for (const neighbor of grid.neighbors(current)) {
            const tentativeG = gScore.get(current)! + cost(current, neighbor);
            if (tentativeG < (gScore.get(neighbor) ?? Infinity)) {
                gScore.set(neighbor, tentativeG);
                fScore.set(neighbor, tentativeG + heuristic(neighbor, goal));
                open.push(neighbor, fScore.get(neighbor)!);
            }
        }
    }
    return [];  // no path
}
```

### Multiplayer Networking
```ts
// Authoritative server model — server is truth, clients predict
// Client-side prediction: apply input locally immediately
// Server reconciliation: receive server state, correct if diverged
// Entity interpolation: smooth rendering between server updates

// Netcode patterns:
// Lockstep: all clients simulate same state — works for RTS
// Client-side prediction + rollback: modern FPS/fighting games
// Dead reckoning: extrapolate position for lag hiding

// WebSocket game server (Node.js)
const io = new Server(httpServer);
io.on("connection", (socket) => {
    socket.on("playerInput", (input: Input) => {
        const player = gameState.players.get(socket.id);
        applyInput(player, input);           // server authoritative update
        io.emit("gameState", gameState.serialize()); // broadcast to all
    });
});
```

### Shader Basics (GLSL/WGSL)
```glsl
/* Vertex shader — transform vertices */
attribute vec3 position;
attribute vec2 uv;
uniform mat4 modelViewProjection;
varying vec2 vUv;

void main() {
    vUv = uv;
    gl_Position = modelViewProjection * vec4(position, 1.0);
}

/* Fragment shader — color each pixel */
uniform sampler2D diffuseMap;
uniform float time;
varying vec2 vUv;

void main() {
    vec2 animated = vUv + vec2(sin(time * 0.5) * 0.01, 0.0);  /* UV scroll */
    gl_FragColor = texture2D(diffuseMap, animated);
}
```

### Game Performance Optimization
- **Draw calls**: minimize — batch same-material objects; use GPU instancing for repeated meshes.
- **Object pooling**: never `Instantiate`/`Destroy` per frame — pool bullets, particles, enemies.
- **LOD (Level of Detail)**: swap high-poly mesh to low-poly at distance — automatic in Unreal/Unity.
- **Occlusion culling**: don't render what the camera can't see — Unity Occlusion Baking, Unreal HLOD.
- **Profiling**: Unity Profiler / Unreal Insights — fix hotspots, don't guess.
- **Physics layers**: only check collisions between relevant layers — reduces broadphase cost.
- **Coroutines/async for non-gameplay work**: don't block game loop for file I/O, network, save.

---

## 🤖 Claude Code Skills
