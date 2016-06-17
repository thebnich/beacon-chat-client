/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let CellIdentifier = "ChatCell"
private let NickPrefKey = "Nick"

private struct ChatMessage {
    let time: String
    let user: String
    let message: String
}

class ChatViewController: UIViewController, ChatClientDelegate, UITableViewDataSource, KeyboardHelperDelegate {
    var chatClient: ChatClient?

    private var nickDelegate: NickTextFieldDelegate!
    private var chatDelegate: ChatTextFieldDelegate!

    private let chatTable = UITableView()
    private let scanner = ProximityBeaconScanner()
    private let titleLabel = UILabel()
    private let URLLabel = UILabel()
    private let nickField = UITextField()
    private let chatText = UITextField()

    private var chatTextBottomConstraint: NSLayoutConstraint!
    private var messages = [ChatMessage]()

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        let header = UIView()
        let refreshButton = UIButton()
        let chatTextBorder = UIView()

        nickDelegate = NickTextFieldDelegate(chatViewController: self)
        nickField.delegate = nickDelegate

        chatDelegate = ChatTextFieldDelegate(chatViewController: self)
        chatText.delegate = chatDelegate

        view.addSubview(header)
        header.addSubview(refreshButton)
        header.addSubview(titleLabel)
        header.addSubview(URLLabel)
        header.addSubview(nickField)
        view.addSubview(chatTable)
        view.addSubview(chatTextBorder)
        chatTextBorder.addSubview(chatText)

        header.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        header.translatesAutoresizingMaskIntoConstraints = false
        header.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        header.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        header.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true

        refreshButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        refreshButton.setTitle("Refresh", forState: .Normal)
        refreshButton.setTitleColor(UIColor(red: 0.13, green: 0.38, blue: 0.87, alpha: 1), forState: .Normal)
        refreshButton.setTitleColor(UIColor(red: 0.4, green: 0.6, blue: 0.95, alpha: 1), forState: .Highlighted)
        refreshButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.topAnchor.constraintEqualToAnchor(titleLabel.topAnchor).active = true
        refreshButton.bottomAnchor.constraintEqualToAnchor(nickField.bottomAnchor).active = true
        refreshButton.trailingAnchor.constraintEqualToAnchor(header.trailingAnchor, constant: -10).active = true
        refreshButton.addTarget(self, action: #selector(joinClosestRoom), forControlEvents: .TouchUpInside)

        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        titleLabel.font = UIFont.boldSystemFontOfSize(16)
        titleLabel.textAlignment = .Center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraintEqualToAnchor(header.leadingAnchor, constant: 10).active = true
        titleLabel.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 10).active = true
        titleLabel.trailingAnchor.constraintEqualToAnchor(refreshButton.leadingAnchor, constant: -10).active = true

        URLLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        URLLabel.font = UIFont.systemFontOfSize(13)
        URLLabel.textAlignment = .Center
        URLLabel.translatesAutoresizingMaskIntoConstraints = false
        URLLabel.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor).active = true
        URLLabel.leadingAnchor.constraintEqualToAnchor(header.leadingAnchor, constant: 10).active = true
        URLLabel.trailingAnchor.constraintEqualToAnchor(refreshButton.leadingAnchor, constant: -10).active = true

        nickField.adjustsFontSizeToFitWidth = true
        nickField.autocorrectionType = .No
        nickField.autocapitalizationType = .None
        nickField.backgroundColor = UIColor.whiteColor()
        nickField.textAlignment = .Center
        nickField.layer.cornerRadius = 5
        nickField.layer.borderColor = UIColor.grayColor().CGColor
        nickField.layer.borderWidth = 0.5
        nickField.translatesAutoresizingMaskIntoConstraints = false
        nickField.widthAnchor.constraintEqualToConstant(120).active = true
        nickField.topAnchor.constraintEqualToAnchor(URLLabel.bottomAnchor, constant: 10).active = true
        nickField.centerXAnchor.constraintEqualToAnchor(titleLabel.centerXAnchor).active = true
        nickField.bottomAnchor.constraintEqualToAnchor(header.bottomAnchor, constant: -10).active = true

        chatTable.separatorStyle = .None
        chatTable.translatesAutoresizingMaskIntoConstraints = false
        chatTable.topAnchor.constraintEqualToAnchor(header.bottomAnchor).active = true
        chatTable.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        chatTable.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        chatTable.dataSource = self
        chatTable.allowsSelection = false

        chatTextBorder.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        chatTextBorder.translatesAutoresizingMaskIntoConstraints = false
        chatTextBorder.topAnchor.constraintEqualToAnchor(chatTable.bottomAnchor).active = true
        chatTextBorder.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        chatTextBorder.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        chatTextBottomConstraint = chatTextBorder.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        chatTextBottomConstraint.active = true

        chatText.backgroundColor = UIColor.whiteColor()
        chatText.layer.cornerRadius = 3
        chatText.translatesAutoresizingMaskIntoConstraints = false
        chatText.leadingAnchor.constraintEqualToAnchor(chatTextBorder.leadingAnchor, constant: 4).active = true
        chatText.trailingAnchor.constraintEqualToAnchor(chatTextBorder.trailingAnchor, constant: -4).active = true
        chatText.topAnchor.constraintEqualToAnchor(chatTextBorder.topAnchor, constant: 4).active = true
        chatText.bottomAnchor.constraintEqualToAnchor(chatTextBorder.bottomAnchor, constant: -4).active = true
        chatText.heightAnchor.constraintEqualToConstant(30).active = true

        KeyboardHelper.defaultHelper.addDelegate(self)

        let nick = NSUserDefaults.standardUserDefaults().stringForKey(NickPrefKey) ?? randomNick()
        NSUserDefaults.standardUserDefaults().setObject(nick, forKey: NickPrefKey)
        nickField.text = nick
        chatClient?.setNick(nick)
        joinClosestRoom()
    }

    @objc private func joinClosestRoom() {
        self.titleLabel.text = "Scanning..."
        self.URLLabel.text = nil

        chatClient?.leaveRoom()

        scanner.getSortedURLs() { URLs in
            if let roomURL = URLs.first {
                PageInfo.pageInfoForURL(roomURL) { pageInfo in
                    self.messages.removeAll()
                    self.chatTable.reloadData()

                    self.chatClient?.joinRoom(roomURL.absoluteString)
                    self.titleLabel.text = pageInfo.title
                    self.URLLabel.text = pageInfo.URL.absoluteString
                }
            }
        }
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

    func randomNick() -> String {
        return "Guest\(Int(arc4random_uniform(9999) + 1))"
    }
}

private class ChatTextFieldDelegate: NSObject, UITextFieldDelegate {
    private unowned var chatViewController: ChatViewController

    init(chatViewController: ChatViewController) {
        self.chatViewController = chatViewController
    }

    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text where !text.isEmpty {
            chatViewController.chatClient?.sendMessage(text)
            textField.text = nil
        }

        return true
    }
}

private class NickTextFieldDelegate: NSObject, UITextFieldDelegate {
    private unowned var chatViewController: ChatViewController

    init(chatViewController: ChatViewController) {
        self.chatViewController = chatViewController
    }

    @objc func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectAll(nil)
    }

    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func textFieldDidEndEditing(textField: UITextField) {
        var nick = textField.text ?? ""
        if nick.isEmpty {
            nick = chatViewController.randomNick()
        }

        NSUserDefaults.standardUserDefaults().setObject(nick, forKey: NickPrefKey)
        chatViewController.chatClient?.setNick(nick)
    }
}