/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Kanna

struct PageInfo {
    var URL: NSURL
    var title: String

    private static var pageMap = [NSURL: PageInfo]()

    static func pageInfoForURL(URL: NSURL, callback: PageInfo -> ()) {
        if let pageInfo = pageMap[URL] {
            dispatch_async(dispatch_get_main_queue()) {
                callback(pageInfo)
            }
            return
        }

        NSURLSession.sharedSession().dataTaskWithURL(URL) { data, response, error in
            if let data = data,
                html = NSString(data: data, encoding: NSUTF8StringEncoding),
                doc = Kanna.HTML(html: String(html), encoding: NSUTF8StringEncoding),
                title = doc.title {
                dispatch_async(dispatch_get_main_queue()) {
                    let pageInfo = PageInfo(URL: response!.URL!, title: title)
                    pageMap[URL] = pageInfo
                    callback(pageInfo)
                }
            }
        }.resume()
    }
}