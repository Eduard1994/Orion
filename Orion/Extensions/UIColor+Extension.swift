//
//  UIColor+Extension.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import UIKit

// MARK: - UIColor Extension
extension UIColor {
    static func getColor(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
    static func fade(fromRed: CGFloat, fromGreen: CGFloat, fromBlue: CGFloat, fromAlpha: CGFloat, toRed: CGFloat, toGreen: CGFloat, toBlue: CGFloat, toAlpha: CGFloat, withPercentage percentage: CGFloat) -> UIColor {
        
        let red: CGFloat = (toRed - fromRed) * percentage + fromRed
        let green: CGFloat = (toGreen - fromGreen) * percentage + fromGreen
        let blue: CGFloat = (toBlue - fromBlue) * percentage + fromBlue
        let alpha: CGFloat = (toAlpha - fromAlpha) * percentage + fromAlpha
        
        // return the fade colour
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    static var main: UIColor {
//        return #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        return .getColor(r: 45, g: 127, b: 193)
    }
    
    static var mainGray: UIColor {
//        return #colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.937254902, alpha: 1)
        return .getColor(r: 239, g: 239, b: 239)
    }
    
    static var mainDarkGray: UIColor {
//        return #colorLiteral(red: 0.6862745098, green: 0.7058823529, blue: 0.7058823529, alpha: 1)
        return .getColor(r: 175, g: 180, b: 180)
    }
    
    static var mainUnselected: UIColor {
//        return #colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1)
        return .getColor(r: 200, g: 200, b: 200)
    }
    
    static var mainURL: UIColor {
//        return #colorLiteral(red: 0.01568627451, green: 0.4274509804, blue: 0.137254902, alpha: 1)
        return .getColor(r: 4, g: 109, b: 35)
    }
}
