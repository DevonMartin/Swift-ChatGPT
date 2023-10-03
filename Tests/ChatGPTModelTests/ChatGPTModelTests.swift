import XCTest
@testable import ChatGPTModel

final class ChatGPTModelTests: XCTestCase {
    func testExample() async throws {

		let model = ChatGPTModel(.gpt_3, priceAdjustmentFactor: 1, dateSuffix: nil)
		let messages: [OpenAiApiMessage] = [
			.init(role: .system, content: "Respond only \"test\""),
			.init(role: .user, content: "Hello!")
		]
		
		let filtered = try await model.filterMessagesToFitBudget(messages)
		
		XCTAssert(filtered.messages.count == 2)
    }
}
