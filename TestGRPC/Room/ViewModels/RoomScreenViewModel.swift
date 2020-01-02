//
//  RoomScreenViewModel.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/25.
//  Copyright © 2019 curcifer. All rights reserved.
//

import Combine
import Foundation

final class RoomScreenViewModel: ObservableObject {
  
  private var roomClientGuide: RoomClientGuide
  private var cancellableSet: Set<AnyCancellable> = []
  private var isStreaming: Bool = false
  var roomIsValid: Bool = false
  
  enum Action {
    case createOrJoinRoom
    case connectToRoom
    case outOfTheRoom
    case sendMessage
    case goAway
    case nothing
  }
  
  enum RoomStatus {
    case joinStatus(status: String)
    case joinError(status: String)
  }
  
  // Input
  @Published var roomID: String
  @Published var inputMessage: String
  
  // Output
  let fetchAction: PassthroughSubject<Action, Never> = PassthroughSubject<Action, Never>()
  let fetchStatus: PassthroughSubject<RoomStatus, Never> = PassthroughSubject<RoomStatus, Never>()
  @Published var room: Room?
  @Published var statusText: String = ""
  @Published var statusAction: Action = .nothing
  
  init() {
    roomClientGuide = RoomClientGuide()
    roomID = UserSession.shared.user?.roomId ?? ""
    inputMessage = ""
    fetchAction.sink { [weak self] (v) in
      guard let self = self else { return }
      self.statusAction = v
      switch v {
      case .createOrJoinRoom:
        self.doCreateRoom()
      case .sendMessage:
        self.roomClientGuide.sendMessage(roomID: self.roomID,
                                         inputMessage: self.inputMessage)
        self.inputMessage = ""
      case .connectToRoom:
        self.createStream()
      case .outOfTheRoom:
        UserSession.shared.user?.roomId = nil
      case .goAway:
        UserSession.shared.user = nil
      case .nothing:
        break
      }
    }.store(in: &cancellableSet)
  }
  
  private func doCreateRoom() {
    let isValid = roomClientGuide.DoRegisterOrCreateRoom(roomID: self.roomID, completion: { [weak self] (room) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        UserSession.shared.user?.roomId = room.roomID
        UserSession.shared.messages = room.messages
        self.room = room
        self.roomIsValid = true
        self.fetchAction.send(.connectToRoom)
      }
    }) { [weak self] (statusCode, message) in
      DispatchQueue.main.async {
        self?.statusText = "status: \(statusCode.rawValue) \(message ?? "")"
      }
    }
    
    if !isValid {
      DispatchQueue.main.async {
        self.roomIsValid = false
      }
    }
  }
  
  private func createStream() {
    _ = try? roomClientGuide.createStreamConnection(roomID: self.roomID) { (message) in
      DispatchQueue.main.async {
        UserSession.shared.messages?.insert(message, at: 0)
      }
    }
  }
  
  
}


