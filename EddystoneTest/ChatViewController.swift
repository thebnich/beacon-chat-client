/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

let CellIdentifier = "ChatCell"

private struct ChatMessage {
    let time: String
    let user: String
    let message: String
}

class ChatViewController: UIViewController, ChatClientDelegate, UITableViewDataSource, UITextFieldDelegate {
    private let chatTable = UITableView()
    private var chatTextBottomConstraint: NSLayoutConstraint!
    private var messages = [ChatMessage]()
    private var chatClient: ChatClient?

    private lazy var chatText: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        return textField
    }()

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        let chatTextBorder = UIView()
        view.addSubview(chatTextBorder)
        chatTextBorder.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        chatTextBorder.translatesAutoresizingMaskIntoConstraints = false
        chatTextBorder.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        chatTextBorder.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        chatTextBottomConstraint = chatTextBorder.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        chatTextBottomConstraint.active = true

        chatTextBorder.addSubview(chatText)
        chatText.backgroundColor = UIColor.whiteColor()
        chatText.layer.cornerRadius = 3
        chatText.translatesAutoresizingMaskIntoConstraints = false
        chatText.leadingAnchor.constraintEqualToAnchor(chatTextBorder.leadingAnchor, constant: 4).active = true
        chatText.trailingAnchor.constraintEqualToAnchor(chatTextBorder.trailingAnchor, constant: -4).active = true
        chatText.topAnchor.constraintEqualToAnchor(chatTextBorder.topAnchor, constant: 4).active = true
        chatText.bottomAnchor.constraintEqualToAnchor(chatTextBorder.bottomAnchor, constant: -4).active = true
        chatText.heightAnchor.constraintEqualToConstant(30).active = true

        view.addSubview(chatTable)
        chatTable.separatorStyle = .None
        chatTable.translatesAutoresizingMaskIntoConstraints = false
        chatTable.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        chatTable.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        chatTable.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        chatTable.bottomAnchor.constraintEqualToAnchor(chatTextBorder.topAnchor).active = true
        chatTable.dataSource = self
        chatTable.allowsSelection = false
    }

    func loadURL(URL: NSURL) {
        chatClient = ChatClient(room: URL.absoluteString)
        chatClient?.delegate = self
    }

    func chatClientOnMessage(chatClient: ChatClient, time: String, user: String, message: String) {
        messages.append(ChatMessage(time: time, user: user, message: message))
        chatTable.reloadData()
        self.chatTable.scrollToRowAtIndexPath(NSIndexPath(forRow: self.chatTable.numberOfRowsInSection(0) - 1, inSection: 0), atScrollPosition: .Bottom, animated: true)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) ?? UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        let messageData = messages[indexPath.row]
        let string = NSMutableAttributedString(string: "\(messageData.user)  \(messageData.message)")
        string.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(14), range: NSMakeRange(0, messageData.user.characters.count))

        cell.textLabel?.font = UIFont.systemFontOfSize(14)
        cell.textLabel?.attributedText = string
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(11)
        cell.detailTextLabel?.text = messageData.time
        cell.detailTextLabel?.textColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text where !text.isEmpty {
            chatClient?.sendMessage(text)
            textField.text = nil
        }
        return true
    }
}