import XCTest
@testable import ChatGPTModel

final class ChatGPTModelTests: XCTestCase {
	
	private var testMessages: [ChatCompletion.Message] = [
		.init(role: .system, content: "Respond only \"test\""),
		.init(role: .user, content: "Hello!")
	]
	
    func testOutputBudgetAmounts() async throws {
		print("")

		let models: [ChatGPTModel] = [
			.init(.gpt_3),
			.init(.gpt_3_16k),
			.init(.gpt_4),
			.init(.gpt_4_32k)
		]
		
		var additionAmount = 0.00001
		
		for model in models {
			
			while model.budget.output <= model.tokens.maxCost.output {
				
				model.budget.output += additionAmount
				
				let results = try await model.filterMessagesToFitBudget(testMessages)
				let (filteredMessages, maxOutputTokens) = results
				
				XCTAssert(filteredMessages.count == 2)
				XCTAssert(maxOutputTokens == nil || maxOutputTokens! < model.tokens.max)
			}
			
			additionAmount *= 10
		}
    }
	
	func testServerCompatibility() async throws {
		struct AISandboxServerInput: Codable {
			let messages: [ChatCompletion.Message]
			let model: ChatGPTModel
			let temperature: Double
			let userID: String
		}
		
		struct AISandboxServerOutput: Codable {
			var message: ChatCompletion.Message? = nil
			var cost: Double? = nil
			var newBalance: Double? = nil
		}
		
		print("")
		
		let model = ChatGPTModel(.gpt_3)
		let userID = "sampleUserID1"
		
		let input = AISandboxServerInput(
			messages: testMessages,
			model: model,
			temperature: 0.75,
			userID: userID
		)
		
		let url = URL(string: "http://127.0.0.1:8080/api/chatCompletion")!
		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.setValue("application/json", forHTTPHeaderField: "Content-Type")
		req.httpBody = try JSONEncoder().encode(input)
		
		let session = URLSession.shared
		
		let (data, response) = try await session.data(for: req)
		
		let httpResponse = response as! HTTPURLResponse
		
		// 402 means "Payment Required", and is thrown when the server is unable to shorten the provided request
		// to an acceptable length.
		if httpResponse.statusCode == 402 {
			print("You don't have enough credits to send that message! Purchase more from the shop, or shorten your message.")
		}
		
		do {
			let output = try JSONDecoder().decode(AISandboxServerOutput.self, from: data)
			print(output)
		} catch {
			print("We had a problem processing the response from the server. Please try again.")
			let output = try JSONDecoder().decode(
				ChatCompletion.BadResponse.OpenAIError.self,
				from: data
			)
			print(output)
		}
	}
}
