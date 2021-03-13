//
//  AppDelegate.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    @objc var mainController: BrowserViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if arch(i386) || arch(x86_64)
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            NSLog("Document Path: %@", documentsPath)
        #endif
        
        MigrationManager.shared.attemptMigration()
        
        WebServer.shared.startServer()
        
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: SettingsKeys.firstRun) {
            defaults.set(true, forKey: SettingsKeys.firstRun)
            performFirstRunTasks()
        }
        if defaults.string(forKey: SettingsKeys.searchEngineUrl) == nil {
            defaults.set("https://duckduckgo.com/?q=", forKey: SettingsKeys.searchEngineUrl)
        }
        
        #if DEBUG
//            KeychainWrapper.standard.set(false, forKey: SettingsKeys.adBlockPurchased)
        #endif
        defaults.set(false, forKey: SettingsKeys.stringLiteralAdBlock)
        for hostFile in HostFileNames.allValues {
            defaults.set(false, forKey: hostFile.rawValue)
        }
        
        mainController = BrowserViewController()
        self.window?.rootViewController = mainController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func performFirstRunTasks() {
        UserDefaults.standard.set(true, forKey: SettingsKeys.trackHistory)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        mainController?.tabContainer?.saveBrowsingSession()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        mainController?.tabContainer?.saveBrowsingSession()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            let source = try String(contentsOf: url, encoding: .utf8)
            mainController?.openEditor(withSource: source, andName: url.deletingPathExtension().lastPathComponent)
        } catch {
            print("Could not open file")
        }
        
        return true
    }
}

