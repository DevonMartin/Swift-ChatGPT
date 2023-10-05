//
//  API.swift
//
//
//  Created by Devon Martin on 10/3/23.
//

import Foundation

public struct ChatCompletion {
	
	/// Creates a model response for the given chat conversation via `POST https://api.openai.com/v1/chat/completions` with an API key
	/// in the `Bearer Authorization` parameter of the `header`.
	public struct Request: Codable {
		
		/// ID of the model to use. See the
		/// [model endpoint compatibility table](https://platform.openai.com/docs/models/model-endpoint-compatibility)
		/// for details on which models work with the Chat API.
		public let model: String
		
		/// A list of messages comprising the conversation so far.
		public let messages: [Message]
		
		/// What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will 
		/// make it more focused and deterministic.
		///
		/// We generally recommend altering this or `top_p` but not both.
		public let temperature: Double?
		
		/// An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p 
		/// probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
		///
		/// We generally recommend altering this or `temperature` but not both.
		public let topP: Double?
		
		/// How many chat completion choices to generate for each input message.
		public let n: Double?
		
		/// If set, partial message deltas will be sent, like in ChatGPT. Tokens will be sent as data-only
		/// [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with
		/// the stream terminated by a `data: [DONE]` message.
		public let stream: Bool?
		
		/// Up to 4 sequences where the API will stop generating further tokens.
		public let stop: [String]?
		
		/// The maximum number of [tokens](https://platform.openai.com/tokenizer) to generate in the chat completion.
		///
		/// The total length of input tokens and generated tokens is limited by the model's context length.
		public let maxTokens: Int?
		
		/// Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.
		///
		/// [See more information about frequency and presence penalties.](https://platform.openai.com/docs/guides/gpt/parameter-details)
		public let presencePenalty: Double?
		
		/// Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.
		///
		/// [See more information about frequency and presence penalties.](https://platform.openai.com/docs/guides/gpt/parameter-details)
		public let frequencyPenalty: Double?
		
		/// A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](https://platform.openai.com/docs/guides/safety-best-practices/end-user-ids).
		public let user: String?
		
		enum CodingKeys: String, CodingKey {
			case model
			case messages
			case temperature
			case topP = "top_p"
			case n
			case stream
			case stop
			case maxTokens = "max_tokens"
			case presencePenalty = "presence_penalty"
			case frequencyPenalty = "frequency_penalty"
			case user
		}
		
		// Initialize with temperature
		public init(
			model: String,
			messages: [Message],
			temperature: Double? = nil,
			n: Double? = nil,
			stream: Bool? = nil,
			stop: [String]? = nil,
			maxTokens: Int? = nil,
			presencePenalty: Double? = nil,
			frequencyPenalty: Double? = nil,
			user: String? = nil
		) {
			self.model = model
			self.messages = messages
			self.temperature = temperature
			self.topP = nil
			self.n = n
			self.stream = stream
			self.stop = stop
			self.maxTokens = maxTokens
			self.presencePenalty = presencePenalty
			self.frequencyPenalty = frequencyPenalty
			self.user = user
		}
		
		// Initialize with topP
		public init(
			model: String,
			messages: [Message],
			topP: Double? = nil,
			n: Double? = nil,
			stream: Bool? = nil,
			stop: [String]? = nil,
			maxTokens: Int? = nil,
			presencePenalty: Double? = nil,
			frequencyPenalty: Double? = nil,
			user: String? = nil
		) {
			self.model = model
			self.messages = messages
			self.temperature = nil
			self.topP = topP
			self.n = n
			self.stream = stream
			self.stop = stop
			self.maxTokens = maxTokens
			self.presencePenalty = presencePenalty
			self.frequencyPenalty = frequencyPenalty
			self.user = user
		}
	}
	
	/// Represents a chat completion response returned by the model, based on the provided input.
	public struct Response: Codable {
		
		/// A unique identifier for the chat completion.
		public let id: String
		
		/// The object type, always `chat.completion`.
		public let object: String
		
		/// The Unix timestamp of when the chat completion was created.
		public let created: Int
		
		/// The model used for the chat completion.
		public let model: String
		
