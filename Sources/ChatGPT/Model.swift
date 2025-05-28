// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Tiktoken

public struct ChatGPTModel: Codable, Identifiable, Equatable, Hashable {
	
	private static var counter: Tiktoken?
	private let baseTokenCostDivisor: Double
	
	// MARK: - Properties -
	
	public let base: ChatGPTBaseModel
	public let priceAdjustmentFactor: Double
	public var budget: ChatGPTBudget { base.budget }
	
	public var tokens: (
		max: (input: Int, output: Int),
		costPerToken: (input: Double, output: Double),
		maxCost: (input: Double, output: Double)
	) {
		let max = base.tokens.max
		let baseCostPer1K = base.tokens.cost
		
		let costPerToken: (input: Double, output: Double) = (
			input: baseCostPer1K.input / baseTokenCostDivisor * priceAdjustmentFactor,
			output: baseCostPer1K.output / baseTokenCostDivisor * priceAdjustmentFactor
		)
		
		return (
			max: max,
			costPerToken: costPerToken,
			maxCost: (
				input: costPerToken.input * Double(max.input),
				output: costPerToken.output * Double(max.output)
			)
		)
	}
	
	/// A unique identifier for the ChatGPT Model that the OpenAI API will accept.
	public var id: String { base.id }
	
	/// A properly-capitalized name of the ChatGPT Model.
	public var name: String {
		let components = self.id.components(separatedBy: "-")
		let capitalizedComponents = components.compactMap { component in
			if component == "gpt" { return "GPT" }
			else if ["o1", "o4", "mini", "nano"].contains(component) { return component }
			else if let first = component.first, first.isLetter { return component.capitalized }
			else { return component }
		}
		
		return capitalizedComponents
			.joined(separator: "-")
			.replacingOccurrences(of: "GPT-3.5-Turbo", with: "GPT-3")
		
		// Models with dates in their names are no longer used.
		// Uncomment the below code if this changes.
		
//		var formattedName = capitalizedComponents.joined(separator: "-")
//		formattedName = formattedName.replacingOccurrences(of: "GPT-3.5-Turbo", with: "GPT-3")
//
//		if let last = capitalizedComponents.last,
//		   let (modelDateNumber, dateString) = Date.parse(string: last) {
//			formattedName = formattedName.replacingOccurrences(
//				of: "-\(modelDateNumber)",
//				with: " \(dateString) version"
//			)
//		}
//		
//		return formattedName
	}
	
	// MARK: - Initializer -
	
	public init(
		_ base: ChatGPTBaseModel,
		priceAdjustmentFactor: Double = 1
	) {
		if Self.counter == nil { Task { Self.counter = await .init() } }
		
		baseTokenCostDivisor = 1000
		
		self.base = base
		self.priceAdjustmentFactor = priceAdjustmentFactor
	}
	
	public init(id: String, priceAdjustmentFactor: Double = 1) {
		let base = ChatGPTBaseModel.get(from: id.lowercased()) ?? .gpt35Turbo
		self.init(base, priceAdjustmentFactor: priceAdjustmentFactor)
	}
	
	// MARK: - API -
	
	public func filterMessagesToFitBudget(
		_ messages: [ChatCompletion.Message],
		maxBudget: Double = .infinity
	) async throws -> (messages: [ChatCompletion.Message], maxOutputTokens: Int?) {
		
		guard !messages.isEmpty else { throw OpenAiApiError.emptyMessageArray }
		
		let (inputTokenBudget, affordableOutputTokens) = getTokenBudgets(maxBudget)
		let (filteredMessages, _) = try await filter(messages, budget: inputTokenBudget)
		
		// Calculate maximum output tokens
		var maxOutputTokens: Int? = min(tokens.max.output, affordableOutputTokens)
		if maxOutputTokens! <= 0 { maxOutputTokens = nil }
		
		return (messages: filteredMessages, maxOutputTokens: maxOutputTokens)
	}
    
    public func countTokens(for messages: [ChatCompletion.Message]) async -> Int {
        await calculateTokenUsage(from: messages)
    }
    
    public func countTokens(for message: ChatCompletion.Message) async -> Int {
        await calculateTokenUsage(from: [message])
    }
	
	// MARK: - Helper Functions -
	
	private func getTokenBudgets(
		_ maxBudget: Double
	) -> (inputTokenBudget: Int, affordableOutputTokens: Int) {
		// Calculate affordable input and output costs
		let affordableInputCost = min(maxBudget, budget.input)
		let affordableOutputCost = min(maxBudget, budget.output)
		
		// Determine the input budget
		let designatedInputBudget = Double(tokens.maxCost.input) * 0.75
		let inputBudget = affordableInputCost > 0
		? min(affordableInputCost, designatedInputBudget)
		: designatedInputBudget
		
		// Your max tokens can be calculated by your budget divided by the cost of each token.
		let inputTokenBudget = Int(floor(inputBudget / tokens.costPerToken.input))
		let affordableOutputTokens = Int(floor(affordableOutputCost / tokens.costPerToken.output))
		
		return (inputTokenBudget, affordableOutputTokens)
	}
	
	internal func filter(
		_ messages: [ChatCompletion.Message],
		budget: Int
	) async throws -> (filteredMessages: [ChatCompletion.Message], tokenUsage: Int) {
		// Ensure at least two messages in the response to avoid only sending a system message
		let minimumMessages = min(2, messages.count)
		
		var filteredMessages = messages
		var tokenUsage = await calculateTokenUsage(from: filteredMessages)
		
		// Remove messages to fit within the input token budget
		while tokenUsage > budget
				&& filteredMessages.count >= minimumMessages {
			filteredMessages.remove(at: 1)
			tokenUsage = await calculateTokenUsage(from: filteredMessages)
		}
		
		guard filteredMessages.count >= minimumMessages else { throw OpenAiApiError.cannotAfford }
		return (filteredMessages, tokenUsage)
	}
	
	private func calculateTokenUsage(from messages: [ChatCompletion.Message]) async -> Int {
		var concatenatedMessages = ""
		for message in messages {
			let role = "role: " + message.role
			let content = "content: " + message.content
			
			concatenatedMessages += "\(role) \(content)"
		}
		
		if Self.counter == nil {
			Self.counter = await .init()
		}
		
		let count = Self.counter!.count(concatenatedMessages)
		return count
	}
}

public enum OpenAiApiError: Error {
	case cannotAfford, emptyMessageArray
	
	var description: String {
		switch self {
			case .cannotAfford: "The provided messages cannot be processed within your budget."
			case .emptyMessageArray: "Your array is empty."
		}
	}
}
