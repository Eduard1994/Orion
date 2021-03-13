//
//  AutocompleteView.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit
import LUAutocompleteView

class AutocompleteTableViewCell: LUAutocompleteTableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        detailTextLabel?.textColor = .gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func set(text: String) {
        textLabel?.text = text
        DispatchQueue.global().async {
            let pageTitle = SuggestionManager.shared.pageTitle(forURLSring: text)
            DispatchQueue.main.async {
                self.detailTextLabel?.text = pageTitle
            }
        }
    }
}

