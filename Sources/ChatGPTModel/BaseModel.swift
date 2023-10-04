//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

import Foundation

public struct ChatGPTBaseModel: Codable, Equatable {
	
	public var id: String { base.id }
	
	internal var tokens: (max: Int, cost: (input: Double, output: Double)) { base.tokens }
	internal var budget: ChatGPTBudget {
		switch base {
			case .gpt3: .gpt3
			case .gpt16k: .gpt16k
			case .gpt4: .gpt4
			case .gpt32k: .gpt32k
		}
	}
	
	private let base: ChatGPTBaseModelEnum
	
	fileprivate init(_ base: ChatGPTBaseModelEnum) {
		self.base = base
	}
	
	public static let gpt_3 = ChatGPTBaseModel(.gpt3)
	public static let gpt_3_16k = ChatGPTBaseModel(.gpt16k)
	public static let gpt_4 = ChatGPTBaseModel(.gpt4)
	public static let gpt_4_32k = ChatGPTBaseModel(.gpt32k)
	
	internal static func get(from id: String) -> ChatGPTBaseModel? {
		
		for model in ChatGPTBaseModelEnum.allCases.sorted(by: { $0.id.count > $1.id.count }) {
			if id.contains(model.id) {
				switch model {
					case .gpt3: return .gpt_3
					case .gpt16k: return .gpt_3_16k
					case .gpt4: return .gpt_4
					case .gpt32k: return .gpt_4_32k
				}
			}
		}
		
		return nil
	}
	
	public static func == (lhs: ChatGPTBaseModel, rhs: ChatGPTBaseModel) -> Bool {
		lhs.base == rhs.base
	}
}

fileprivate enum ChatGPTBaseModelEnum: String, CaseIterable, Codable {
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
