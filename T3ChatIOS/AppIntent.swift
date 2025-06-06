//
//  AppIntent.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import AppIntents



struct AskAIIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask T3 Chat"
    static var description: IntentDescription? = "Send a message and get a response from T3 Chat"
    static var openAppWhenRun: Bool = false // Set to true if your intent needs to open the app

    @Parameter(title: "model", optionsProvider: ModelOptionsProvider())
    var aiModel: Model // Use your Model struct here

    @Parameter(title: "Message", description: "The message to send to the AI.")
    var message: String // New parameter for the user's message
    
    @Parameter(title: "Save to history", description: "Shows the messages in your chat history")
    var showInHistory: Bool // New parameter for the user's message

    static var parameterSummary: some ParameterSummary {
        // Updated parameter summary to reflect the new parameters
        Summary("Ask \(\.$aiModel) about \(\.$message), and show in history: \(\.$showInHistory)") {
            \.$message
            \.$aiModel
            \.$showInHistory
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let chatViewModel = ChatViewModel(model: aiModel)
        let ModelConfig =  ModelParams.init(reasoningEffort: "medium", includeSearch: false)
        let UserChat = ConvexChatMessage.init(messageId: UUID().uuidString, content: message, role: ChatMessage.Role.user, model: aiModel.id, modelParams: ModelConfig, created_at: chatViewModel.CurrentTime(), status:ConvexChatMessage.status.done, attachmentIds: [], updated_at: chatViewModel.CurrentTime())
        chatViewModel.messages.append(UserChat)
        let Message = try await chatViewModel.fetchCompleteResponse(userMessage: UserChat, upload: showInHistory)

        return .result(value: Message)
    }
}
