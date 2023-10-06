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
public struct Models: Codable {
	
	/// API endpoint URL for fetching available GPT models.
	private static let endpointURL = "https://api.openai.com/v1/models"
	
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

extension Models {
	
	/// Fetches the list of available GPT models using the provided API key.
	///
	/// - Parameter apiKey: An API key for authenticating with OpenAI's API, obtainable at
	/// [OpenAI's website](https://platform.openai.com/account/api-keys).
	/// - Returns: An array of `Model` objects representing the accessible GPT models.
	/// - Throws: An error if the request fails.
	public static func fetchAll(with apiKey: String) async throws -> [Model] {
		return try await withCheckedThrowingContinuation { continuation in
			var request = URLRequest(url: URL(string: endpointURL)!)
			request.httpMethod = "GET"
			request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
			
			URLSession.shared.dataTask(with: request) { data, response, error in
				guard error == nil else { 
					print("\nError is not null: \(error!)\n")
					continuation.resume(throwing: error!)
					return
				}
				
				guard let data else {
					print("\nData is null.\n")
					continuation.resume(throwing: AvailableModelsError.badKey)
					return
				}
				
				do {
					let decodedModels = try JSONDecoder().decode(Models.self, from: data)
					if let models = decodedModels.data {
						continuation.resume(returning: models)
					} else {
						print("decodedModels is null.")
						continuation.resume(throwing: AvailableModelsError.badKey)
					}
					
				} catch {
					continuation.resume(throwing: error)
				}
			}.resume()
		}
	}
	
	/// Fetches the list of available GPT models compatible with the `Chat Completion` endpoint.
	///
	/// - Parameter apiKey: An API key for authenticating with OpenAI's API, obtainable at
	/// [OpenAI's website](https://platform.openai.com/account/api-keys).
	///	- Parameter priceAdjustmentFactor: The factor to multiply the cost of tokens by, to impact how quickly budgets are used up. Defaults to 1, meaninng tokens are priced exactly as OpenAI charges.
	/// - Returns: An array of `ChatGPTModel` objects representing the accessible GPT models.
	/// - Throws: An error if the request fails.
	public static func fetchChatCompletion(
		with apiKey: String,
		priceAdjustmentFactor: Double = 1
	) async throws -> [ChatGPTModel] {
		try await fetchAll(with: apiKey).filter {
			$0.id.contains("gpt") &&
			!$0.id.contains("instruct")
		}.map {
			ChatGPTModel(id: $0.id, priceAdjustmentFactor: priceAdjustmentFactor)
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
