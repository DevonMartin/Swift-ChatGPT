//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

public struct OpenAiApiMessage: Codable {
	public let role: String
	public let content: String
	
	public init(role: Role, content: String) {
		self.role = role.rawValue
		self.content = content
	}
	
	public enum Role: String {
		case system = "system"
		case user = "user"
		case assistant = "assistant"
	}
}
