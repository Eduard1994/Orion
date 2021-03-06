//
//  BookmarkTableViewCell.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit

class BookmarkTableViewCell: UITableViewCell {
    
    @objc var titleTextField: UITextField?
    @objc var urlTextField: UITextField?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        imageView?.snp.remakeConstraints { (make) in
            make.left.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
            make.width.equalTo(self.contentView.snp.height)
            make.height.equalTo(88)
            make.bottom.equalTo(self.contentView)
        }
        
        titleTextField = SharedTextField().then { [unowned self] in
            $0.inset = 8
            $0.placeholder = "Bookmark Name"
            $0.clearButtonMode = .always
            
            self.contentView.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.left.equalTo(self.imageView!.snp.right)
                make.right.equalTo(self.contentView)
                make.top.equalTo(self.contentView)
                make.height.equalTo(44)
            }
        }
        
        urlTextField = SharedTextField().then { [unowned self] in
            $0.inset = 8
            $0.placeholder = "Bookmark URL"
            $0.clearButtonMode = .always
            
            self.contentView.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.left.equalTo(self.imageView!.snp.right)
                make.right.equalTo(self.contentView)
                make.top.equalTo(self.titleTextField!.snp.bottom)
                make.height.equalTo(44)
            }
        }
        
        let _ = UIView().then { [unowned self] in
            $0.backgroundColor = .lightGray
            
            self.contentView.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.top.equalTo(self.titleTextField!.snp.bottom)
                make.right.equalTo(self.contentView)
                make.left.equalTo(self.imageView!.snp.right).offset(8)
                make.height.equalTo(0.5)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

