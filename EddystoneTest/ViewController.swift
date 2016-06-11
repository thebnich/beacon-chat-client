// Copyright 2015-2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Kanna
import UIKit

private let CellIdentifier = "BeaconCell"
private let NickPrefKey = "Nick"

private class PageWrapper {
  var pageInfo: PageInfo? = nil
}

private struct PageInfo {
  var URL: NSURL
  var title: String
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
  private let chatClient = ChatClient()
  private var pages = [PageWrapper]()
  private var pageMap = [NSURL: PageInfo]()

  private let beaconTable = UITableView()

  override func viewDidLoad() {
    super.viewDidLoad()

    let nick = NSUserDefaults.standardUserDefaults().stringForKey(NickPrefKey) ?? randomNick()
    NSUserDefaults.standardUserDefaults().setObject(nick, forKey: NickPrefKey)
    chatClient.setNick(nick)
    chatClient.connect()

    let nickField = UITextField(frame: CGRectMake(0, 0, 150, 30))
    nickField.text = nick
    nickField.autocorrectionType = .No
    nickField.autocapitalizationType = .None
    nickField.backgroundColor = UIColor.whiteColor()
    nickField.textAlignment = .Center
    nickField.layer.cornerRadius = 5
    nickField.layer.borderColor = UIColor.grayColor().CGColor
    nickField.layer.borderWidth = 0.5
    nickField.delegate = self
    navigationItem.titleView = nickField

    view.addSubview(beaconTable)
    beaconTable.separatorStyle = .None
    beaconTable.rowHeight = 50
    beaconTable.translatesAutoresizingMaskIntoConstraints = false
    beaconTable.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
    beaconTable.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
    beaconTable.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
    beaconTable.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
    beaconTable.dataSource = self
    beaconTable.delegate = self

    ProximityBeaconScanner().getSortedURLs() { URLs in
      self.pages.removeAll()

      for URL in URLs {
        let wrapper = PageWrapper()
        self.pages.append(wrapper)

        self.pageInfoForURL(URL) { pageInfo in
          wrapper.pageInfo = pageInfo
          self.beaconTable.reloadData()
        }
      }
    }
  }

  // For debugging in simulator
//  override func viewDidAppear(animated: Bool) {
//    joinRoom(NSURL(string: "https://mzl.bnich.com/b/1")!)
//  }

  func randomNick() -> String {
    return "Guest\(Int(arc4random_uniform(9999) + 1))"
  }

  private func joinRoom(pageInfo: PageInfo) {
    chatClient.joinRoom(pageInfo.URL.absoluteString)

    let chatController = ChatViewController()
    chatController.title = pageInfo.title
    chatController.chatClient = chatClient

    navigationController?.pushViewController(chatController, animated: true)
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return pages.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) ?? UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
    let pageInfo = pages[indexPath.row].pageInfo
    cell.textLabel?.text = pageInfo?.title
    cell.detailTextLabel?.text = pageInfo?.URL.absoluteString
    return cell
  }

  private func pageInfoForURL(URL: NSURL, callback: PageInfo -> ()) {
    if let pageInfo = pageMap[URL] {
      callback(pageInfo)
      return
    }

    NSURLSession.sharedSession().dataTaskWithURL(URL) { data, response, error in
      if let data = data,
        html = NSString(data: data, encoding: NSUTF8StringEncoding),
        doc = Kanna.HTML(html: String(html), encoding: NSUTF8StringEncoding),
        title = doc.title {
        dispatch_async(dispatch_get_main_queue()) {
          let pageInfo = PageInfo(URL: response!.URL!, title: title)
          self.pageMap[URL] = pageInfo
          callback(pageInfo)
        }
      }
    }.resume()
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: false)
    guard let pageInfo = pages[indexPath.row].pageInfo else { return }
    joinRoom(pageInfo)
  }

  func textFieldDidBeginEditing(textField: UITextField) {
    textField.selectAll(nil)
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidEndEditing(textField: UITextField) {
    var nick = textField.text ?? ""
    if nick.isEmpty {
      nick = randomNick()
    }

    NSUserDefaults.standardUserDefaults().setObject(nick, forKey: NickPrefKey)
    chatClient.setNick(nick)
  }
}
