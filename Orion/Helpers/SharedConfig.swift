//
//  SharedConfig.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

//import Foundation
import UIKit

struct SettingsKeys {
    static let firstRun = "firstRun"
    static let trackHistory = "trackHistory"
    static let adBlockEnabled = "adBlockEnabled"
    static let stringLiteralAdBlock = "stringLiteralAdBlock"
    static let adBlockPurchased = "purchasedAdBlock"
    static let needToShowAdBlockAlert = "needToShowAdBlockAlert"
    static let searchEngineUrl = "searchEngineUrl"
}

enum HostFileNames: String {
    case adaway
    case blackHosts
    case malwareHosts
    case camelon
    case zeus
    case tracker
    case simpleAds
    case adServerHosts
    case ultimateAdBlock
    
    static let allValues: [HostFileNames] = [.adaway, .blackHosts, .malwareHosts, .camelon, .zeus, .tracker, .simpleAds, .adServerHosts, .ultimateAdBlock]
}

let isiPadUI = UIDevice().userInterfaceIdiom == .pad
let isiPhone5 = UIScreen.main.bounds.height == 568

func logRealmError(error: Error) {
    print("## Realm Error: \(error.localizedDescription)")
}

func delay(_ delay: Double, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
