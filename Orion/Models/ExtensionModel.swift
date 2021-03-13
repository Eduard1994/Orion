//
//  ExtensionModel.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import Foundation
import RealmSwift

class ExtensionModel: Object {
    @objc dynamic var source = ""
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var active = true
    @objc dynamic var injectionTime = 1 // 0 == Start, 1 == End
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

