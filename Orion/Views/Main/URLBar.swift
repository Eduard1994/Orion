//
//  URLBar.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import UIKit
import SnapKit

class URLBar: UIView {
    // MARK: - Properties
    /// Standard Height
    @objc static let standardHeight: CGFloat = 44
    
    /// Back Button for going back.
    @objc var backButton: UIButton?
    /// Forward Button for going forward.
    @objc var forwardButton: UIButton?
    /// Refresh Button for refreshing.
    @objc var refreshButton: UIButton?
    /// URL Field
    @objc var urlField: UITextField?
    /// Menu Button.
    @objc var menuButton: UIButton?
    
    /// Tab Container
    @objc weak var tabContainer: TabContainerView?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .main
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 0.5
        
        backButton = UIButton().then { [unowned self] in
            $0.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
            $0.setTitleColor(.black, for: .normal)
            $0.setTitleColor(.lightGray, for: .disabled)
            $0.tintColor = .lightGray
            $0.isEnabled = false
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.left.equalTo(self).offset(8)
                make.width.equalTo(32)
                make.centerY.equalTo(self)
            }
        }
        
        if isiPadUI {
            forwardButton = UIButton().then { [unowned self] in
                $0.setImage(UIImage(named: "forward")?.withRenderingMode(.alwaysTemplate), for: .normal)
                $0.setTitleColor(.black, for: .normal)
                $0.setTitleColor(.lightGray, for: .disabled)
                $0.isEnabled = false
                $0.tintColor = .lightGray
                
                self.addSubview($0)
                $0.snp.makeConstraints { (make) in
                    make.left.equalTo(self.backButton!.snp.right).offset(8)
                    make.width.equalTo(32)
                    make.centerY.equalTo(self)
                }
            }
        }
        
        menuButton = UIButton().then { [unowned self] in
            $0.setImage(UIImage(named: "menu"), for: .normal)
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.width.equalTo(25)
                make.height.equalTo(25)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(-8)
            }
        }
        
        refreshButton = UIButton(frame: CGRect(x: -5, y: 0, width: 12.5, height: 15)).then {
            $0.setImage(imageNamed("refresh"), for: .normal)
            $0.tintColor = .gray
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.width.equalTo(25)
                make.height.equalTo(25)
                make.centerY.equalTo(self)
                make.right.equalTo(self.menuButton!.snp.left).offset(-8)
            }
//            urlField?.rightView = $0
//            urlField?.rightViewMode = .unlessEditing
        }
        
        urlField = SharedTextField().then { [unowned self] in
            $0.placeholder = "Address"
            $0.textColor = .darkGray
            $0.tintColor = .darkGray
            $0.backgroundColor = .white
            $0.layer.borderColor = UIColor.lightGray.cgColor
            $0.layer.borderWidth = 0.5
            $0.layer.cornerRadius = 4
            $0.inset = 8
            
            $0.autocorrectionType = .no
            $0.autocapitalizationType = .none
            $0.keyboardType = .webSearch
            $0.delegate = self
            $0.clearButtonMode = .whileEditing
            
            if !isiPadUI {
                $0.inputAccessoryView = DoneAccessoryView(targetView: $0, width: UIScreen.main.bounds.width).then { obj in
                    obj.doneButton?.setTitle("Cancel", for: .normal)
                    obj.doneButton?.snp.updateConstraints { make in
                        make.width.equalTo(60)
                    }
                }
            }
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                if isiPadUI {
                    make.left.equalTo(self.forwardButton!.snp.right).offset(8)
                } else {
                    make.left.equalTo(self.backButton!.snp.right).offset(8)
                }
                make.top.equalTo(self).offset(8)
                make.bottom.equalTo(self).offset(-8)
                make.right.equalTo(self.refreshButton!.snp.left).offset(-8)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    @objc func setupNaviagtionActions(forTabConatiner tabContainer: TabContainerView) {
        backButton?.addTarget(tabContainer, action: #selector(tabContainer.goBack(sender:)), for: .touchUpInside)
        forwardButton?.addTarget(tabContainer, action: #selector(tabContainer.goForward(sender:)), for: .touchUpInside)
        refreshButton?.addTarget(tabContainer, action: #selector(tabContainer.refresh(sender:)), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc func setAddressText(_ text: String?) {
        guard let _ = urlField else { return }
        
        if !urlField!.isFirstResponder {
            urlField?.text = text
            checkForLocalhost()
        }
    }
    
    @objc func setAttributedAddressText(_ text: NSAttributedString) {
        guard let _ = urlField else { return }
        
        if !urlField!.isFirstResponder {
            urlField?.attributedText = text
            checkForLocalhost()
        }
    }
    
    func checkForLocalhost() {
        if let address = urlField?.text, address.contains("localhost") {
            urlField?.text = ""
        }
    }
}

// MARK: - UITextFieldDelegate
extension URLBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tabContainer?.loadQuery(string: textField.text)
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let string = textField.attributedText?.mutableCopy() as? NSMutableAttributedString {
            string.setAttributes(convertToOptionalNSAttributedStringKeyDictionary([:]), range: NSRange(0..<string.length))
            textField.attributedText = string
        }
        if let text = textField.text, !text.isEmpty {
            textField.selectAll(nil)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
