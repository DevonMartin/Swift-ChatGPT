import XCTest
@testable import ChatGPTModel

final class ChatGPTModelTests: XCTestCase {
    func testOutputBudgetAmounts() async throws {
		print("")

		let models: [ChatGPTModel] = [
			.init(.gpt_3),
			.init(.gpt_3_16k),
			.init(.gpt_4),
			.init(.gpt_4_32k)
		]
		
		let messages: [ChatCompletion.Message] = [
			.init(role: .system, content: "Respond only \"test\""),
			.init(role: .user, content: "Hello!")
		]
		
		var additionAmount = 0.00001
		
		for model in models {
			
			while model.budget.output <= model.tokens.maxCost.output {
				
				model.budget.output += additionAmount
				
				let results = try await model.filterMessagesToFitBudget(messages)
				let (filteredMessages, maxOutputTokens) = results
				
				XCTAssert(filteredMessages.count == 2)
				XCTAssert(maxOutputTokens == nil || maxOutputTokens! < model.tokens.max)
			}
			
			additionAmount *= 10
		}
    }
}
