//
//  WebSocket.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import Foundation
import ConvexMobile
import Combine


class T3ConvexWrapper {
    
    var SessionID:String
    var convex:ConvexClientWithAuth<String>!
    
    init (SessionID:String, JWT:String) {
        self.SessionID = SessionID
//        local proxy for debug ws://10.0.12.71:8080/api/1.23.0/sync
//        main endpoint wss://api.sync.t3.chat/api/sync
        convex = ConvexClientWithAuth<String>(deploymentUrl: "wss://api.sync.t3.chat/api/sync",authProvider: StaticJWTAuthProvider(jwt: JWT))
      
        Task {
            await convex.loginFromCache()
//            await GetThreadList()
        }
    }
    
    
    
    
    func arguments() -> [String:ConvexEncodable] {
        return ["sessionId":SessionID]
    }
    
    func GetThreadListPublisher() -> AnyPublisher<[ConvexMessageThread], Never> { // <--- Changed ClientError to Never
        convex.subscribe(to: "threads:get", with: arguments(), yielding: [ConvexMessageThread].self)
            .replaceError(with: []) // This makes the error type Never
            .eraseToAnyPublisher()  // Erase the specific publisher chain to AnyPublisher<[ConvexMessageThread], Never>
    }
    func GetThreadByIdPublisher(id:String) -> AnyPublisher<[ConvexChatMessage], Never> { // <--- Changed ClientError to Never
        var arguments = arguments()
        arguments["threadId"] = id
        
        return convex.subscribe(to: "messages:getByThreadId", with: arguments, yielding: [ConvexChatMessage].self)
            .replaceError(with: []) // This makes the error type Never
            .eraseToAnyPublisher()  // Erase the specific publisher chain to AnyPublisher<[ConvexMessageThread], Never>
    }
    
    func SetNewMessage(User:ConvexChatMessage, Assistant:ConvexChatMessage, threadId:String){ // <--- Changed ClientError to Never
        struct ConvexChatStreamMessage:Codable {
            let message:[ConvexChatMessage]
            let threadId:String
            let sessionId:String
        }
        

        var arguments = arguments()
        arguments["threadId"] = threadId
        arguments["messages"] = [User,Assistant]
        print(arguments)

            
        Task {
            try await convex.mutation("messages:addMessagesToThread",with: arguments)
        }
    }
    
    
    
    
}




extension Array:ConvexEncodable {
    
}
