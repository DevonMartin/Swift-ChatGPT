// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Tiktoken

public struct ChatGPTModel: Identifiable, Codable {
	private static var counter: Tiktoken?
	private let baseTokenCostDivisor: Double
	
	// MARK: - Properties
	
	public let base: ChatGPTBaseModel
	public let priceAdjustmentFactor: Double
	public let dateSuffix: String?
	public var budget: ChatGPTBudget { base.budget }
	
	public var tokens: (
		max: Int,
		cost: (input: Double, output: Double),
		maxCost: (input: Double, output: Double)
	) {
		let max = base.tokens.max
		let baseCost = base.tokens.cost
		
		let cost: (input: Double, output: Double) = (
			input: baseCost.input / baseTokenCostDivisor * priceAdjustmentFactor,
			output: baseCost.output / baseTokenCostDivisor * priceAdjustmentFactor
		)
		
		return (
			max: max,
			cost: cost,
			maxCost: (input: cost.input * Double(max), output: cost.output * Double(max))
		)
	}
	
	/// A unique identifier for the ChatGPT Model that the OpenAI API will accept.
	public var id: String {
		if let dateSuffix { base.id + "-" + dateSuffix }
		else { base.id }
	}
	
	/// A properly-capitalized name of the ChatGPT Model.
	public var name: String {
		let components = self.id.components(separatedBy: "-")
		let capitalizedComponents = components.map { component in
			if component == "gpt" { return "GPT" }
			if let firstCharacter = component.first, firstCharacter.isLetter {
				return component.capitalized
			} else {
				return component
			}
		}
		var formattedName = capitalizedComponents.joined(separator: "-")
		formattedName = formattedName.replacingOccurrences(of: "GPT-3.5-Turbo", with: "GPT-3")
		
		if let last = capitalizedComponents.last,
		   let (modelDateNumber, dateString) = Date.parse(string: last) {
			formattedName = formattedName.replacingOccurrences(
				of: "-\(modelDateNumber)",
				with: " \(dateString) version"
			)
		}
		
		return formattedName
	}
	
	// MARK: - Initializer
	
	public init(_ base: ChatGPTBaseModel, priceAdjustmentFactor: Double = 1, dateSuffix: String? = nil) {
		if Self.counter == nil { Task { Self.counter = await .init() } }
		
		baseTokenCostDivisor = 1000
		
		self.base = base
		self.priceAdjustmentFactor = priceAdjustmentFactor
		self.dateSuffix = dateSuffix
	}
	
	public init(id: String, priceAdjustmentFactor: Double = 1) {
		var id = id.lowercased()
		var dateSuffix: String?
		
		var components = id.components(separatedBy: "-")
		
		if let last = components.last,
		   let (number, _) = Date.parse(string: last) {
			
			dateSuffix = number
			let _ = components.removeLast()
			id = components.map {$0}.joined(separator: "-")
		}
		
		guard let base = ChatGPTBaseModel.get(from: id) else {
			fatalError("Unable to parse provided ID and find a valid GPT model.")
		}
		
		self.init(base, priceAdjustmentFactor: priceAdjustmentFactor, dateSuffix: dateSuffix)
	}
	
	// MARK: - API
	
	public func filterMessagesToFitBudget(
		_ messages: [OpenAiApiMessage],
		maxBudget: Double = .infinity
	) async throws -> (messages: [OpenAiApiMessage], maxOutputTokens: Int?) {
		
		guard !messages.isEmpty else { throw OpenAiApiError.emptyMessageArray }
		
		let (inputTokenBudget, affordableOutputTokens) = getTokenBudgets(maxBudget)
		let (filteredMessages, tokenUsage) = try await filter(messages, budget: inputTokenBudget)
		
		// Calculate maximum output tokens
		var maxOutputTokens: Int? = min(tokens.max - tokenUsage, affordableOutputTokens)
		maxOutputTokens = maxOutputTokens! > 0 ? maxOutputTokens : nil
		
		return (messages: filteredMessages, maxOutputTokens: maxOutputTokens)
	}
	
	// MARK: - Helper Functions
	
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
		let inputTokenBudget = Int(floor(inputBudget / tokens.cost.input))
		let affordableOutputTokens = Int(floor(affordableOutputCost / tokens.cost.output))
		
		return (inputTokenBudget, affordableOutputTokens)
	}
	
	internal func filter(
		_ messages: [OpenAiApiMessage],
		budget: Int
	) async throws -> (filteredMessages: [OpenAiApiMessage], tokenUsage: Int) {
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
	
	private func calculateTokenUsage(from messages: [OpenAiApiMessage]) async -> Int {
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
