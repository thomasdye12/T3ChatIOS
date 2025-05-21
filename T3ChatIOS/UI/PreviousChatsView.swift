//
//  PreviousChatsView.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import SwiftUI

struct PreviousChatsView: View {
    @ObservedObject var userInfo: T3ChatUserShared
    @State private var groupedMessages: [Date: [ConvexMessageThread]] = [:]
    @State private var pinnedMessages: [ConvexMessageThread] = []
    @State private var SearchMessages: [ConvexMessageThread] = []
    @State var searchText:String = ""
    // 1. Add a completion closure
    var onChatSelected: (ConvexMessageThread) -> Void
    @Environment(\.dismiss) var dismiss // To dismiss the view

    var body: some View {
        NavigationStack {
            List {
                if searchText == "" {
                    // Pinned Chats Section
                    if !pinnedMessages.isEmpty {
                        Section(header: Text("Pinned")) {
                            ForEach(pinnedMessages) { message in
                                // 2. Pass the onChatSelected closure to ChatRowView
                                ChatRowView(message: message) { selectedMessage in
                                    onChatSelected(selectedMessage)
                                    dismiss() // Dismiss the view
                                }
                            }
                        }
                    }
                    
                    // Chats Grouped by Day
                    ForEach(sortedDates, id: \.self) { date in
                        Section(header: Text(userInfo.formattedDate(date))) {
                            ForEach(groupedMessages[date]?.sorted(
                                using: KeyPathComparator(\.lastMessageAt, order: .reverse)
                            ) ?? []) { message in
                                // 2. Pass the onChatSelected closure to ChatRowView
                                ChatRowView(message: message) { selectedMessage in
                                    onChatSelected(selectedMessage)
                                    dismiss() // Dismiss the view
                                }
                            }
                        }
                    }
                } else {
                    Text("SEARCH IS NOT IMPLEMENTED")
                }
            }
            .searchable(text: $searchText)
            .task {
                await loadChats()
            }
            .onChange(of: searchText) { newValue in
                print(newValue)
//                Task {
//                    await loadFromSearch(search: newValue)
//                }
            }
            .navigationTitle("Previous Chats")
        }
    }

    private var sortedDates: [Date] {
        groupedMessages.keys.sorted(using: KeyPathComparator(\.self, order: .reverse))
    }

    func loadChats() async {
        let latestChatsPublisher = userInfo.convex?.GetThreadListPublisher()
            .replaceError(with: [])

        if let latestChatsPublisher = latestChatsPublisher {
            for await chats in latestChatsPublisher.values {
                self.pinnedMessages = chats.filter { $0.pinned }
                    .sorted(using: KeyPathComparator(\.lastMessageAt, order: .reverse))
                self.groupedMessages = Dictionary(grouping: chats.filter {
                    !$0.pinned
                }) { message in
                    Calendar.current.startOfDay(
                        for: Date(timeIntervalSince1970: message.lastMessageAtSeconds())
                    )
                }
            }
        }
    }
    
    func loadFromSearch(search:String) async {
        let latestChatsPublisher = userInfo.convex?.GetThreadBySearchPublisher(searchString: search)
            .replaceError(with: [])

        if let latestChatsPublisher = latestChatsPublisher {
            for await chats in latestChatsPublisher.values {
                self.SearchMessages = chats
            }
        }
    }
}

// Assuming ChatRowView looks something like this initially:
struct ChatRowView: View {
    let message: ConvexMessageThread
    // 3. Add a closure for the action
    var onRowTapped: (ConvexMessageThread) -> Void

    var body: some View {
        // Use a Button to make the entire row clickable
        Button {
            onRowTapped(message)
        } label: {
            HStack {
                ChatRowViewContent(message: message)
            }
            .contentShape(Rectangle()) // Makes the whole row tappable
        }
        .buttonStyle(.plain) // Prevents the default button styling
        .contextMenu {
            Button {
                T3ChatUserShared.shared.convex?.SetPinnedStatusOfChat(Pinned: !message.pinned, threadId: message.threadId)
            } label: {
                Label(message.pinned ? "Pin" :"UnPin", systemImage: message.pinned ?  "pin.fill" : "pin.slash.fill")
            }
        }
    }
}

struct ChatRowViewContent: View {
    let message: ConvexMessageThread

    var body: some View {
        HStack {
            Image(systemName: message.pinned ? "pin.fill" : "message.fill")
                .foregroundColor(message.pinned ? .accentColor : .gray)
            Text(message.title)
            Spacer()
            Text(timeAgoString(from: message.lastMessageAtSeconds()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func timeAgoString(from timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // e.g., "2h ago", "3d ago"
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}



#Preview(body: {
    PreviousChatsView(userInfo: T3ChatUserShared.shared, onChatSelected: { thread in
        
    })
})

