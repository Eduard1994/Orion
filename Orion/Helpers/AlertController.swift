//
//  AlertController.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/15/21.
//

import UIKit

// Subclassed to support accessibility identifiers
public class AlertController: UIAlertController {
    private var accessibilityIdentifiers = [UIAlertAction: String]()

    public func addAction(_ action: UIAlertAction, accessibilityIdentifier: String) {
        super.addAction(action)
        accessibilityIdentifiers[action] = accessibilityIdentifier
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // From https://stackoverflow.com/questions/38117410/how-can-i-set-accessibilityidentifier-to-uialertcontroller
        for action in actions {
            let item = action.value(forKey: "__representer") as? UIView
            item?.accessibilityIdentifier = accessibilityIdentifiers[action]
        }
    }
}

