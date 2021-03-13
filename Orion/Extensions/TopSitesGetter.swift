//
//  TopSitesGetter.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/13/21.
//

import UIKit
import WebKit

class TopSitesGetter: BuiltinExtension {
    override var extensionName: String {
        return "Top Sites Getter"
    }
    
    override init(container: WebContainer) {
        super.init(container: container)
        
        scriptHandlerName = "topSitesMessageHandler"
        
        if let path = Bundle.main.url(forResource: "TopSites", withExtension: "js") {
            if let source = try? String(contentsOf: path, encoding: .utf8) {
                let userscript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                webScript = userscript
                container.webView?.configuration.userContentController.addUserScript(userscript)
            }
        }
    }
}

// MARK: - WKScripMessageHandler
extension TopSitesGetter: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message as? [Any] else {
            return
        }
        
        print(body)
    }
}
