//
//  RoomModel.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/25.
//  Copyright © 2019 curcifer. All rights reserved.
//

import Foundation

struct Room {
  let roomID: String
  let messages: [Message]?
}

struct Message: Identifiable {
  let id: String
  let senderName: String
  let content: String
}

extension Message {
  var isSender: Bool {
    return senderName == UserSession.shared.user?.aliasName
  }
}
