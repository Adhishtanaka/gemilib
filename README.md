# adhishtanaka / gemilib

**Unofficial Gemini API Client for Ballerina**
**Package:** `adhishtanaka/gemilib`
**Version:** 0.1.1

## Overview

The **GemiLib** module provides APIs for interacting with AI models, performing intelligent search queries, and analyzing or summarizing web content. It offers structured and extensible abstractions for conversational AI, automated data lookups, and web scraping in a unified workflow.

This is an **unofficial Gemini API client for Ballerina**, built to simplify integration with Google's Gemini models and the Jina Reader API.

The library introduces three main capabilities — **AI Chat**, **Search & Query**, and **Web Scraping** — built upon modern HTTP-based integrations.

---

## AI Chat

### Chat

The `chat()` function enables structured conversations with AI, supporting contextual dialogue and optional database-assisted responses. It accepts a `ChatConfig` for system prompts, classification instructions, and automatic search control.

When `autoSearch` is enabled, the library classifies user intent to determine if a database lookup is required. If so, it extracts relevant keywords and executes the provided query function before generating a response.

```ballerina
string response = check gemi.chat("Show me rice suppliers in Colombo", cfg);
```

### Simple Chat

For lightweight interactions, the `simpleChat()` method enables basic AI exchanges without classification or search integration.

```ballerina
string reply = check gemi.simpleChat("Tell me a joke", "You are a witty assistant.");
```

### Ask

The `ask()` function provides direct access to the AI model for one-off prompt execution.

```ballerina
string output = check gemi.ask("Summarize the concept of reinforcement learning.");
```

---

## Search and Query

### Query

The `query()` function converts user text into structured keyword-based searches. It extracts key terms, invokes a custom database query function, and crafts a natural language summary using a provided prompt template.

```ballerina
QueryResult result = check gemi.query(
    "Find suppliers of organic rice in Colombo",
    { tableName: "suppliers", searchColumns: ["product", "location"] },
    "User asked: {USER_QUERY}. Results: {RESULTS}"
);
```

### Keyword Extraction

The `extractKeywords()` method isolates the most relevant search terms from natural language input using the AI model.

```ballerina
string[] terms = check gemi.extractKeywords("best tea farms near Kandy");
```

---

## Web Scraping

### Scrape

The `scrape()` function retrieves and analyzes the contents of any web page using the Jina Reader API. It can summarize the HTML or process it based on a specific instruction.

```ballerina
string summary = check gemi.scrape("https://example.com/news");
```

This method fetches the HTML, sanitizes it, and generates an AI summary or custom analytical response.

---

## Core Concepts

### Types

* **ChatMessage** – Represents a conversation message with `role` and `content`.
* **QueryResult** – Contains extracted `keywords`, query `results`, and AI `response`.
* **SearchConfig** – Holds configuration for database table and searchable columns.
* **ChatConfig** – Defines prompts and behavior for AI chat, including `systemPrompt`, `autoSearch`, and formatting rules.

### Constructor

The library is initialized with API credentials and optional parameters for model configuration.

```ballerina
 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.0-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);
```

---

## Internal Tools

### AI Communication Tool

Handles all Gemini API interactions for text generation, supporting adjustable temperature, top-K, and token control.

### Keyword Extraction Tool

Processes AI responses to isolate and return clean JSON arrays of search terms.

### Web Scraping Tool

Fetches and processes HTML from any URL using the Jina Reader API, producing summarized or structured results.

---

## Error Handling

All major functions return `string|error` or `error?`, allowing developers to gracefully handle API errors, invalid JSON, or connection issues.

---

## Example

```ballerina
import ballerina/io;
import adhishtanaka/gemilib;

 gemilib:GemiLib gemi = check new ("YOUR_API_KEY");

ChatConfig cfg = {
    systemPrompt: "You are a helpful assistant.",
    searchClassificationPrompt: "Determine if search is required.",
    autoSearch: true
};

string response = check gemi.chat("Find me paddy suppliers in Kurunegala", cfg);
io:println(response);
```

---

## Security

GemiLib connects securely to Gemini and Jina endpoints via HTTPS. No user credentials or API keys are stored locally. All requests are stateless and confined to the current session.
