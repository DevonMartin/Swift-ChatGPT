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
		case .gpt35Turbo: .gpt3
		case .gpt4: .gpt4
//		case .gpt4Turbo:
//		case .gpt4o:
//		case .gpt4oMini:
//		case .gpt41:
//		case .gpt41Mini:
//		case .gpt41Nano:
//		case .gpt45Preview:
//		case .o1:
//		case .o4Mini:
		default: .gpt3
		}
	}
	
	private let base: ChatGPTBaseModelEnum
	
	fileprivate init(_ base: ChatGPTBaseModelEnum) {
		self.base = base
	}
	
	public static let gpt35Turbo = ChatGPTBaseModel(.gpt35Turbo)
	public static let gpt4 = ChatGPTBaseModel(.gpt4)
	public static let gpt4Turbo = ChatGPTBaseModel(.gpt4Turbo)
	public static let gpt4o = ChatGPTBaseModel(.gpt4o)
	public static let gpt4oMini = ChatGPTBaseModel(.gpt4oMini)
	public static let gpt41 = ChatGPTBaseModel(.gpt41)
	public static let gpt41Mini = ChatGPTBaseModel(.gpt41Mini)
	public static let gpt41Nano = ChatGPTBaseModel(.gpt41Nano)
	public static let gpt45Preview = ChatGPTBaseModel(.gpt45Preview)
	public static let o1 = ChatGPTBaseModel(.o1)
	public static let o4Mini = ChatGPTBaseModel(.o4Mini)
	
	internal static func get(from id: String) -> ChatGPTBaseModel? {
		
		for model in ChatGPTBaseModelEnum.allCases.sorted(by: { $0.id.count > $1.id.count }) {
			if id.contains(model.id) {
				switch model {
				case .gpt35Turbo: return gpt35Turbo
				case .gpt4: return gpt4
				case .gpt4Turbo: return gpt4Turbo
				case .gpt4o: return gpt4o
				case .gpt4oMini: return gpt4oMini
				case .gpt41: return gpt41
				case .gpt41Mini: return gpt41Mini
				case .gpt41Nano: return gpt41Nano
				case .gpt45Preview: return gpt45Preview
				case .o1: return o1
				case .o4Mini: return o4Mini
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
	case gpt35Turbo = "gpt-3.5-turbo"
	
	case gpt4 = "gpt-4"
	case gpt4Turbo = "gpt-4-turbo"
	
	case gpt4o = "gpt-4o"
	case gpt4oMini = "gpt-4o-mini"
	
	case gpt41 = "gpt-4.1"
	case gpt41Mini = "gpt-4.1-mini"
	case gpt41Nano = "gpt-4.1-nano"
	
	case gpt45Preview = "gpt-4.5-preview"
	
	case o1 = "o1"
	
	case o4Mini = "o4-mini"
	
	fileprivate var id: String { self.rawValue }
	
	fileprivate var tokens: (max: (input: Int, output: Int), cost: (input: Double, output: Double)) {
		switch self {
		case .gpt35Turbo:
			(max: (input: 16385 - 4096, output: 4096), cost: (input: 0.0005, output: 0.0015))
			
		case .gpt4:
			(max: (input: 8192 - 4096, output: 4096), cost: (input: 0.03, output: 0.06))
		case .gpt4Turbo:
			(max: (input: 128000 - 4096, output: 4096), cost: (input: 0.01, output: 0.03))
			
		case .gpt4o:
			(max: (input: 128000 - 16384, output: 16384), cost: (input: 0.0025, output: 0.01))
		case .gpt4oMini:
			(max: (input: 128000 - 16384, output: 16384), cost: (input: 0.00015, output: 0.0006))
			
		case .gpt41:
			(max: (input: 1047576 - 32768, output: 32768), cost: (input: 0.002, output: 0.008))
		case .gpt41Mini:
			(max: (input: 1047576 - 32768, output: 32768), cost: (input: 0.0004, output: 0.0016))
		case .gpt41Nano:
			(max: (input: 1047576 - 32768, output: 32768), cost: (input: 0.0001, output: 0.0004))
			
		case .gpt45Preview:
			(max: (input: 128000 - 16384, output: 16384), cost: (input: 0.075, output: 0.15))
			
		case .o1:
			(max: (input: 200000 - 100000, output: 100000), cost: (input: 0.015, output: 0.06))
			
		case .o4Mini:
			(max: (input: 200000 - 100000, output: 100000), cost: (input: 0.0011, output: 0.0044))
		}
	}
}
