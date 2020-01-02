//
//  ChatClientMethod.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/22.
//  Copyright © 2019 curcifer. All rights reserved.
//

import Foundation
import SwiftGRPC
import NIO

final class LoginClientGuide {
  private let client = Chatservice_ChatServiceServiceClient(address: "192.168.0.101:8080", secure: false)
  private var userObject: User
  init(user: User) {
    self.userObject = user
  }
  func DoLogin(completion: @escaping ((User, Bool) -> Void), errorHandler: ((StatusCode, String?)->Void)?) {
    var loginRequest = Chatservice_LoginRequest()
    var userRequest = Chatservice_User()
    userRequest.aliasname = self.userObject.aliasName
    userRequest.roomID = userObject.roomId ?? ""
    loginRequest.request = userRequest
    _ = try? client.registerOrLoginUser(loginRequest) { (response, result) in
      if result.success,
        result.statusCode == StatusCode.ok,
        let payload = response?.result{
        self.userObject = User(aliasName: payload.aliasname,
                               roomId: payload.roomID,
                               isLogin: true)
        completion(self.userObject, payload.hasRoom_p)
      } else {
        errorHandler?(result.statusCode, result.statusMessage)
      }
    }
  }
}

final class RoomClientGuide {
  private let client = Chatservice_ChatServiceServiceClient(address: "192.168.0.101:8080", secure: false)
  private var chatStreaming: Chatservice_ChatServiceCreateStreamCall?
  
  func DoRegisterOrCreateRoom(roomID: String, completion: @escaping ((Room) -> Void), errorHandler: ((StatusCode, String?)->Void)? ) -> Bool {
    guard let user = UserSession.shared.user else { return false }
    var userRequest = Chatservice_RoomRequest()
    userRequest.aliasName = user.aliasName
    userRequest.roomID = roomID
    _ = try? client.registerOrJoinRoom(userRequest, completion: { (v, result) in
      if result.success,
        result.statusCode == StatusCode.ok,
        let payload = v?.response {
        let room = Room(roomID: roomID,
                        messages: payload
                          .messages
                          .compactMap{ Message(id: "\(Date().timeIntervalSince1970)-\($0.aliasname)", senderName: $0.aliasname, content: $0.message)})
        completion(room)
      } else {
        errorHandler?(result.statusCode, result.statusMessage)
      }
    })
    return true
  }
  
  func createStreamConnection(roomID: String, stream: @escaping((Message) -> Void)) throws {
    guard let user = UserSession.shared.user else { return }
    var chatServiceConnection = Chatservice_StreamConnect()
    chatServiceConnection.roomID = roomID
    chatServiceConnection.senderalias = user.aliasName
    chatServiceConnection.active = true
    chatStreaming = try? client.createStream(chatServiceConnection) { (result) in
      if !result.success {
        return
      }
    }
    try receiveUpdateMessages(stream: stream)
  }
  
  func sendMessage(roomID: String, inputMessage: String) {
    guard let user = UserSession.shared.user else { return }
    var contentMessage = Chatservice_ContentMessage()
    contentMessage.content = inputMessage
    contentMessage.roomID = roomID
    contentMessage.senderID = user.aliasName
    _ = try? client.sendMessage(contentMessage, completion: { (_, result) in
      if !result.success {
        return
      }
    })
  }
  
  private func receiveUpdateMessages(stream: @escaping((Message) -> Void)) throws {
    guard let chatStreaming = chatStreaming else { return }
    try chatStreaming.receive(completion: { (res) in
      if let senderId = res.result??.senderID, let content = res.result??.content, let roomName = res.result??.roomID {
        print("got messages \(roomName)")
        let message = Message(id: "\(Date().timeIntervalSince1970)-\(senderId)",
                              senderName: senderId,
                              content: content)
        stream(message)
        try! self.receiveUpdateMessages(stream: stream)
      } else if let error = res.error {
        print("error \(error)")
        return
      }
    })
  }
}
