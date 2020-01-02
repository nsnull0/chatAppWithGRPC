//
//  LoginView.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/22.
//  Copyright © 2019 curcifer. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct LoginView: View {
  private let edgeDefault: CGFloat = 8
  @ObservedObject private var viewModel: LoginScreenViewModel = LoginScreenViewModel(user: UserSession.shared.user ?? User(aliasName: "", roomId: nil, isLogin: false))
  @State private var loginSuccess: Bool = false
    var body: some View {
      HStack {
        Spacer(minLength: 32)
        VStack {
          HStack {
            VStack(alignment: .center, spacing: CGFloat(8)) {
              TextField("Enter you alias name", text: $viewModel.aliasName)
            }
            
          }.padding(EdgeInsets.init(top: edgeDefault,
                                    leading: edgeDefault,
                                    bottom: edgeDefault,
                                    trailing: edgeDefault))
            .multilineTextAlignment(.center)
          
          VStack(alignment: .center) {
            Text("\(viewModel.loginViewMessage)")
              .foregroundColor(viewModel.statusText.getColor)
              .bold().multilineTextAlignment(.center)
          }
          Button(action: {
            self.viewModel.fetchAction.send(.login)
          }) {
            Text("Login or Register")
          }.padding(8)
            .disabled(viewModel.statusText.isDisabledLoginButton)
        }.border(Color(.systemGray), width: 1)
        Spacer(minLength: 32)
      }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
      return LoginView()
    }
}
#endif
