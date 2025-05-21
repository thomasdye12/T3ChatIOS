//
//  ChatMessage.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI
import Combine
import ConvexMobile
import AppIntents

// MARK: - Model
struct ChatMessage: Identifiable, Codable {
    let id: String
    var content: String
    let role: Role
//    let attachments: [String]

    enum Role: String, Codable {
        case user, assistant
    }
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content
        case role
    }
}

struct ThreadMetadata: Codable {
    var id: String
}

struct ModelParams: Codable {
    let reasoningEffort: String
    var includeSearch: Bool
}

struct Preferences: Codable {
    let name: String
    let occupation: String
    let selectedTraits: String
    let additionalInfo: String
}

struct UserInfoPayload: Codable {
    let timezone: String
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
    let threadMetadata: ThreadMetadata
    let responseMessageId: String
    let model: String
    let modelParams: ModelParams
    let preferences: Preferences
    let userInfo: UserInfoPayload
    let convexSessionId:String
    
}

struct ChatResponse: Codable {
    struct ResponseMessage: Codable {
        let id: UUID
        let content: String
        let role: ChatMessage.Role
        let attachments: [String]
    }
    let messages: [ResponseMessage]
    let threadMetadata: ThreadMetadata
    let responseMessageId: UUID
}

// For "0:" type messages (content chunks)
struct ChatStreamContent: Decodable {
    let content: String
}

// For "f:" type messages (initial message ID)
struct ChatStreamMessageId: Decodable {
    let messageId: String
}

// For "e:" and "d:" type messages (end of stream/usage info)
struct ChatStreamFinishReason: Decodable {
    let finishReason: String
    let usage: ChatStreamUsage? // Make optional as "d:" might not have all fields
    let isContinued: Bool? // "e:" has this
}

struct ChatStreamUsage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
}

// For "2:" type messages (metadata)
struct ChatStreamMetadataWrapper: Decodable {
    let type: String
    let content: String // This will likely be a JSON string that needs further parsing
}

struct ChatStreamRateLimit: Decodable {
    let remaining: Int
    let used: Int
    let max: Int
    let consume: String
}

struct ChatStreamProviderMetadata: Decodable {
    // Depending on the structure of the "google" content, you might need more structs here
    // For now, let's keep it simple as a general container if not directly used
}

struct Model: Codable, Identifiable, Hashable, AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "model")
    
      typealias DefaultQueryType = ModelQuery
      static var defaultQuery: ModelQuery = ModelQuery()

      static var typeDisplayName: LocalizedStringResource = LocalizedStringResource("Model", defaultValue: "Model")
      var displayRepresentation: DisplayRepresentation {
          DisplayRepresentation(title: .init(stringLiteral: name))
      }
    
    let id: String
    let name: String
    var SearchEngin: Bool? = false

    // Initializer remains the same
    init(id: String, name: String, SearchEngin: Bool? = false) {
        self.id = id
        self.name = name
        self.SearchEngin = SearchEngin
    }

    // Equatable and Hashable conformance are still necessary for this struct
    // to be used as a parameter and within the DynamicOptionsProvider.
    static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Your predefined list of models (remains the same)
// In a real app, this would likely come from an API or local persistent store.
let models: [Model] = [
    .init(id: "gemini-2.5-flash", name: "Gemini 2.5 (Flash)", SearchEngin: true),
    .init(id: "gpt-4.1", name: "GPT-4.1"),
    .init(id: "gemini-2.5-flash2", name: "Gemini 2.5 (Flash) 2"),
    .init(id: "gemini-2.5-flash3", name: "Gemini 2.5 (Flash) 3"),
    .init(id: "gemini-2.5-flash4", name: "Gemini 2.5 (Flash) 4")
]


struct ModelQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [Model] {
        return models.filter({ identifiers.contains($0.id) })
    }
    
    typealias Entity = Model
    func entities(matching string: String) async throws -> [Model] {
        return models.filter({ $0.name.starts(with: string)})
    }

//    func entities(for identifiers: [UUID]) async throws -> [Model] {
//        return models.filter({ identifiers.contains($0.id) })
//    }
}

struct ModelOptionsProvider: DynamicOptionsProvider {
 
    
    func results() async throws -> [Model] {
        return models
    }
}






// Convex



struct ConvexMessageThread: Codable,Identifiable {
    let creationTime: Double
    let id: String
    let branchParent: String?
    let createdAt: Double
    let generationStatus: String
    let lastMessageAt: Double
    let model: String
    let pinned: Bool
    let threadId: String
    let title: String
    let updatedAt: Double
    let userId: String
    let userSetTitle: Bool?
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case creationTime = "_creationTime"
        case id           = "_id"
        case branchParent
        case createdAt
        case generationStatus
        case lastMessageAt
        case model
        case pinned
        case threadId
        case title
        case updatedAt
        case userId
        case userSetTitle
        case visibility
    }
    
    
    func creationTimeSeconds() -> Double {
//        convert the milisectionds to seconds
        return creationTime / 1000
    }
    
    func lastMessageAtSeconds() -> Double {
//        convert the milisectionds to seconds
        return lastMessageAt / 1000
    }
}



struct ConvexChatMessage:Codable,ConvexEncodable {
//        var id: String {messageId}
        let messageId:String
        var content: String
        let role: ChatMessage.Role
        let model:String
        let modelParams:ModelParams?
        let created_at:Int  
        let status:status
        let attachmentIds:[String]
        var updated_at: Int
    //    let attachments: [String]


        enum CodingKeys: String, CodingKey {
//            case id = "_id"
            case content
            case role
            case model
            case modelParams
            case created_at
            case status
            case messageId
            case updated_at
            case attachmentIds
        }
    
    
    enum status: String, Codable {
        case done, waiting,streaming
    }
    
    
    
    func ConvertToMessage() -> ChatMessage {
        return .init(id: messageId, content: content, role: role)
    }
    
    
    func toJsonString() -> String? {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Optional: for human-readable output
            do {
                let data = try encoder.encode(self)
                return String(data: data, encoding: .utf8)
            } catch {
                print("Error encoding ConvexChatMessage to JSON: \(error)")
                return nil
            }
        }
    

}



