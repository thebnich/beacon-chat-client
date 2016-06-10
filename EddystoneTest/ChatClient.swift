/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SocketIOClientSwift

private let SocketURL = NSURL(string: "https://chat.bnich.com")!

protocol ChatClientDelegate: class {
    func chatClientOnMessage(chatClient: ChatClient, time: String, user: String, message: String)
}

class ChatClient {
    weak var delegate: ChatClientDelegate?

    private let socket: SocketIOClient

    init() {
        socket = SocketIOClient(socketURL: SocketURL, options: [.Log(false)])

        socket.on("msg") { data, ack in
            guard let values = data as? [[String]] else { return }

            for value in values {
                self.delegate?.chatClientOnMessage(self, time: value[0], user: value[1], message: value[2])
            }
        }

        socket.connect()
    }

    func joinRoom(room: String) {
        self.socket.emit("joinroom", room)
    }

    func leaveRoom() {
        self.socket.emit("leaveroom", "")
    }

    func setNick(nick: String) {
        self.socket.emit("nick", nick)
    }

    func sendMessage(message: String) {
        socket.emit("msg", message)
    }
}