		/// A list of chat completion choices.
		public let choices: [Choice]
		
		/// Usage statistics for the completion request.
		public let usage: Usage
		
		public enum CodingKeys: String, CodingKey {
			case id, object, created, model, choices, usage
		}
		
		public init(
			id: String,
			object: String,
			created: Int,
			model: String,
			choices: [Choice], 
			usage: Usage
		) {
			self.id = id
			self.object = object
			self.created = created
			self.model = model
			self.choices = choices
			self.usage = usage
		}
		
		/// Represents a choice in the list of chat completion choices.
		public struct Choice: Codable {
			
			/// The index of the choice in the list of choices.
			public let index: Int
			
			/// A chat completion message generated by the model.
			public let message: Message
			
			/// The reason the model stopped generating tokens.
			public let finishReason: String
			
			public enum CodingKeys: String, CodingKey {
				case index, message
				case finishReason = "finish_reason"
			}
			
			public init(index: Int, message: Message, finishReason: String) {
				self.index = index
				self.message = message
				self.finishReason = finishReason
			}
		}
		
		/// Represents usage statistics for the completion request.
		public struct Usage: Codable {
			
			/// Number of tokens in the prompt.
			public let promptTokens: Int
			
			/// Number of tokens in the generated completion.
			public let completionTokens: Int
			
			/// Total number of tokens used in the request.
			public let totalTokens: Int
			
			public enum CodingKeys: String, CodingKey {
				case promptTokens = "prompt_tokens"
				case completionTokens = "completion_tokens"
				case totalTokens = "total_tokens"
			}
			
			public init(promptTokens: Int, completionTokens: Int, totalTokens: Int) {
				self.promptTokens = promptTokens
				self.completionTokens = completionTokens
				self.totalTokens = totalTokens
			}
		}
	}
	
	/// Represents a streamed chunk of a chat completion response returned by the model, based on the provided input.
	public struct ChunkResponse: Codable {
		
		/// A unique identifier for the chat completion. Each chunk has the same ID.
		public let id: String
		
		/// The object type, always `chat.completion.chunk`.
		public let object: String
		
		/// The Unix timestamp of when the chat completion was created. Each chunk has the same timestamp.
		public let created: Int
		
		/// The model used to generate the completion.
		public let model: String
		
		/// A list of chat completion choices.
		public let choices: [Choice]
		
		public enum CodingKeys: String, CodingKey {
			case id, object, created, model, choices
		}
		
		public init(id: String, object: String, created: Int, model: String, choices: [Choice]) {
			self.id = id
			self.object = object
			self.created = created
			self.model = model
			self.choices = choices
		}
		
		/// Represents a choice in the list of chat completion choices.
		public struct Choice: Codable {
			
			/// The index of the choice in the list of choices.
			public let index: Int
			
			/// A chat completion delta generated by streamed model responses.
			public let delta: Delta
			
			/// The reason the model stopped generating tokens.
			public let finishReason: String?
			
			public enum CodingKeys: String, CodingKey {
				case index, delta
				case finishReason = "finish_reason"
			}
			
			public init(index: Int, delta: Delta, finishReason: String?) {
				self.index = index
				self.delta = delta
				self.finishReason = finishReason
			}
			
			/// Represents a chat completion delta generated by streamed model responses.
			public struct Delta: Codable {
				
				/// The role of the author of this message.
				public let role: String
				
				/// The contents of the chunk message.
				public let content: String?
				
				public enum CodingKeys: String, CodingKey {
					case role, content
				}
				
				public init(role: String, content: String?) {
					self.role = role
					self.content = content
				}
			}
		}
	}
	
	public struct BadResponse: Codable {
		public let error: Error
		
		public struct Error: Codable, CustomStringConvertible {
			public let type: String
			public let code: String?
			public let param: String?
			public let message: String
			
			public var description: String {
				"Error from ChatGPT API of type \(type) with code \(code as Any): \(message)"
			}
		}
	}

	public struct Message: Codable {
		
		/// The role of the author of this message.
		public let role: String
		
		/// The contents of the message.
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
}
