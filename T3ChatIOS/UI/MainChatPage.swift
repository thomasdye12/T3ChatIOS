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
                        Text("Chats")
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
                        Text("Settings")
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
                PreviousChatsView() // Display previous chats in a popup
            }
        }
    }
}


// Placeholder Views for Settings and Previous Chats


struct PreviousChatsView: View {
    var body: some View {
        Text("Previous Chats Content Here")
            .padding()
        Text("This has not been built yet, coming soon")
            .padding()
    }
}


#Preview {
    MainChatPage(userInfo: T3ChatUserShared.shared)
}
