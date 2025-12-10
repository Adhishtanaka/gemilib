# adhishtanaka / gemilib

**Unofficial Gemini API Client for Ballerina**
**Package:** `adhishtanaka/gemilib`
**Version:** 0.1.2

## Overview

The **GemiLib** module provides APIs for interacting with AI models, performing intelligent search queries, and analyzing or summarizing web content. This is an **unofficial Gemini API client for Ballerina**, built to simplify integration with Google's Gemini models and the Jina Reader API.

The library introduces three main capabilities   
- **AI Chat**, 
- **Keyword Extraction**, 
- **Web Scraping** 

built upon modern HTTP-based integrations.

### Constructor

The library is initialized with API credentials and optional parameters for model configuration.

```ballerina
 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.5-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);
```

## Usage

### Simple Chat

For lightweight interactions, the `simpleChat()` method enables basic AI exchanges without classification or search integration.

```ballerina
import ballerina/io;
import adhishtanaka/gemilib;

 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.5-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);
string reply = check gemi.simpleChat("Tell me a joke", "You are a witty assistant.");
```

### Ask

The `ask()` function provides direct access to the AI model for one-off prompt execution.

```ballerina
import ballerina/io;
import adhishtanaka/gemilib;

 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.5-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);

string output = check gemi.ask("Summarize the concept of reinforcement learning.");
io:println(output);
```

---

## Web Scraping

### Summary Scrape

The `scrape()` function retrieves and analyzes the contents of any web page using the Jina Reader API. It can summarize the HTML or process it based on a specific instruction.

```ballerina
import ballerina/io;
import adhishtanaka/gemilib;

 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.5-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);

string summary = check gemi.scrape("https://example.com");

io:println(summary);
```

### Specific Details Scrape

```ballerina
import ballerina/io;
import adhishtanaka/gemilib;

 gemilib:GemiLib gemi = check new (
    apiKey = "YOUR_API_KEY",
    modelName = "gemini-2.5-flash",
    baseUrl = "https://generativelanguage.googleapis.com",
    temperature = 0.7,
    maxOutputTokens = 2048
);

    string output = check gemi.scrape("https://en.wikipedia.org/wiki/National_School_of_Business_Management","in what year NSBM university founded");
    io:println(output);
```

This method fetches the HTML, sanitizes it, and generates an AI summary or custom analytical response.

---




