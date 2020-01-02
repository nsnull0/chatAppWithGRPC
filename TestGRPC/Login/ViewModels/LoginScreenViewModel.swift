//
//  LoginScreenViewModel.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/22.
//  Copyright © 2019 curcifer. All rights reserved.
//

import Foundation
import Combine
import SwiftGRPC
import SwiftUI

class LoginScreenViewModel: ObservableObject {
  
  private var loginGuide: LoginClientGuide
  private var cancellableSet: Set<AnyCancellable> = []
  private(set) var hasRoom: Bool = false
  
  // TODO: Localize
  enum StatusText {
    case hasRoomAndLogin
    case noRoomYet
    case hasError(errorMessage: String)
    case nothing
    var getState: String {
      switch self {
      case .hasRoomAndLogin:
        return "Wait a moment ..."
      case .noRoomYet:
        return "You haven't join any room"
      case .hasError(let errorMessage):
        return errorMessage
      case .nothing:
        return "Welcome"
      }
    }
    var getColor: Color {
      switch self {
      case .hasRoomAndLogin, .noRoomYet:
        return Color(.systemYellow)
      case .hasError:
        return Color(.systemRed)
      case .nothing:
        return Color(.systemGreen)
      }
    }
    var isDisabledLoginButton: Bool {
      switch self {
      case .hasRoomAndLogin, .noRoomYet:
        return true
      case .hasError, .nothing:
        return false
      }
    }
  }
  
  // TODO: Maybe more
  enum Action {
    case login
  }
  
  /// Published for input
  @Published var aliasName: String = ""
  @Published var roomID: String = ""
  
  /// Published for output
  @Published var statusText: StatusText = .nothing
  @Published var loginViewMessage: String = ""
  let fetchAction: PassthroughSubject<Action, Never> = PassthroughSubject<Action, Never>()
  
  private var gotErrorPublisher: AnyPublisher<String, Never> {
    $statusText.map { v in
      return v.getState
    }.eraseToAnyPublisher()
  }
  
  init(user: User) {
    loginGuide = LoginClientGuide(user: user)
    gotErrorPublisher
      .receive(on: RunLoop.main)
      .assign(to: \.loginViewMessage, on: self)
      .store(in: &cancellableSet)
    fetchAction
      .receive(on: RunLoop.main)
      .handleEvents()
      .sink { [weak self] v in
        guard let self = self else { return }
        switch v {
        case .login:
          self.loginOrRegister()
        }
    }.store(in: &cancellableSet)
  }
  
  private func loginOrRegister() {
    loginGuide = LoginClientGuide(user: User(aliasName: aliasName, roomId: roomID, isLogin: false))
    loginGuide.DoLogin(completion: { [weak self] (user, hasRoom) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.statusText = hasRoom ? .hasRoomAndLogin : .noRoomYet
        self.hasRoom = hasRoom
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        UserSession.shared.user = user
      }
    }) { [weak self] (statusCode, message) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.statusText = .hasError(errorMessage: "StatusCode : \(statusCode.rawValue) \("" + (message ?? ""))")
      }
    }
  }
}
