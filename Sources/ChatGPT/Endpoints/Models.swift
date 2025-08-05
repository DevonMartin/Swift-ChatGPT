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
		guard let url = URL(string: endpointURL) else {
			throw AvailableModelsError.invalidURL
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
		
		return try await withCheckedThrowingContinuation { continuation in
			URLSession.shared.dataTask(with: request) { data, response, error in
				if let error {
					continuation.resume(throwing: error)
					return
				}
				
				guard let httpResponse = response as? HTTPURLResponse else {
					continuation.resume(throwing: AvailableModelsError.networkFailure)
					return
				}
				
				guard httpResponse.statusCode == 200, let data else {
					if httpResponse.statusCode == 401 {
						continuation.resume(throwing: AvailableModelsError.badKey)
					} else {
						continuation.resume(throwing: AvailableModelsError.badResponse(status: httpResponse.statusCode))
					}
					return
				}
				
				do {
					let decodedModels = try JSONDecoder().decode(Models.self, from: data)
					continuation.resume(returning: decodedModels.data ?? [])
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
		
		let preferredModelIDs: Set<String> = [
			"gpt-4o",
			"gpt-4.5-preview",
			"gpt-4-turbo",
			"gpt-4",
			"gpt-4.1",
			"o1",
			"gpt-4o-mini",
			"gpt-4.1-mini",
			"gpt-4.1-nano",
			"o4-mini",
			"gpt-3.5-turbo"
		]
		
		let allAvailableModels = try await fetchAll(with: apiKey)
		
		let curatedModels = allAvailableModels.filter { preferredModelIDs.contains($0.id) }
		
		return curatedModels.map {
			ChatGPTModel(id: $0.id, priceAdjustmentFactor: priceAdjustmentFactor)
		}
	}
	
	enum AvailableModelsError: Error {
		case invalidURL
		case networkFailure
		case badKey
		case badResponse(status: Int)
		
		var description: String {
			switch self {
			case .invalidURL: "Invalid URL for models endpoint."
			case .networkFailure: "No HTTP response received."
			case .badKey: "Invalid API key (401 unauthorized)."
			case .badResponse(let status): "API error (status \(status))."
			}
		}
	}
}
