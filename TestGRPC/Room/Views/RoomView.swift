//
//  SwiftUIView.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/23.
//  Copyright © 2019 curcifer. All rights reserved.
//

import SwiftUI
import Combine
import KeyboardObserving

struct RoomView: View {
  @ObservedObject var viewModel: RoomScreenViewModel
  @State var textJoinColor: Color = Color(.systemGreen)
  @State var textRoomIDColor: Color = Color(.secondaryLabel)
  init() {
    viewModel = RoomScreenViewModel()
  }
  var body: some View {
    VStack(alignment: .leading) {
      if UserSession.shared.hasRoom {
        Button(action: {
          self.viewModel.fetchAction.send(.goAway)
        }, label: {
          Text("Go Away").foregroundColor(textJoinColor)
        })
          .padding(8)
          .border(textJoinColor, width: 1)
      }
      HStack {
        VStack {
          VStack {
            Text("RoomID: ")
              .font(Font.system(size: 14))
              .foregroundColor(textJoinColor)
              .padding(.top, 8)
            TextField("Input your Room", text: $viewModel.roomID)
              .font(Font.system(size: 14))
              .multilineTextAlignment(.center)
              .padding(.bottom, 8)
              .disabled(UserSession.shared.hasRoom)
              .foregroundColor(textRoomIDColor)
          }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)).border(textJoinColor, width: 1)
          VStack {
            if UserSession.shared.hasRoom {
              Button(action: {
                self.viewModel.fetchAction.send(.outOfTheRoom)
                self.textJoinColor = Color(.systemGreen)
                self.textRoomIDColor = Color(.secondaryLabel)
              }) {
                HStack {
                    Text("Out the room").foregroundColor(textJoinColor).padding()
                    .foregroundColor(.white)
                    .cornerRadius(40)
                    .border(textJoinColor)
                  }.frame(minWidth: 0, maxWidth: .infinity)
              }
            } else {
              Button(action: {
                if self.viewModel.roomID.count > 0 {
                  self.viewModel.fetchAction.send(.createOrJoinRoom)
                  self.textJoinColor = Color(.systemRed)
                  self.textRoomIDColor = Color(.systemGreen)
                }
                }) {
                  HStack {
                    Text("Join Room").foregroundColor(textJoinColor).padding()
                    .foregroundColor(.white)
                    .cornerRadius(40)
                    .border(textJoinColor)
                  }.frame(minWidth: 0, maxWidth: .infinity)
              }
            }
          }
        }.padding(.top, 8)
      }
      Spacer(minLength: 8)
      if UserSession.shared.hasRoom {
        Divider().background(textJoinColor)
        MessageListView(messageCollection: UserSession.shared.messages ?? [])
        Spacer(minLength: 8)
        HStack {
          TextField("Input your Messages", text: $viewModel.inputMessage)
          .multilineTextAlignment(.trailing)
          Button(action: {
            self.viewModel.fetchAction.send(.sendMessage)
          }) {
            Text("Send").foregroundColor(Color(.systemYellow))
          }
        }
      }
      Spacer(minLength: 8)
    }.padding([.trailing, .leading], 8)
    .keyboardObserving(offset: 8)
  }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        RoomView()
    }
}
