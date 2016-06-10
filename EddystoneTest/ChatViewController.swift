/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let CellIdentifier = "ChatCell"

private struct ChatMessage {
    let time: String
    let user: String
    let message: String
}

class ChatViewController: UIViewController, ChatClientDelegate, UITableViewDataSource, UITextFieldDelegate, KeyboardHelperDelegate {
    var chatClient: ChatClient? {
        didSet {
            chatClient?.delegate = self
        }
    }

    let titleLabel = UILabel()
    let URLLabel = UILabel()

    private let chatTable = UITableView()
    private var chatTextBottomConstraint: NSLayoutConstraint!
    private var messages = [ChatMessage]()

    private lazy var chatText: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        return textField
    }()

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        let header = UIView()
        view.addSubview(header)
        header.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        header.translatesAutoresizingMaskIntoConstraints = false
        header.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        header.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        header.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true

        header.addSubview(titleLabel)
        titleLabel.font = UIFont.boldSystemFontOfSize(14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 10).active = true
        titleLabel.leadingAnchor.constraintEqualToAnchor(header.leadingAnchor, constant: 10).active = true
        titleLabel.trailingAnchor.constraintEqualToAnchor(header.trailingAnchor, constant: -10).active = true

        header.addSubview(URLLabel)
        URLLabel.font = UIFont.systemFontOfSize(12)
        URLLabel.translatesAutoresizingMaskIntoConstraints = false
        URLLabel.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor).active = true
        URLLabel.leadingAnchor.constraintEqualToAnchor(header.leadingAnchor, constant: 10).active = true
        URLLabel.trailingAnchor.constraintEqualToAnchor(header.trailingAnchor, constant: -10).active = true
        URLLabel.bottomAnchor.constraintEqualToAnchor(header.bottomAnchor, constant: -10).active = true

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
        chatTable.topAnchor.constraintEqualToAnchor(header.bottomAnchor).active = true
        chatTable.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        chatTable.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        chatTable.bottomAnchor.constraintEqualToAnchor(chatTextBorder.topAnchor).active = true
        chatTable.dataSource = self
        chatTable.allowsSelection = false

        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    func chatClientOnMessage(chatClient: ChatClient, time: String, user: String, message: String) {
        messages.append(ChatMessage(time: time, user: user, message: message))
        chatTable.reloadData()
        scrollToBottom(animated: true)
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

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let keyboardHeight = state.intersectionHeightForView(self.view) ?? 0
        UIView.animateWithDuration(state.animationDuration) {
            self.chatTextBottomConstraint.constant = -keyboardHeight
            UIView.setAnimationCurve(state.animationCurve)
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        UIView.animateWithDuration(state.animationDuration) {
            self.chatTextBottomConstraint.constant = 0
            UIView.setAnimationCurve(state.animationCurve)
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToBottom(animated animated: Bool) {
        let bottomRow = self.chatTable.numberOfRowsInSection(0) - 1
        if bottomRow >= 0 {
            self.chatTable.scrollToRowAtIndexPath(NSIndexPath(forRow: bottomRow, inSection: 0), atScrollPosition: .Bottom, animated: animated)
        }
    }
}