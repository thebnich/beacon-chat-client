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
import CoreBluetooth

///
/// BeaconScannerDelegate
///
/// Implement this to receive notifications about beacons.
protocol BeaconScannerDelegate: class {
  func didFindBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
  func didLoseBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
  func didUpdateBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
}

///
/// BeaconScanner
///
/// Scans for Eddystone compliant beacons using Core Bluetooth. To receive notifications of any
/// sighted beacons, be sure to implement BeaconScannerDelegate and set that on the scanner.
///
class BeaconScanner: NSObject, CBCentralManagerDelegate {

  weak var delegate: BeaconScannerDelegate?

  ///
  /// How long we should go without a beacon sighting before considering it "lost". In seconds.
  ///
  var onLostTimeout: Double = 15.0

  private var centralManager: CBCentralManager!
  private let beaconOperationsQueue: dispatch_queue_t =
      dispatch_queue_create("beacon_operations_queue", nil)
  private var shouldBeScanning: Bool = false

  private var seenEddystoneCache = [String : [String : AnyObject]]()
  private var deviceIDCache = [NSUUID : NSData]()

  override init() {
    super.init()

    self.centralManager = CBCentralManager(delegate: self, queue: self.beaconOperationsQueue)
    self.centralManager.delegate = self
  }

  ///
  /// Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts
  /// scanning.
  ///
  func startScanning() {
    dispatch_async(self.beaconOperationsQueue) {
      self.startScanningSynchronized()
    }
  }

  ///
  /// Stops scanning for Eddystone beacons.
  ///
  func stopScanning() {
    self.centralManager.stopScan()
  }

  ///
  /// MARK - private methods and delegate callbacks
  ///
  func centralManagerDidUpdateState(central: CBCentralManager) {
    if central.state == CBCentralManagerState.PoweredOn && self.shouldBeScanning {
      self.startScanningSynchronized();
    }
  }

  ///
  /// Core Bluetooth CBCentralManager callback when we discover a beacon. We're not super 
  /// interested in any error situations at this point in time.
  ///
  func centralManager(central: CBCentralManager,
                      didDiscoverPeripheral peripheral: CBPeripheral,
                                            advertisementData: [String : AnyObject],
                                            RSSI: NSNumber) {
    guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey]
        as? [NSObject : AnyObject] else {
      NSLog("Unable to find service data; can't process Eddystone")
      return
    }

    var eft: BeaconInfo.EddystoneFrameType
    eft = BeaconInfo.frameTypeForFrame(serviceData)

    // If it's a telemetry frame, stash it away and we'll send it along with the next regular
    // frame we see. Otherwise, process the UID frame.
    if eft == BeaconInfo.EddystoneFrameType.TelemetryFrameType {
      deviceIDCache[peripheral.identifier] = BeaconInfo.telemetryDataForFrame(serviceData)
      return
    }

    let _RSSI: Int = RSSI.integerValue
    let serviceUUID = CBUUID(string: "FEAA")
    let telemetry = self.deviceIDCache[peripheral.identifier]

    guard let beaconServiceData = serviceData[serviceUUID] as? NSData else { return }

    let info: BeaconInfo?
    switch eft {
    case BeaconInfo.EddystoneFrameType.UIDFrameType:
      info = BeaconInfo.beaconInfoForUIDFrameData(beaconServiceData, telemetry: telemetry, RSSI: _RSSI)
    case BeaconInfo.EddystoneFrameType.EIDFrameType:
      info = BeaconInfo.beaconInfoForEIDFrameData(beaconServiceData, telemetry: telemetry, RSSI: _RSSI)
    case BeaconInfo.EddystoneFrameType.URLFrameType:
      info = BeaconInfo.beaconInfoForURLFrameData(beaconServiceData, telemetry: telemetry, RSSI: _RSSI)
    default:
      info = nil
    }

    guard let beaconInfo = info,
          let cacheKey = beaconInfo.extendedInfo?.beaconID.description ??
                beaconInfo.URL?.absoluteString else { return }

    // NOTE: At this point you can choose whether to keep or get rid of the telemetry
    //       data. You can either opt to include it with every single beacon sighting
    //       for this beacon, or delete it until we get a new / "fresh" TLM frame.
    //       We'll treat it as "report it only when you see it", so we'll delete it
    //       each time.
    self.deviceIDCache.removeValueForKey(peripheral.identifier)

    if (self.seenEddystoneCache[cacheKey] != nil) {
      // Reset the onLost timer and fire the didUpdate.
      if let timer =
        self.seenEddystoneCache[cacheKey]?["onLostTimer"]
          as? DispatchTimer {
        timer.reschedule()
      }

      self.delegate?.didUpdateBeacon(self, beaconInfo: beaconInfo)
    } else {
      // We've never seen this beacon before
      self.delegate?.didFindBeacon(self, beaconInfo: beaconInfo)

      let onLostTimer = DispatchTimer.scheduledDispatchTimer(
        self.onLostTimeout,
        queue: dispatch_get_main_queue()) {
          (timer: DispatchTimer) -> () in
          if let
            beaconCache = self.seenEddystoneCache[cacheKey],
            lostBeaconInfo = beaconCache["beaconInfo"] as? BeaconInfo {
            self.delegate?.didLoseBeacon(self, beaconInfo: lostBeaconInfo)
            self.seenEddystoneCache.removeValueForKey(cacheKey)
          }
      }

      self.seenEddystoneCache[cacheKey] = [
        "beaconInfo" : beaconInfo,
        "onLostTimer" : onLostTimer
      ]
    }
  }

  private func startScanningSynchronized() {
    if self.centralManager.state != CBCentralManagerState.PoweredOn {
      NSLog("CentralManager state is %d, cannot start scan", self.centralManager.state.rawValue)
      self.shouldBeScanning = true
    } else {
      NSLog("Starting to scan for Eddystones")
      let services = [CBUUID(string: "FEAA")]
      let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
      self.centralManager.scanForPeripheralsWithServices(services, options: options)
    }
  }
}
