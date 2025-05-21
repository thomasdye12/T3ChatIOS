//
//  T3ChatUserShared.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 20/05/2025.
//



import Foundation
import SwiftUI
import UIKit
import ConvexMobile

class T3ChatUserShared:ObservableObject {
 
    
    var accessToken:String? {
        didSet {
            if let accessToken = accessToken{
                SetuConvex(JWT: accessToken)
            }
         
        }
    }
    
    
    static let shared = T3ChatUserShared()
    var SessionID:UUID = UUID()
    var MainVC:UIViewController?
    @Published var CurrentUserChat:ChatViewModel?
    
    @Published var selectedModel: Model? = models.first
    
    
    @Published var modelParams = ModelParams(
        reasoningEffort: "medium",
        includeSearch: false
    )
//    wss://api.sync.t3.chat/api/1.23.0/sync
    var convex:T3ConvexWrapper?
    
    func CreateNewChat(model:Model?) {
        
        let newChat = ChatViewModel(model: model ?? selectedModel ?? models.first!)
        CurrentUserChat = newChat
    }
    
    init(){
        if let token = GetUserToken(){
            accessToken = token
            SetuConvex(JWT: token)
         
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

//     attempting to connect to a convex sync and get that work, defiantly dont know enough about it 
    func SetuConvex(JWT:String) {
        convex = T3ConvexWrapper(SessionID: SessionID.uuidString,JWT:JWT)
    }
    
    
    
     func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
    }
    
}
