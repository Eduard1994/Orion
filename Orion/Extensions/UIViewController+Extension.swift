//
//  UIViewController+Extension.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit

// MARK: - Storyboard Names Enumeration
enum Storyboards: String {
    case Main = "Main"
    case Onboarding = "Onboarding"
    case Premium = "Premium"
}

// MARK: - DispatchQueue
extension DispatchQueue {
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
