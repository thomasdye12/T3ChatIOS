//
//  ChatBubble.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI
import MarkdownUI
struct ChatBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
//        Divider()
 
        HStack {
            if isUser {
                Spacer()
            }
            Markdown(message.content)
                .padding(12) // Re-added padding for better appearance
                .background(isUser ?  Color.gray.opacity(0.1) : nil)
//                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16) // Re-added corner radius
//                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isUser ? .trailing : .leading)
                .multilineTextAlignment(isUser ? .trailing : .leading)
                // MARK: - Add Context Menu for Copy
                .contextMenu {
                    Button {
                        // Action to copy the text to the pasteboard
                        UIPasteboard.general.string = message.content
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            if !isUser {
                Spacer()
            }


        }
//        .background(Color.red)
        .padding(isUser ? .trailing : .leading, 20)
        .padding(.vertical, 4)
    }
}


#Preview {
    VStack(alignment: .leading) {
                ChatBubble(
                    message: ChatMessage(id:UUID(),
                        content: "Hello there! How are you?\n```\nfunc greet() {\n  print(\"Hello\")\n}\n```\nThis is some more text after the code.",
                                         role: .assistant,
                                         attachments: []
                    )
                )
                ChatBubble(
                    message: ChatMessage(
                        id:UUID(),
                        content: "I'm good! Thanks for asking.\n```\nlet x = 10\nlet y = 20\nlet sum = x + y\nprint(sum)\n```",
                        role: .user,
                        attachments: []
                    )
                )
            }
//    .background(Color.blue)
            .padding()
}
