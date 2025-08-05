import XCTest
@testable import ChatGPT

final class ChatGPTTests: XCTestCase {
	
	private var testMessages: [ChatCompletion.Message] = [
		.init(role: .system, content: "Respond only \"test\""),
		.init(role: .user, content: "Hello!")
	]
	
    func testOutputBudgetAmounts() async throws {
		print("")

		let models: [ChatGPTModel] = [
			.init(.gpt35Turbo),
			.init(.gpt4),
		]
		
		var additionAmount = 0.00001
		
		for model in models {
			
			while model.budget.output <= model.tokens.maxCost.output {
				
				model.budget.output += additionAmount
				
				let results = try await model.filterMessagesToFitBudget(testMessages)
				let (filteredMessages, maxOutputTokens) = results
				
				XCTAssert(filteredMessages.count == 2)
				XCTAssert(maxOutputTokens == nil || maxOutputTokens! < model.tokens.max.output)
			}
			
			additionAmount *= 10
		}
    }
	
	func testAvailableModels() async throws {
		let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
		let models = try await Models.fetchChatCompletion(
			with: apiKey,
			priceAdjustmentFactor: 2
		)
		
		models.sorted(by: { $0.name < $1.name }).forEach {
			print("\($0.name) has an ID of: \($0.id)")
		}
	}
	
	func testServerCompatibility() async throws {
		struct AISandboxServerInput: Codable {
			let messages: [ChatCompletion.Message]
			let model: ChatGPTModel
			let temperature: Double
			let user: String
		}
		
		struct AISandboxServerOutput: Codable {
			var message: ChatCompletion.Message
			var cost: Double
			var newBalance: Double? = nil
		}
		
		print("")
		
		let model = ChatGPTModel(.gpt35Turbo, priceAdjustmentFactor: 1)
		
		let userID = "sampleUserID1"
		
		let input = AISandboxServerInput(
			messages: testMessages,
			model: model,
			temperature: 0.75,
			user: userID
		)
		
		let url = URL(string: "http://127.0.0.1:8080/api/chatCompletion")!
		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.setValue("application/json", forHTTPHeaderField: "Content-Type")
		req.httpBody = try JSONEncoder().encode(input)
		
		let session = URLSession.shared
		
		let (data, response) = try await session.data(for: req)
		
		let httpResponse = response as! HTTPURLResponse
		
		// 402 means "Payment Required", and is thrown when the server is unable to shorten the 
		// provided request to an acceptable length.
		if httpResponse.statusCode == 402 {
			print("""
You don't have enough credits to send that message! Purchase more from the shop, or shorten your \
message.
""")
		}
		
		do {
			let output = try JSONDecoder().decode(AISandboxServerOutput.self, from: data)
			print(String(format: "%.6f", output.cost))
		} catch {
			print("We had a problem processing the response from the server:\n\(error)\n")
				
			if let jsonString = String(data: data, encoding: .utf8) {
				print("Raw JSON:\n\(jsonString)\n")
				
				// Handle your custom server error format
				struct CustomServerError: Decodable {
					let error: Bool
					let reason: String
				}
				
				if let customError = try? JSONDecoder().decode(CustomServerError.self, from: data) {
					print("Custom server error:\n\(customError.reason)\n")
					XCTAssertEqual(customError.reason, "noUser")
				} else if let output = try? JSONDecoder().decode(
					ChatCompletion.BadResponse.OpenAIError.self,
					from: data
				 ) {
					 print(output)
				 }
			} else {
				print("Failed to convert data to string")
			}
		}
		
		print("")
	}
}
