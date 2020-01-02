//
//  MessageList.swift
//  TestGRPC
//
//  Created by Yoseph Wijaya on 2019/12/29.
//  Copyright © 2019 curcifer. All rights reserved.
//

import SwiftUI

struct MessageListView: View {
  let messageCollection: [Message]
    var body: some View {
      List {
        ForEach(messageCollection) { (messageData) in
          HStack {
            VStack(alignment: messageData.isSender ? .trailing : .leading) {
              if messageData.isSender {
                Text("\(messageData.senderName)").bold()
              } else {
                Text("\(messageData.senderName)").italic()
              }
              
              Text("\(messageData.content)").font(Font.system(size: 12))
              Divider()
            }.rotationEffect(.degrees(-180))
          }
        }
      }.onAppear {
        UITableView.appearance().separatorStyle = .none
      }.rotationEffect(.degrees(-180))
    }
}

struct MessageList_Previews: PreviewProvider {
    static var previews: some View {
      let dummyMessage: [Message] = [Message(id: "dummy#1", senderName: "dummy", content: "hey1"), Message(id: "dummy#1", senderName: "dummy", content: "hey2"), Message(id: "dummy#1", senderName: "dummy", content: "hey3")]
      return MessageListView(messageCollection: dummyMessage)
    }
}

