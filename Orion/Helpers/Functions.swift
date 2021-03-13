//
//  Functions.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit

/**
 Returns image with a given name from the resource bundle.
 - Parameter name: Image name.
 - Returns: An image.
 */
func imageNamed(_ name: String) -> UIImage {
    let cls = BrowserViewController.self
    var bundle = Bundle(for: cls)
    let traitCollection = UITraitCollection(displayScale: 3)
    
    if let resourceBundle = bundle.resourcePath.flatMap({ Bundle(path: $0 + "/Orion.bundle") }) {
        bundle = resourceBundle
    }
    
    guard let image = UIImage(named: name, in: bundle, compatibleWith: traitCollection) else {
        return UIImage()
    }
    
    return image
}

func openURL(path: String) {
    if let url = URL(string: path) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
