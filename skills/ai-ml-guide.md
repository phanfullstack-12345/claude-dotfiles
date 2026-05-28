# Reference: ai-ml-guide
# Load this file when working on tasks matching this domain.

## 🤖 AI / LLM Stack

### LangGraph
- Define graphs with typed state using `TypedDict` or Pydantic models.
- Nodes are pure functions where possible — side effects in dedicated tool nodes.
- Use `StateGraph` for stateful multi-step flows; `MessageGraph` for chat agents.
- Always define explicit `END` conditions — guard against infinite loops.
- Checkpoint with `SqliteSaver` (dev) or `PostgresSaver` (prod) for resumable flows.
- Test graphs with `graph.invoke()` + snapshot tests on state output.

### LangSmith
- Set `LANGCHAIN_TRACING_V2=true` in all environments (dev, staging, prod).
- Tag runs with `project`, `environment`, and `version` metadata.
- Use datasets for regression testing LLM behavior — add failing cases to datasets.
- Monitor latency and token usage per run in the LangSmith dashboard.
- Use `@traceable` decorator on custom functions that should appear in traces.

### LangFuse
- Use LangFuse for production observability when self-hosting is required.
- Instrument with `@observe()` decorator or manual `langfuse.trace()`.
- Track: input/output, latency, token cost, model name, user ID per trace.
- Create Scores for quality evaluation — tie to human feedback or automated evals.
- Use LangFuse datasets for A/B testing prompt versions.

### General LLM Best Practices
- Always set explicit `max_tokens` — never let the model run unbounded.
- Use structured output (JSON mode, tool calling, Pydantic) over parsing free text.
- Prompt versioning: store prompts in code or a prompt registry — not hardcoded strings.
- Retry with exponential backoff on rate limit errors (429).
- Log every LLM call: model, prompt, response, latency, cost, user context.
- Evaluate systematically — build evals before optimizing prompts.
- Keep system prompts and user prompts separate; never concatenate them naively.
- PII: scrub sensitive data before sending to third-party LLM APIs.

---


## 🧬 AI/ML Engineering — LLM, RAG, Agents

### LLM Fundamentals
- Tokens ≠ words: ~4 chars/token (English); pricing and context limits are in tokens, not words.
- Temperature: 0 = deterministic/factual, 0.7 = balanced, 1.0+ = creative/varied.
- Context window: everything the model "sees" — system prompt + history + tools + output.
- Top-p (nucleus sampling): only sample from top-p probability mass — use with temperature.
- **System prompt** sets persona/constraints; **user turn** is the task; never merge them.
- Always set `max_tokens` explicitly — unbounded generation wastes money and causes timeouts.

### Prompt Engineering

#### Core Techniques
```python
# Chain-of-thought — force reasoning before answer
system = "Think step by step before giving your final answer."

# Few-shot — show examples in prompt
system = """Classify sentiment as positive/negative/neutral.
Examples:
"I love this!" → positive
"It's broken." → negative
"It works." → neutral
Now classify: {input}"""

# Role prompting
system = "You are a senior TypeScript engineer reviewing code for security issues."

# Structured output — JSON mode / tool use
system = "Always respond with valid JSON matching the schema: {fields}"
```

#### Prompt Versioning
- Store prompts in code, not hardcoded strings — use a prompt registry or constants file.
- Version prompts like code: `PROMPT_V2 = "..."` — never silently edit live prompts.
- A/B test prompt changes with LangSmith datasets or LangFuse experiments.
- Eval before deploy: regression suite of known inputs → expected outputs.

### RAG Architecture (Retrieval-Augmented Generation)

#### Pipeline
```
Documents → Chunking → Embedding → Vector Store
                                        ↓
Query → Embed query → Similarity search → Retrieved chunks → LLM → Answer
```

#### Chunking Strategies
```python
# Fixed-size (simple, baseline)
chunks = [text[i:i+512] for i in range(0, len(text), 512)]

# Semantic chunking (better quality — split at sentence/paragraph boundaries)
from langchain.text_splitter import RecursiveCharacterTextSplitter
splitter = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=64)
chunks = splitter.split_text(document)

# Hierarchical chunking: store both parent (context) and child (precision)
# Retrieve child, return parent to LLM for more context
```

#### Retrieval Strategies
| Strategy | When to use |
|---|---|
| **Dense retrieval** (vector similarity) | Semantic meaning matters, not exact keywords |
| **Sparse retrieval** (BM25/keyword) | Exact terms, codes, names, IDs |
| **Hybrid** (dense + sparse, RRF reranking) | Best of both — production default |
| **Reranking** (cross-encoder) | After initial retrieval — rerank top-k for precision |
| **HyDE** (Hypothetical Document Embeddings) | Generate a hypothetical answer, embed it, search |
| **Multi-query** | Generate N query variants, merge results |

#### Vector Databases
```python
# pgvector — PostgreSQL extension (best for existing Postgres stack)
CREATE EXTENSION vector;
CREATE TABLE embeddings (id SERIAL, content TEXT, embedding vector(1536));
CREATE INDEX ON embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

# Similarity search
SELECT content FROM embeddings
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 10;
```

