//
//  BrowsingSession.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import Foundation
import RealmSwift

class URLModel: Object {
    @objc dynamic var urlString = ""
    @objc dynamic var pageTitle = ""
}

class BrowsingSession: Object {
    let tabs = List<URLModel>()
    @objc dynamic var selectedTabIndex = 0
}

