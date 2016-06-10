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
    private var queue = [(event: String, msg: String)]()
    private var nick = "?"
    private var room: String?

    init() {
        socket = SocketIOClient(socketURL: SocketURL, options: [.ForcePolling(true), .Log(false)])

        socket.on("msg") { [unowned self] data, ack in
            guard let values = data as? [[String]] else { return }

            for value in values {
                self.delegate?.chatClientOnMessage(self, time: value[0], user: value[1], message: value[2])
            }
        }

        socket.on("connect") { [unowned self] data, ack in
            self.setNick(self.nick)

            if let room = self.room {
                self.joinRoom(room)
            }

            for message in self.queue {
                self.socket.emit(message.event, message.msg)
            }

            self.queue.removeAll()
        }
    }

    func connect() {
        socket.connect()
    }

    func joinRoom(room: String) {
        self.room = room
        socket.emit("joinroom", room)
    }

    func leaveRoom() {
        self.room = nil
        socket.emit("leaveroom", "")
    }

    func setNick(nick: String) {
        self.nick = nick
        self.socket.emit("nick", nick)
    }

    func sendMessage(message: String) {
        emit("msg", message)
    }

    private func emit(event: String, _ msg: String) {
        guard socket.status == .Connected else {
            queue.append((event, msg))
            return
        }

        socket.emit(event, msg)
    }
}