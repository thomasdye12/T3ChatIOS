//
//  T3ChatUserShared.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//

import Foundation
import SwiftUI
import UIKit
class T3ChatUserShared:ObservableObject {
    
    var accessToken:String?
    
    
    static let shared = T3ChatUserShared()
    
    var MainVC:UIViewController?
    
    @Published var CurrentUserChat:ChatViewModel?
    
    @Published var selectedModel: Model? = models.first
    
    
    @Published var modelParams = ModelParams(
        reasoningEffort: "medium",
        includeSearch: false
    )
    
    
    func CreateNewChat(model:Model?) {
        
        let newChat = ChatViewModel(model: model ?? selectedModel ?? models.first!)
        CurrentUserChat = newChat
    }
    
    init(){
        if let token = GetUserToken(){
            accessToken = token
        }
    }
    
    
    func SetUserToken(accessToken:String) {
        UserDefaults.standard.set(accessToken, forKey: "T3AccessToken")
        self.accessToken = accessToken
    }
    
    func GetUserToken() -> String? {
        return UserDefaults.standard.string(forKey: "T3AccessToken")
    }
    func Cookies() -> String {
        return "access_token=\(accessToken ?? "")"
    }
    
    
    func ShowAlert(title:String,message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .cancel))
        DispatchQueue.main.async {
            self.MainVC?.present(alert, animated: true)
        }

    }
}
