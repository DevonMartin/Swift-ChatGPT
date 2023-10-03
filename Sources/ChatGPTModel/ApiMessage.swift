//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

public struct OpenAiApiMessage: Codable {
	let role: String
	let content: String
	
	init(role: Role, content: String) {
		self.role = role.rawValue
		self.content = content
	}
	
	enum Role: String {
		case system = "system"
		case user = "user"
		case assistant = "assistant"
	}
}
