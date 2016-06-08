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

import UIKit

class ViewController: UIViewController, BeaconScannerDelegate {

  let beaconScanner = BeaconScanner()
  let beaconText = UITextView()

  var beaconsInRange = [NSURL: (count: Int, sumRSSI: Int)]()
  var timer: NSTimer?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(beaconText)
    beaconText.scrollEnabled = false
    beaconText.font = UIFont.systemFontOfSize(20)
    beaconText.translatesAutoresizingMaskIntoConstraints = false
    beaconText.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
    beaconText.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true

    let leaveButton = UIButton()
    view.addSubview(leaveButton)
    leaveButton.setTitle("Leave room", forState: .Normal)
    leaveButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
    leaveButton.addTarget(self, action: #selector(scanForRoom), forControlEvents: .TouchUpInside)
    leaveButton.titleLabel?.font = UIFont.systemFontOfSize(20)
    leaveButton.translatesAutoresizingMaskIntoConstraints = false
    leaveButton.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
    leaveButton.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

    beaconScanner.delegate = self

    updateClosestBeacon()
    scanForRoom()
  }

  func didFindBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
    NSLog("FIND: %@", beaconInfo.description)
  }

  func didLoseBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
    NSLog("LOST: %@", beaconInfo.description)
  }

  func didUpdateBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
    guard let URL = beaconInfo.URL else { return }

    let (count, sumRSSI) = beaconsInRange[URL] ?? (0, 0)
    beaconsInRange[URL] = (count + 1, sumRSSI + beaconInfo.RSSI)

    NSLog("UPDATE: %@", beaconInfo.description)
  }

  func updateClosestBeacon() {
    // beaconsInRange is modified both on the UI thread and the background thread.
    // Make a local copy here so it doesn't change while we're iterating over it.
    let beaconsInRange = self.beaconsInRange
    let initial: (URL: NSURL, averageRSSI: Int)? = nil
    let closestBeacon = beaconsInRange.reduce(initial) { current, other in
      let averageRSSI = other.1.sumRSSI / other.1.count
      return (averageRSSI > current?.averageRSSI) ? (other.0, averageRSSI) : current
    }

    self.beaconsInRange.removeAll()

    guard let URL = closestBeacon?.URL else {
      beaconText.text = "Scanning..."
      return
    }

    joinRoom(URL)
  }

  func joinRoom(URL: NSURL) {
    timer?.invalidate()
    beaconScanner.stopScanning()
    beaconText.text = URL.absoluteString
  }

  func scanForRoom() {
    beaconsInRange.removeAll()
    updateClosestBeacon()

    beaconScanner.startScanning()
    timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(updateClosestBeacon), userInfo: nil, repeats: true)
  }
}
