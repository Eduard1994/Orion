//
//  MigrationManager.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper

class MigrationManager: NSObject {
    @objc static let shared = MigrationManager()
    
    @objc func attemptMigration() {
        let realmConfig = Realm.Configuration(
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: ExtensionModel.className()) { _, newObject in
                        newObject?["active"] = true
                    }
                }
                
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: BrowsingSession.className()) { _, newObject in
                        newObject?["selectedTabIndex"] = 0
                    }
                }
                
                if oldSchemaVersion < 3 {
                    migration.enumerateObjects(ofType: ExtensionModel.className()) { _, newObject in
                        newObject?["injectionTime"] = 1
                    }
                }
                
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: BrowsingSession.className()) { _, newObject in
                        newObject?["selectedTabIndex"] = 0
                    }
                }
                
                if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: Bookmark.className()) { _, newObject in
                        newObject?["iconURL"] = ""
                    }
                }
                
                // Using this to grand father current users in for ad blocking
                if #available(iOS 11.0, *), oldSchemaVersion < 6 {
                    KeychainWrapper.standard.set(true, forKey: SettingsKeys.adBlockPurchased)
                    UserDefaults.standard.set(true, forKey: SettingsKeys.needToShowAdBlockAlert)
                    UserDefaults.standard.set(true, forKey: SettingsKeys.adBlockEnabled)
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = realmConfig
        
        if !UserDefaults.standard.bool(forKey: "firefoxToOrionAdded") {
            if let filePath = Bundle.main.path(forResource: "FirefoxToOrion", ofType: "js"),
                let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                UserDefaults.standard.set(true, forKey: "firefoxToOrionAdded")
                
                let exten = ExtensionModel()
                exten.id = UUID().uuidString
                exten.name = "Firefox to Orion"
                exten.source = content
                exten.active = false
                
                do {
                    let realm = try Realm()
                    try realm.write {
                        realm.add(exten)
                    }
                } catch {
                    print("Realm error: \(error.localizedDescription)")
                }
            }
        }
    }
}

