//
//  Budget.swift
//
//
//  Created by Devon Martin on 10/4/23.
//

import Foundation

#if !SERVER
@Observable
#endif
public class ChatGPTBudget: Codable {
	public var input: Double { didSet { save() } }
	public var output: Double { didSet { save() } }
	
	private let key: String
	
	private init(key: String, input: Double, output: Double) {
		self.key = key
		self.input = input
		self.output = output
	}
	
	static let gpt3 = get(from: gpt3Key) ?? .init(key: gpt3Key, input: 0.002, output: 0.005)
	static let gpt4 = get(from: gpt4Key) ?? .init(key: gpt4Key, input: 0.05, output: 0.1)
	
	private static let gpt3Key = "ChatGPTModel.Budget.3"
	private static let gpt4Key = "ChatGPTModel.Budget.4"
	
	private static func get(from key: String) -> ChatGPTBudget? {
		guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
		return try? JSONDecoder().decode(ChatGPTBudget.self, from: data)
	}
	
	private func save() {
		do {
			let data = try JSONEncoder().encode(self)
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			let components = key.split(separator: "-")
			let model = components.last ?? "unknown"
			print("""

Failed to save budget data for base model: \(model)
Error: \(error.localizedDescription)

""")
		}
	}
}