| DB | Best for |
|---|---|
| **pgvector** | Existing PostgreSQL, simple stack |
| **Weaviate** | Multi-modal, hybrid search built-in |
| **Qdrant** | High-performance, on-prem |
| **Pinecone** | Managed, serverless, zero-ops |
| **Chroma** | Local dev, prototyping |

#### RAG Quality Checklist
- [ ] Chunk overlap to avoid splitting context at boundaries
- [ ] Metadata filtering: filter by date, source, category before vector search
- [ ] Re-ranking applied after initial retrieval
- [ ] Answer grounded in retrieved context (check with LLM-as-judge eval)
- [ ] Hallucination rate measured in evals
- [ ] Fallback: "I don't have enough information" when retrieval score is low

### Agent Systems

#### ReAct Pattern (Reason + Act)
```python
# Agent loop: Think → Tool call → Observe → Think → ... → Answer
from langchain.agents import create_react_agent

# Each step: LLM reasons about what tool to call, calls it, observes result
# Loop until LLM decides it has enough info to answer
```

#### Tool / Function Calling
```python
# Anthropic tool use
tools = [{
    "name": "search_database",
    "description": "Search the product database. Use when user asks about specific products.",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {"type": "string", "description": "Search query"},
            "limit": {"type": "integer", "default": 10}
        },
        "required": ["query"]
    }
}]

response = client.messages.create(
    model="claude-opus-4-7",
    tools=tools,
    messages=[{"role": "user", "content": "Find laptops under $1000"}]
)
# Check if response.stop_reason == "tool_use" → execute tool → continue loop
```

#### Multi-Agent Orchestration (LangGraph)
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    next_agent: str

# Supervisor routes tasks to specialized agents
def supervisor(state: AgentState):
    # Decide which agent handles next step
    return {"next_agent": "researcher" if needs_research(state) else "writer"}

builder = StateGraph(AgentState)
builder.add_node("supervisor", supervisor)
builder.add_node("researcher", research_agent)
builder.add_node("writer", write_agent)
builder.add_conditional_edges("supervisor", lambda s: s["next_agent"],
    {"researcher": "researcher", "writer": "writer", "done": END})
```

#### Agent Patterns
| Pattern | Use case |
|---|---|
| **ReAct** | General tool-using agent |
| **Plan & Execute** | Complex multi-step tasks — plan first, then execute |
| **Reflexion** | Self-critique and retry on failure |
| **Multi-agent supervisor** | Route subtasks to specialized agents |
| **Parallel agents** | Independent tasks run concurrently |
| **Human-in-the-loop** | Pause for approval on sensitive actions |

### MLOps & Evaluation

#### Experiment Tracking
```python
# MLflow
import mlflow
with mlflow.start_run():
    mlflow.log_param("model", "claude-sonnet-4-6")
    mlflow.log_param("temperature", 0.7)
    mlflow.log_metric("accuracy", 0.87)
    mlflow.log_metric("latency_p99", 1.2)
```

#### LLM Evaluation (Evals)
```python
# LLM-as-judge: use a model to score outputs
def evaluate_answer(question, context, answer):
    prompt = f"""Rate this answer 1-5 for correctness and groundedness.
    Question: {question}
    Context: {context}
    Answer: {answer}
    Return JSON: {{"score": int, "reason": str}}"""
    return judge_model.complete(prompt)

# Eval types:
# - Exact match (factual Q&A)
# - LLM-as-judge (open-ended quality)
# - Retrieval precision/recall (RAG eval)
# - Tool call accuracy (agent eval)
# - End-to-end task completion rate
```

#### Fine-tuning (When RAG isn't enough)
- **LoRA / QLoRA**: low-rank adaptation — fine-tune with <1% of original parameters.
- Use fine-tuning for: style/format adherence, domain-specific vocabulary, structured output.
- **Do NOT** use fine-tuning to inject facts — facts drift and hallucinate. Use RAG for facts.
- Dataset: minimum 100 examples; 1000+ for reliable results; curate quality over quantity.
- Evaluate fine-tuned model against base model on held-out test set before deploying.

### LLM Cost Optimization
- **Prompt caching**: cache system prompt + static context (Anthropic Cache Control — up to 90% savings).
- **Model routing**: use Haiku/Flash for classification/routing; Sonnet for generation; Opus for complex reasoning.
- **Batching**: use Batch API for non-real-time workloads (50% discount on Anthropic).
- **Output length**: constrain with `max_tokens`; use structured output to avoid verbose prose.
- **Token counting**: count before sending; reject oversized requests early.
- Monitor cost per user/feature in LangSmith/LangFuse — find expensive outliers.

### Guardrails & Safety
```python
# Input guardrails
def validate_input(user_input: str) -> bool:
    # Check for prompt injection attempts
    injection_patterns = ["ignore previous instructions", "system:", "SYSTEM:"]
    if any(p.lower() in user_input.lower() for p in injection_patterns):
        return False
    # PII detection before sending to external LLM
    if contains_pii(user_input):
        redact_pii(user_input)
    return True

# Output guardrails
def validate_output(response: str) -> str:
    # Check for hallucinated citations, toxic content, PII leakage
    if contains_hallucinated_urls(response):
        response = remove_urls(response)
    return response
```

---

