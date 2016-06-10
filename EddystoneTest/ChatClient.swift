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
    private var queue = [(event: String, items: [AnyObject])]()

    init() {
        socket = SocketIOClient(socketURL: SocketURL, options: [.Log(false)])

        socket.on("connect") { data, ack in
            for message in self.queue {
                self.socket.emit(message.event, message.items)
            }
            self.queue.removeAll()
        }

        socket.on("msg") { data, ack in
            guard let values = data as? [[String]] else { return }

            for value in values {
                self.delegate?.chatClientOnMessage(self, time: value[0], user: value[1], message: value[2])
            }
        }

        socket.connect()
    }

    func joinRoom(room: String) {
        emit("joinroom", room)
    }

    func leaveRoom() {
        emit("leaveroom", "")
    }

    func setNick(nick: String) {
        emit("nick", nick)
    }

    func sendMessage(message: String) {
        emit("msg", message)
    }

    private func emit(event: String, _ items: AnyObject...) {
        guard socket.status == .Connected else {
            queue.append((event, items))
            return
        }

        socket.emit(event, items)
    }
}