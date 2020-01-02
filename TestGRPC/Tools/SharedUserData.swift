//
//  SharedUserData.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/22.
//  Copyright © 2019 curcifer. All rights reserved.
//

import SwiftUI
import Combine

final class UserSession: ObservableObject {
  static let shared = UserSession()
  private var storedUser: User?
  private var storedMessages: [Message]?
  var user: User? {
    get {
      return storedUser
    }
    set {
      objectWillChange.send()
      storedUser = newValue
    }
  }
  var messages: [Message]? {
    get {
      return storedMessages
    }
    set {
      objectWillChange.send()
      storedMessages = newValue
    }
  }
  
  var hasRoom: Bool {
    return !(storedUser?.roomId?.isEmpty ?? true)
  }
  
  var isLogin: Bool {
    return storedUser?.isLogin ?? false
  }
}
