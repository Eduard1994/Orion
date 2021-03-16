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
}

// MARK: - DispatchQueue
extension DispatchQueue {
    func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}


// Only push the task async if we are not already on the main thread.
// Unless you want another event to fire before your work happens. This is better than using DispatchQueue.main.async to ensure main thread
public func ensureMainThread(execute work: @escaping @convention(block) () -> Swift.Void) {
    if Thread.isMainThread {
        work()
    } else {
        DispatchQueue.main.async {
            work()
        }
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    // MARK: - Controller Instantiation
    /// Providing any type of Controllers from any Storyboard
    /// - Parameter identifier: The Identifier of the Controller
    /// - Parameter name: The Storyboard Name
    static func instantiateFromStoryboard(_ name: Storyboards.RawValue = Storyboards.Main.rawValue, with identifier: String) -> Self {
        func instantiateFromStoryboardHelper<T>(_ name: String, with identifier: String) -> T {
            let storyboard = UIStoryboard(name: name, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T
            return controller
        }
        return instantiateFromStoryboardHelper(name, with: identifier)
    }
    
    static func instantiate(from storyboard: Storyboards, with identifier: String) -> Self {
        return instantiateFromStoryboard(storyboard.rawValue, with: identifier)
    }
    
    // Type Level
    static var typeName: String {
        return String(describing: self)
    }
}
