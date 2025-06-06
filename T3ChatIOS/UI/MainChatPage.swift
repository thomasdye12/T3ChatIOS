//
//  MainChatPage.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import SwiftUI


struct MainChatPage: View {
    @State private var showPreviousChats = false
    @State private var showSettings = false
    @ObservedObject var userInfo: T3ChatUserShared

    var body: some View {
        NavigationStack {
            VStack {
                // Top Bar with Buttons
                HStack {
                    Button(action: {
                        showPreviousChats = true
                    }) {
                        Image(systemName: "folder")
//                        Label("Chat", image: "folder")
                    }
                    .padding(.leading)

                    Spacer()
                    Button(action: {
                        userInfo.CurrentUserChat = nil
                    }, label: {
                        
                        Text("T3.Chat")
                            .bold()
                            .foregroundColor(.accentColor)
                    })
                   
                    Spacer()

                    Button(action: {
                        showSettings = true
                    }) {
                        Label("Settings", image: "folder")
                    }
                    .padding(.trailing)
                }
                .padding(.top)

                // Chat Content
                ChatWrapper(userInfo: userInfo)
            }
            .onAppear(){
                if userInfo.accessToken == nil {
                    print("No access token found, navigating to login page")
                    showSettings = true
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView() // Display the settings in a popup
            }
            .sheet(isPresented: $showPreviousChats) {
                PreviousChatsView(userInfo: userInfo, onChatSelected: {Thread in
                    userInfo.CurrentUserChat = .init(threadId: Thread.threadId)
                }) // Display previous chats in a popup
            }
        }
    }
}


// Placeholder Views for Settings and Previous Chats




#Preview {
    MainChatPage(userInfo: T3ChatUserShared.shared)
}
