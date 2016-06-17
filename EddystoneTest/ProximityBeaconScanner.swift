/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ProximityBeaconScanner: BeaconScannerDelegate {
    private let beaconScanner = BeaconScanner()
    private var beaconsInRange = [NSURL: (count: Int, sumRSSI: Int)]()

    init() {
        beaconScanner.delegate = self
    }

    func didFindBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
        print("found beacon: \(beaconInfo.URL)")
    }

    func didLoseBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {}

    func didUpdateBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
        // +127 is returned if the value cannot be read.
        guard let URL = beaconInfo.URL where beaconInfo.RSSI != 127 else { return }

        let (count, sumRSSI) = beaconsInRange[URL] ?? (0, 0)
        beaconsInRange[URL] = (count + 1, sumRSSI + beaconInfo.RSSI)
    }

    /// Returns the list of available beacons sorted by strongest signal.
    func getSortedURLs(callback: [NSURL] -> ()) {
        self.beaconsInRange.removeAll()
        beaconScanner.startScanning()

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.beaconScanner.stopScanning()

            let sortedBeacons = self.beaconsInRange.sort() { beacon1, beacon2 in
                return beacon1.1.sumRSSI / beacon1.1.count > beacon2.1.sumRSSI / beacon2.1.count
            }

            callback(sortedBeacons.map { $0.0 })
        }
    }
}