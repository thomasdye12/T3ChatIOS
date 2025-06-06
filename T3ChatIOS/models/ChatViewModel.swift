//
//  ChatViewModel.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ConvexChatMessage] = []
    @Published var isSending: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared

    // Hardcoded params
    var model: Model
    init(model: Model) {
        self.model = model
    }

    @MainActor
    init(threadId:String) {
        self.model = models.first!
        Task {
            let latestChatPublisher =  T3ChatUserShared.shared.convex?.GetThreadByIdPublisher(id: threadId)
            if let latestChat = latestChatPublisher {
                for await chats in latestChat.values {
                    messages = chats
                    if let lastChat = chats.last  {
                        threadMetadata = .init(id:threadId)
                        self.model = models.first(where: { $0.id == lastChat.model }) ?? models.first!
                    }
                }
            }
        }

    }

    private let preferences = Preferences(
        name: "",
        occupation: "",
        selectedTraits: [""],
        additionalInfo: ""
    )
    private let userInfoPayload = UserInfoPayload(timezone: "Europe/London")

    private var threadMetadata = ThreadMetadata(id: UUID().uuidString)
    private var lastResponseId: String?

    /// Load any initial messages and thread metadata
    func loadInitial(
        messages: [ConvexChatMessage],
        threadId: UUID? = nil,
        responseId: String? = nil
    ) {
        self.messages = messages
        if let tid = threadId {
            threadMetadata = ThreadMetadata(id: tid.uuidString)
        }
        lastResponseId = responseId
    }

    /// Send a user message and fetch assistant response
    func send(_ text: String) {
        let userMsg = ConvexChatMessage(
            messageId: UUID().uuidString,
            content: text,
            role: .user,
            model: model.id, modelParams: nil,
            created_at: CurrentTime(), status: .done, attachmentIds: [], updated_at: CurrentTime()
            
//            attachments: []
        )
        messages.append(userMsg)

    
        isSending = true

        // We'll now subscribe to the stream of events
        fetchResponseStream(userMessage: userMsg)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isSending = false
                if case .failure(let error) = completion {
                    print("Error fetching response stream: \(error)")
                    T3ChatUserShared.shared.ShowAlert(title: "Error fetching response stream", message: "\(error)")
                }
            } receiveValue: { [weak self] event in
                guard let self = self else {
                    return
                }

                switch event {
                case .content(let content):
                    print("new content has come in \(content)")
                    // Append content to the last assistant message,
                    // or create a new one
                    if let lastAssistantMessage = self.messages.last(
                        where: { $0.role == .assistant }
                    ),
                       lastAssistantMessage.messageId == self.lastResponseId
                    {
                        // Append to existing message
                        var updatedMessage = lastAssistantMessage
                        updatedMessage.content += content.content
                        if let index = self.messages.firstIndex(where: {
                            $0.messageId == updatedMessage.messageId
                        }) {
                            self.messages[index] = updatedMessage
                        } else {
                            print("FAILED TO UDPATE MEESAGE INDEX")
                        }
                    } else {
                        // This might be the first chunk for a new message,
                        // or if lastResponseId was not set up yet.
                        // You might need a temporary placeholder message here,
                        // and update its ID once 'f:' is received.
                        // For simplicity, let's assume 'f:' arrives before content.
                        print("Warning: Content chunk arrived before message ID.")
                        // If it happens, you'd want to handle creating
                        // the initial message here
                        // For now, this will simply not append
                        // if there's no matching message.
                    }
                case .messageId(let msgId):
                    // Create the initial assistant message placeholder
                    self.threadMetadata.id =
                        self.threadMetadata
                        .id  // No change to thread ID based on f:
                case .finishReason(let reason):
                    // Stream finished, process usage, etc.
                    print(
                        "Stream finished. Reason: \(reason.finishReason), " +
                            "Usage: \(reason.usage?.completionTokens ?? 0) " +
                            "completion tokens."
                    )
                // You might want to do something with the
                // `isContinued` flag if you have a multi-turn
                // continued conversation logic
                case .rateLimit(let rateLimit):
                    // Handle rate limit information
                    print(
                        "Rate Limit Info: Remaining: \(rateLimit.remaining), " +
                            "Used: \(rateLimit.used), Max: \(rateLimit.max)"
                    )
                // You might want to display a user-facing message here.
                case .providerMetadata(let metadata):
                    print(
                        "Provider Metadata: Type: \(metadata.type), " +
                            "Content: \(metadata.content)"
                    )
                // This is extra metadata you might want to log or use.
                case .unknown(let raw):
                    print("Unknown stream event: \(raw)")
                }
            }
            .store(in: &cancellables)
    }

    // Enum to represent different types of streamed events
    enum ChatStreamEvent {
        case content(ChatStreamContent)  // 0:
        case messageId(ChatStreamMessageId)  // f:
        case finishReason(ChatStreamFinishReason)  // e: or d:
        case rateLimit(ChatStreamRateLimit)  // 2: type "ratelimit"
        case providerMetadata(ChatStreamMetadataWrapper)  // 2:
        // type "provider-metadata"
        case unknown(String)  // For unparsed lines
    }

    /// Real network call for streaming
    private func fetchResponseStream(userMessage:ConvexChatMessage,upload:Bool = true) -> AnyPublisher<ChatStreamEvent, Error> {
        guard let url = URL(string: "https://t3.chat/api/chat") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(
            T3ChatUserShared.shared.Cookies(),
            forHTTPHeaderField: "Cookie"
        )

        
        
        let assistantMsg = ConvexChatMessage(
            messageId:  UUID().uuidString,
            content: "",
            role: .assistant,
            model: model.id, modelParams: T3ChatUserShared.shared.modelParams,
            created_at: CurrentTime(), status: .waiting, attachmentIds: [], updated_at: CurrentTime()
            
//            attachments: []
        )
 
        

        let payload = ChatRequest(
            messages: messages.map({$0.ConvertToMessage()}),
            threadMetadata: threadMetadata,
            responseMessageId: assistantMsg.messageId,
            model: model.id,
            modelParams: assistantMsg.modelParams!,
            preferences: preferences,
            userInfo: userInfoPayload,
            convexSessionId: T3ChatUserShared.shared.SessionID.uuidString
        )

        self.messages.append(assistantMsg)
        self.lastResponseId = assistantMsg.messageId
        if upload == false {
            T3ChatUserShared.shared.convex?.SetNewMessage(User: userMessage, Assistant: assistantMsg, threadId: threadMetadata.id)
        }
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session
            .dataTaskPublisher(for: request)
            .mapError { $0 as Error }  // Convert URLError to generic Error
            .flatMap { data, response -> AnyPublisher<ChatStreamEvent, Error> in
                guard let http = response as? HTTPURLResponse else {
                    return Fail(error: URLError(.badServerResponse))
                        .eraseToAnyPublisher()
                }
                guard 200..<300 ~= http.statusCode else {
                    // Convert the throw into a Fail publisher
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Server error (\(http.statusCode)): \(errorBody)")
                        return Fail(
                            error: NSError(
                                domain: "ChatAPI",
                                code: http.statusCode,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Server error: \(errorBody)",
                                ]
                            )
                        ).eraseToAnyPublisher()
                    } else {
                        return Fail(error: URLError(.badServerResponse))
                            .eraseToAnyPublisher()
                    }
                }

                // Split the data by newline to process each line
                // as a separate event
                guard let responseString = String(data: data, encoding: .utf8) else {
                    return Fail(error: URLError(.cannotDecodeContentData))
                        .eraseToAnyPublisher()
                }

                let lines = responseString.split(
                    separator: "\n",
                    omittingEmptySubsequences: true
                )

                // Process each line as before (this part is mostly fine)
                return Publishers.Sequence(sequence: lines.map { String($0) })
                    .flatMap { line -> AnyPublisher<ChatStreamEvent, Error> in
                        let decoder = JSONDecoder()

                        // Your existing line parsing logic remains
                        // largely the same,
                        // ensuring each path returns a Just() or Fail() publisher.
                        if line.starts(with: "0:") {
                            let jsonString = String(line.dropFirst(2))
                            if let jsonData = jsonString.data(using: .utf8),
                               let content = try? decoder.decode(
                                String.self,
                                from: jsonData
                                )
                            {
                                return Just(
                                    ChatStreamEvent.content(
                                        ChatStreamContent(content: content)
                                    )
                                )
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                            }
                        } else if line.starts(with: "f:") {
                            let jsonString = String(line.dropFirst(2))
                            if let jsonData = jsonString.data(using: .utf8),
                               let messageId = try? decoder.decode(
                                ChatStreamMessageId.self,
                                from: jsonData
                                )
                            {
                                return Just(ChatStreamEvent.messageId(messageId))
                                    .setFailureType(to: Error.self)
                                    .eraseToAnyPublisher()
                            }
                        } else if line.starts(with: "e:") ||
                            line.starts(with: "d:"
                            )
                        {
                            let jsonString = String(line.dropFirst(2))
                            if let jsonData = jsonString.data(using: .utf8),
                               let finishReason = try? decoder.decode(
                                ChatStreamFinishReason.self,
                                from: jsonData
                                )
                            {
                                return Just(
                                    ChatStreamEvent.finishReason(finishReason)
                                )
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                            }
                        } else if line.starts(with: "2:") {
                            let jsonString = String(line.dropFirst(2))
                            if let jsonData = jsonString.data(using: .utf8),
                               let metadataArray = try? decoder.decode(
                                [ChatStreamMetadataWrapper].self,
                                from: jsonData
                                )
                            {
                                if let firstMetadata = metadataArray.first {
                                    if firstMetadata.type == "ratelimit" {
                                        if let rateLimitData =
                                            firstMetadata.content.data(using: .utf8),
                                           let rateLimit = try? decoder.decode(
                                            ChatStreamRateLimit.self,
                                            from: rateLimitData
                                            )
                                        {
                                            return Just(
                                                ChatStreamEvent.rateLimit(rateLimit)
                                            )
                                            .setFailureType(to: Error.self)
                                            .eraseToAnyPublisher()
                                        }
                                    } else if firstMetadata.type ==
                                        "provider-metadata"
                                    {
                                        return Just(
                                            ChatStreamEvent
                                                .providerMetadata(firstMetadata)
                                        )
                                        .setFailureType(to: Error.self)
                                        .eraseToAnyPublisher()
                                    }
                                }
                            }
                        }
                        return Just(ChatStreamEvent.unknown(line))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    
    //     unix time stamp as doube with in miliseconds
        func CurrentTime() -> Int {
            print(Int(Date().timeIntervalSince1970 * 1000))
            return Int(Date().timeIntervalSince1970 * 1000)
        }
    
    
    func fetchCompleteResponse(userMessage: ConvexChatMessage,upload:Bool = true) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            var accumulated = ""

            // Kick off the Combine stream
            fetchResponseStream(userMessage: userMessage,upload: upload)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        // Stream ended successfully—return the full text
                        continuation.resume(returning: accumulated)

                    case .failure(let error):
                        // Stream failed—propagate the error
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { event in
                    switch event {
                    case .content(let content):
                        // Append each chunk as it arrives
                        accumulated += content.content
                    default:
                        // ignore other event types
                        break
                    }
                }
                .store(in: &cancellables)
        }
    }
    
}

// MARK: - Bubble View

extension T3ChatUserShared {
    
}
