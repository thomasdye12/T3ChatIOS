//
//  ChatMessage.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI
import Combine

// MARK: - Model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var content: String
    let role: Role
    let attachments: [String]

    enum Role: String, Codable {
        case user, assistant
    }
}

struct ThreadMetadata: Codable {
    var id: UUID
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
    let responseMessageId: UUID
    let model: String
    let modelParams: ModelParams
    let preferences: Preferences
    let userInfo: UserInfoPayload
    let convexSessionId:String = ""
    
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


struct Model:Codable,Identifiable {
    let id:String
    let name:String
    var SearchEngin:Bool? = false
}


// need some sort of endpoint to get all current models from the system, could not find that.
let models:[Model] = [
    .init(id:"gemini-2.5-flash",name:"Gemini 2.5 (Flash)",SearchEngin: true),
    .init(id:"gpt-4.1",name:"gpt-4.1"),
    .init(id:"gemini-2.5-flash2",name:"Gemini 2.5 (Flash)2"),
    .init(id:"gemini-2.5-flash3",name:"Gemini 2.5 (Flash)3"),
    .init(id:"gemini-2.5-flash4",name:"Gemini 2.5 (Flash)4")
    ]
    
