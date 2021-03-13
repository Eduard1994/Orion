//
//  TabCountButton.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit

class TabCountButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.black, for: .normal)
        
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1.5
        layer.cornerRadius = 4
        
        setTitle("0", for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCount(_ newCount: Int) {
        setTitle("\(newCount)", for: .normal)
    }
}

