//
//  ChatView.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI

struct ChatView: View {
    
    @ObservedObject var viewModel: ChatViewModel
    
    
    var body: some View {
        ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack {
                                chatModelInfo(viewModel: viewModel)
                                ForEach(viewModel.messages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.id)
                                }
                            }
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
        }
    }
}

struct chatModelInfo:View {
    @ObservedObject var viewModel: ChatViewModel
    var body: some View {
        Text("Model:\(viewModel.model.name)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}


struct NoChatStarted: View {
  @ObservedObject var viewModel: T3ChatUserShared

  var body: some View {
    VStack {
      Spacer()
      Image("icon")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 150, height: 150)
        .padding(10)
        Text("This application is not associated with T3 Chat in any way")
            .font(.caption)
            .foregroundStyle(.secondary)
        Text("Please DO NOT contact Theo with an issue, contact me Thomas")
            .font(.caption)
            .foregroundStyle(.secondary)
      Spacer()
      Text("No chat has been started")

      // Horizontal ScrollView for Model Selection
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(models) { model in
            Button(action: {
                viewModel.selectedModel = model
            }) {
              Text(model.name)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 10)
                    .fill(
                        viewModel.selectedModel?.id == model.id
                      ? Color.accentColor
                        : Color.gray.opacity(0.3)
                    )
                )
                .foregroundColor(.white)
            }
          }
        }
        .padding()
      }
    }
  }
}



struct ChatWrapper: View {
    @ObservedObject var userInfo: T3ChatUserShared
    @State private var messageText: String = ""
    @FocusState private var isInputActive: Bool
    @State private var searchEnabled: Bool = false // State to control the search toggle
    var body: some View {
        VStack {
            // Your chat messages list goes here
            if let ChatData = userInfo.CurrentUserChat {
                ChatView(viewModel: ChatData)
            } else {
                NoChatStarted(viewModel: userInfo)
            }

            // Input bar sits at bottom and moves with keyboard
            HStack(spacing: 8) {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputActive)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }

                // Search button/toggle
                if userInfo.selectedModel?.SearchEngin == true {
                    Toggle(isOn: $searchEnabled) {
                        Image(systemName: "globe") // Icon for web search
                            .font(.system(size: 20))
                    }
                    .toggleStyle(.button) // Make it look like a button
                    .tint(.blue) // Optional: change accent color
                    .onChange(of: searchEnabled) { newValue in
                        userInfo.modelParams.includeSearch = newValue
                        print("Search enabled: \(userInfo.modelParams.includeSearch)") // For debugging
                    }
                    .help("Toggle web search for your query") // Accessibility hint
                }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            // Auto-focus the text field to present the keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputActive = true
            }
            // Initialize searchEnabled based on the current modelParams if needed,
            // though for a new chat, it usually starts as false.
            searchEnabled = userInfo.modelParams.includeSearch
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if userInfo.CurrentUserChat == nil {
            // Ensure modelParams.includeSearch is set before creating a new chat
            // if the first message should immediately use the search setting.
            userInfo.modelParams.includeSearch = searchEnabled
            userInfo.CreateNewChat(model: userInfo.selectedModel)
        } else {
            // For ongoing chats, ensure the latest search setting is applied
            // before sending the message, though it's typically set on the modelParams
            // object directly.
            userInfo.modelParams.includeSearch = searchEnabled
        }

        userInfo.CurrentUserChat?.send(messageText)
        messageText = ""
        // Reset searchEnabled after sending if you want it to default to off for the next message
        // searchEnabled = false
    }
}

#Preview {

    ChatWrapper(userInfo: T3ChatUserShared.shared)
//    return ChatView(viewModel: loadSampleChats())
}


func loadSampleChats()  -> ChatViewModel{
    let sample = [
               ChatMessage(id: UUID(), content: "Hello! How can I help you?", role: .assistant, attachments: []),
               ChatMessage(id: UUID(), content: "Just testing, thanks!", role: .user, attachments: [])
           ]
    let vm = ChatViewModel(model: models.first!)
//           vm.loadInitial(messages: sample)
    return vm
}
