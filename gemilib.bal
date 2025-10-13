import ballerina/http;

public type ChatMessage record {|
    string role; 
    string content;
|};

public type QueryResult record {|
    string[] keywords;
    json results;
    string response;
|};

public type SearchConfig record {|
    string tableName;
    string[] searchColumns;
    int maxResults = 10;
|};

public type ChatConfig record {|
    string systemPrompt;
    string searchClassificationPrompt; 
    string responseFormatInstructions?; 
    boolean autoSearch = true; 
|};

public isolated class GemiLib {
    private final http:Client aiClient;
    private final http:Client jinaClient;
    private final string modelName;
    private final string apiKey;
    private final float temperature;
    private final int maxOutputTokens;

    public isolated function init(
        string apiKey,
        string modelName = "gemini-2.0-flash",
        string baseUrl = "https://generativelanguage.googleapis.com",
        float temperature = 0.7,
        int maxOutputTokens = 2048
    ) returns error? {
        self.apiKey = apiKey;
        self.modelName = modelName;
        self.temperature = temperature;
        self.maxOutputTokens = maxOutputTokens;
        self.aiClient = check new (baseUrl);
        self.jinaClient = check new ("https://r.jina.ai");
    }

    # Sends a chat message to the AI model with optional conversation history and auto-search functionality.
#
# + userMessage - The current user message to process.
# + chatConfig - Configuration including system prompt, search prompt, and response formatting.
# + conversationHistory - Optional array of previous chat messages.
# + queryFunction - Optional function to perform keyword-based database search.
# + return - AI-generated response string, or an error if processing fails.
    public isolated function chat(
        string userMessage,
        ChatConfig chatConfig,
        ChatMessage[]? conversationHistory = (),
        (isolated function (string[]) returns json|error)? queryFunction = ()
    ) returns string|error {
        
        json? searchResults = ();
        
        if chatConfig.autoSearch && queryFunction is isolated function (string[]) returns json|error {
            boolean needsSearch = check self.classifySearchIntent(
                userMessage,
                chatConfig.searchClassificationPrompt
            );

            if needsSearch {
                string[] keywords = check self.extractKeywords(userMessage);
                
                if keywords.length() > 0 {
                    searchResults = check queryFunction(keywords);
                }
            }
        }

        string response = check self.generateChatResponse(
            userMessage,
            chatConfig,
            conversationHistory,
            searchResults
        );

        return response;
    }

    private isolated function classifySearchIntent(
        string userMessage,
        string classificationPrompt
    ) returns boolean|error {
        
        string prompt = classificationPrompt + string `

User message: "${userMessage}"

Return ONLY one of these two values: "SEARCH_NEEDED" or "NO_SEARCH"`;

        string classification = check self.callAI(prompt);
        return classification.trim().toUpperAscii().includes("SEARCH");
    }

    private isolated function generateChatResponse(
        string userMessage,
        ChatConfig chatConfig,
        ChatMessage[]? conversationHistory,
        json? searchResults
    ) returns string|error {
        
        string prompt = chatConfig.systemPrompt + "\n\n";

        string? formatInstructions = chatConfig.responseFormatInstructions;
        if formatInstructions is string {
            prompt += formatInstructions + "\n\n";
        }

        if conversationHistory is ChatMessage[] && conversationHistory.length() > 0 {
            prompt += "Previous conversation:\n";
            foreach ChatMessage msg in conversationHistory {
                prompt += msg.role + ": " + msg.content + "\n";
            }
            prompt += "\n";
        }

        if searchResults is json {
            prompt += string `Database search results: ${searchResults.toJsonString()}\n\n`;
        }

        prompt += string `Current user message: "${userMessage}"\n\n`;
        prompt += "Respond:";

        return check self.callAI(prompt);
    }
# Sends a simple chat message to the AI model using only the system prompt.
#
# + userMessage - The current user message.
# + systemPrompt - System-level instruction for the AI.
# + conversationHistory - Optional array of previous chat messages.
# + return - AI-generated response string, or an error if processing fails.
    public isolated function simpleChat(
        string userMessage,
        string systemPrompt,
        ChatMessage[]? conversationHistory = ()
    ) returns string|error {
        
        string prompt = systemPrompt + "\n\n";

        if conversationHistory is ChatMessage[] && conversationHistory.length() > 0 {
            prompt += "Previous conversation:\n";
            foreach ChatMessage msg in conversationHistory {
                prompt += msg.role + ": " + msg.content + "\n";
            }
            prompt += "\n";
        }

        prompt += string `User: "${userMessage}"\n\nRespond:`;

        return check self.callAI(prompt);
    }
# Executes a keyword-based query with search results from a database or collection.
#
# + userQuery - The user’s search query string.
# + searchConfig - Configuration specifying the table, columns, and max results.
# + responsePromptTemplate - AI prompt template for formatting the final response.
# + queryFunction - Function that executes the search using extracted keywords.
# + return - A QueryResult containing keywords, results, and the AI-formatted response.
    public isolated function query(
        string userQuery,
        SearchConfig searchConfig,
        string responsePromptTemplate,
        isolated function (string[]) returns json|error queryFunction
    ) returns QueryResult|error {
        
        string[] keywords = check self.extractKeywords(userQuery);
        
        if keywords.length() == 0 {
            return error("Could not extract meaningful keywords from query");
        }

        json results = check queryFunction(keywords);
        
        string response = check self.generateQueryResponse(
            userQuery,
            results,
            searchConfig,
            responsePromptTemplate
        );
        
        return {
            keywords: keywords,
            results: results,
            response: response
        };
    }
# Extracts 1–3 relevant keywords from user input for database searching.
#
# + userInput - The user query text.
# + customPrompt - Optional prompt to customize AI keyword extraction.
# + return - Array of extracted keywords, or an error if extraction fails.
    public isolated function extractKeywords(
        string userInput,
        string? customPrompt = ()
    ) returns string[]|error {
        
        string prompt = customPrompt is string ? customPrompt : 
            string `Extract 1-3 most relevant keywords for database search.
Query: "${userInput}"

Return ONLY a JSON array of keywords in lowercase.
Example: ["rice", "colombo", "seeds"]

JSON array:`;

        string aiResponse = check self.callAI(prompt);
        string cleanResponse = cleanJsonResponse(aiResponse);
        
        json keywordJson = check cleanResponse.fromJsonString();
        string[] keywords = check keywordJson.cloneWithType();
        
        return keywords;
    }

    private isolated function generateQueryResponse(
        string userQuery,
        json results,
        SearchConfig searchConfig,
        string promptTemplate
    ) returns string|error {
        
        string prompt = promptTemplate;
        
        prompt = self.replaceString(prompt, "{USER_QUERY}", userQuery);
        prompt = self.replaceString(prompt, "{TABLE_NAME}", searchConfig.tableName);
        prompt = self.replaceString(prompt, "{SEARCH_COLUMNS}", searchConfig.searchColumns.toString());
        prompt = self.replaceString(prompt, "{RESULTS}", results.toJsonString());

        return check self.callAI(prompt);
    }
    
    private isolated function replaceString(string original, string target, string replacement) returns string {
        string result = "";
        int targetLen = target.length();
        int i = 0;
        
        while i < original.length() {
            if i + targetLen <= original.length() && original.substring(i, i + targetLen) == target {
                result += replacement;
                i += targetLen;
            } else {
                result += original.substring(i, i + 1);
                i += 1;
            }
        }
        
        return result;
    }
# Scrapes and summarizes content from a web page.
#
# + url - The URL of the web page to scrape.
# + instruction - Optional instruction for summarization or analysis.
# + return - AI-generated summary string, or an error if scraping or AI processing fails.
    public isolated function scrape(
        string url,
        string? instruction = ()
    ) returns string|error {
        
        string htmlContent = check self.fetchHtml(url);
        
        string prompt = instruction is string 
            ? string `${instruction}

HTML Content:
${htmlContent}

Response:`
            : string `Analyze and summarize the main content from this webpage:

HTML Content:
${htmlContent}

Summary:`;

        return check self.callAI(prompt);
    }

    private isolated function fetchHtml(string url) returns string|error {
        http:Response response = check self.jinaClient->get("/" + url);
        string htmlContent = check response.getTextPayload();
        return htmlContent;
    }

# Sends a freeform prompt directly to the AI model.
#
# + prompt - The instruction or message to send to the AI.
# + return - AI-generated response string, or an error if processing fails.
    public isolated function ask(string prompt) returns string|error {
        return check self.callAI(prompt);
    }

    private isolated function callAI(string prompt) returns string|error {
        json payload = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }],
            "generationConfig": {
                "temperature": self.temperature,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": self.maxOutputTokens
            }
        };

        string endpoint = string `/v1beta/models/${self.modelName}:generateContent?key=${self.apiKey}`;
        
        json|http:ClientError response = self.aiClient->post(endpoint, payload);
        
        if response is http:ClientError {
            return error(string `AI API call failed: ${response.message()}`);
        }
        
        return check extractText(response);
    }

    public isolated function sanitizeInput(string input) returns string {
        string sanitized = input.trim();
        
        string result = "";
        boolean prevSpace = false;
        
        foreach int i in 0 ..< sanitized.length() {
            string char = sanitized.substring(i, i + 1);
            if char == " " {
                if !prevSpace {
                    result += char;
                }
                prevSpace = true;
            } else {
                result += char;
                prevSpace = false;
            }
        }
        
        return result;
    }

    public isolated function hasResults(json results) returns boolean {
        if results is json[] {
            return results.length() > 0;
        }
        return false;
    }
}

public isolated function cleanJsonResponse(string response) returns string {
    string cleaned = response.trim();
    
    if cleaned.startsWith("```json") {
        cleaned = cleaned.substring(7);
    } else if cleaned.startsWith("```") {
        cleaned = cleaned.substring(3);
    }
    
    if cleaned.endsWith("```") {
        cleaned = cleaned.substring(0, cleaned.length() - 3);
    }
    
    return cleaned.trim();
}

isolated function extractText(json response) returns string|error {
    json|error candidatesJson = response.candidates;
    if candidatesJson is error {
        return error("No candidates in API response");
    }
    
    json[] candidates = check candidatesJson.ensureType();
    
    if candidates.length() == 0 {
        return error("Empty response from AI");
    }
    
    json content = check candidates[0].content;
    json[] parts = check content.parts.ensureType();
    
    if parts.length() == 0 {
        return error("No content parts in response");
    }
    
    string text = check parts[0].text.ensureType();
    return text;
}