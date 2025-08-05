# ChatGPT Swift Package

A reusable Swift package for interacting with the OpenAI ChatGPT API. Handles model selection, token counting, cost estimation, and message filtering to fit budgets. Shared between AI Sandbox app and server.

## Features
- Supports models like GPT-3.5-Turbo, GPT-4o, o1 (with token limits and costs).
- Token counting via Tiktoken.
- Budget-aware message filtering to avoid API errors.
- Codable, Equatable, Hashable structs for easy integration.

## Installation
Add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/your-repo/ChatGPT.git", .upToNextMajor(from: "1.0.0"))
]
```
Then in targets: `.product(name: "ChatGPT", package: "ChatGPT")`.

## Usage
```swift
import ChatGPT

// Initialize a model
let model = ChatGPTModel(.)

// Filter messages to fit budget
let messages: [ChatCompletion.Message] = [...]  // Your chat messages
do {
    let (filtered, maxOutput) = try await model.filterMessagesToFitBudget(messages, maxBudget: 0.50)  // e.g., $0.50 limit
    print("Filtered messages: \(filtered.count), Max output tokens: \(maxOutput ?? 0)")
} catch {
    print(error.localizedDescription)
}

// Count tokens
let tokenCount = await model.countTokens(for: messages)
```

## Models & Budgeting
Models are predefined in `ChatGPTBaseModel`. Budgets use `ChatGPTBudget`. Costs are per 1K tokens, adjustable via `priceAdjustmentFactor`.

## Dependencies
- [Tiktoken](https://github.com/DevonMartin/Tiktoken) for token encoding.

## License
MIT.
