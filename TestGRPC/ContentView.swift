//
//  ContentView.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/15.
//  Copyright © 2019 curcifer. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
  @ObservedObject var session = UserSession.shared
    var body: some View {
      VStack {
        if session.isLogin {
          RoomView()
        } else {
          LoginView()
        }
      }.navigationBarTitle("Session Chat")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

