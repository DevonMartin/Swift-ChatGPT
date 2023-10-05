//
//  Models.swift
//
//
//  Created by Devon Martin on 10/5/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Represents data and operations for fetching a list of GPT models accessible via a given API key.
public struct AvailableModels {
	
	/// API endpoint URL for fetching available GPT models.
	private static let endpointURL = "https://api.openai.com/v1/models"
	
	/// Encapsulates the response data for available GPT models.
	public struct Models: Codable {
		
		/// An array of available GPT models.
		public let data: [Model]?
		
		/// Represents a single GPT model.
		public struct Model: Codable {
		
			/// Unique identifier for the model.
			public let id: String
			
			/// Timestamp for model creation.
			public let created: Int
			
			/// Ownership information for the model.
			public let ownedBy: OwnedBy
			
			/// Root identifier for the model.
			public let root: String
			
			private enum CodingKeys: String, CodingKey {
				case id, created
				case ownedBy = "owned_by"
				case root
			}
			
			/// Enumerates possible owners of a GPT model.
			public enum OwnedBy: String, Codable {
				case openai = "openai"
				case openaiDev = "openai-dev"
				case openaiInternal = "openai-internal"
				case system = "system"
			}
		}
	}
}

extension AvailableModels {
	public static func fetchAll(with apiKey: String) async throws -> [Models.Model] {
		return try await withCheckedThrowingContinuation { continuation in
			var request = URLRequest(url: URL(string: endpointURL)!)
			request.httpMethod = "GET"
			request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
			
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				if let error = error {
					continuation.resume(throwing: error)
				} else if let data {
					do {
						let decodedModels = try JSONDecoder().decode(Models.self, from: data)
						continuation.resume(returning: decodedModels.data ?? [])
					} catch {
						continuation.resume(throwing: error)
					}
				}
			}
			task.resume()
		}
	}
	
	public static func fetchChatCompletion(with apiKey: String) async throws -> [Models.Model] {
		try await fetchAll(with: apiKey).filter {
			$0.id.contains("gpt") &&
			!$0.id.contains("instruct")
		}
	}
	
	enum AvailableModelsError: Error {
		case badKey
		
		var description: String {
			switch self {
				case .badKey:
					"Your API key didn't return any results. It is invalid."
			}
		}
	}
}
