//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

public class ChatGPTBaseModel: Codable {
	private let base: ChatGPTBaseModelEnum
	internal var budget: Budget
	
	internal var id: String { base.id }
	internal var tokens: (max: Int, cost: (input: Double, output: Double)) { base.tokens }
	
	internal init(_ base: ChatGPTBaseModelEnum, budget: Budget) {
		self.base = base
		self.budget = budget
	}
	
	static let gpt_3   = ChatGPTBaseModel(.gpt3, budget: .init(input: 0.0075, output: 0.0025))
	static let gpt_3_16k = ChatGPTBaseModel(.gpt16k, budget: .init(input: 0.015, output: 0.005))
	static let gpt_4   = ChatGPTBaseModel(.gpt4, budget: .init(input: 0.075, output: 0.025))
	static let gpt_4_32k = ChatGPTBaseModel(.gpt32k, budget: .init(input: 0.15, output: 0.25))
	
	public class Budget: Codable {
		var input: Double
		var output: Double
		
		init(input: Double, output: Double) {
			self.input = input
			self.output = output
		}
	}
}

enum ChatGPTBaseModelEnum: String, CaseIterable, Codable {
	case gpt3 = "gpt-3.5-turbo"
	case gpt16k = "gpt-3.5-turbo-16k"
	case gpt4 = "gpt-4"
	case gpt32k = "gpt-4-32k"
	
	fileprivate var id: String { self.rawValue }
	
	fileprivate var tokens: (max: Int, cost: (input: Double, output: Double)) {
		switch self {
			case .gpt3:   (max: 4097,  cost: (input: 0.0015, output: 0.002))
			case .gpt16k: (max: 16385, cost: (input: 0.003,  output: 0.004))
			case .gpt4:   (max: 8192,  cost: (input: 0.03,   output: 0.06))
			case .gpt32k: (max: 32768, cost: (input: 0.06,   output: 0.12))
		}
	}
}
