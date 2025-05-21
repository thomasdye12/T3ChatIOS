//
//  SettingsView.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import SwiftUI

struct SettingsView: View {
  @State private var accessToken: String = ""
    @Environment(\.dismiss) var dismiss
  var body: some View {
    NavigationView {
      VStack {
          Image("icon")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .padding()
          Text("This application is not associated with T3 Chat in any way")
              .font(.caption)
              .foregroundStyle(.secondary)
          Text("Please DO NOT contact Theo with an issue, contact me Thomas")
              .font(.caption)
              .foregroundStyle(.secondary)
          
        Text("To use the app \n Please enter your access token from T3 Chat")
          .font(.headline)
          .multilineTextAlignment(.center)
          .padding()

        VStack(alignment: .leading) {
          Text("Access Token")
            .font(.subheadline)
            .padding(.horizontal)

          TextField("Enter your access token", text: $accessToken)
            .padding()
            .border(Color.gray, width: 1)
            .padding(.horizontal)

          Text("An access token is required to use.")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal)
        }
        .padding(.bottom)

        Button(action: {
            T3ChatUserShared.shared.SetUserToken(accessToken: accessToken)
            dismiss.callAsFunction()
        }) {
          Text("Save Access Token")
            .padding()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .disabled(accessToken.isEmpty)
        .opacity(accessToken.isEmpty ? 0.5 : 1.0)

          
        Spacer()
          Text("Contact Thomas: ContactThomas@thomasdye.net")
              .font(.caption)
              .foregroundStyle(.secondary)
      }
      .navigationTitle("Settings")
      .padding()
      .onAppear() {
          accessToken = T3ChatUserShared.shared.GetUserToken() ?? ""
      }
    }
  }
}

#Preview {
    SettingsView()
}
