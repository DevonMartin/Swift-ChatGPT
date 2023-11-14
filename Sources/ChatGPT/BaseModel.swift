//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

import Foundation

public struct ChatGPTBaseModel: Codable, Equatable, Hashable {
	
	public var id: String { base.id }
	
	internal var tokens: (max: (input: Int, output: Int), cost: (input: Double, output: Double)) {
		base.tokens
	}
	
	internal var budget: ChatGPTBudget {
		switch base {
			case .gpt3: .gpt3
			case .gpt4: .gpt4
		}
	}
	
	private let base: ChatGPTBaseModelEnum
	
	fileprivate init(_ base: ChatGPTBaseModelEnum) {
		self.base = base
	}
	
	public static let gpt_3 = ChatGPTBaseModel(.gpt3)
	public static let gpt_4 = ChatGPTBaseModel(.gpt4)
	
	internal static func get(from id: String) -> ChatGPTBaseModel? {
		
		for model in ChatGPTBaseModelEnum.allCases.sorted(by: { $0.id.count > $1.id.count }) {
			if id.contains(model.id) {
				switch model {
					case .gpt3: return .gpt_3
					case .gpt4: return .gpt_4
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
	case gpt3 = "gpt-3.5-turbo-1106"
	case gpt4 = "gpt-4-1106-preview"
	
	fileprivate var id: String { self.rawValue }
	
	fileprivate var tokens: (max: (input: Int, output: Int), cost: (input: Double, output: Double)) {
		switch self { // Updated to reflect changed prices from ~11/7/23
			case .gpt3:   (max: (input: 12288, output: 4096),  cost: (input: 0.001, output: 0.002))
			case .gpt4:   (max: (input: 123904, output: 4096),  cost: (input: 0.01,   output: 0.03))
		}
	}
}
