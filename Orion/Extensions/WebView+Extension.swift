//
//  WebView+Extension.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import Foundation
import WebKit

// MARK: - WebView Extension
extension WKWebView {
    /// Loading url functionality
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}
