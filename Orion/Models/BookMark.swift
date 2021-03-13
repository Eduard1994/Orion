//
//  BookMark.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import Foundation
import RealmSwift

class Bookmark: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var pageURL = ""
    @objc dynamic var iconURL = ""
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

