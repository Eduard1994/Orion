//
//  WebView+Extension.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import Foundation
import WebKit
// Temporary flag to test the new sandboxed javascript environment
// in iOS 14
private let USE_NEW_SANDBOX_APIS = true

extension WKWebView {
    
    /// This calls different WebKit evaluateJavaScript functions depending on iOS version
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        #if compiler(>=5.3)
            if #available(iOS 14.0, *), USE_NEW_SANDBOX_APIS {
                self.evaluateJavaScript(javascript, in: nil, in: .defaultClient, completionHandler: { _ in })
            } else {
                self.evaluateJavaScript(javascript)
            }
        #else
            self.evaluateJavaScript(javascript)
        #endif
    }
    
    /// This calls different WebKit evaluateJavaScript functions depending on iOS version with a completion that passes a tuple with optional data or an optional error
    ///  - If iOS14 or higher, evaluates Javascript in a .defaultClient sandboxed content world
    ///  - If below iOS14, evaluates Javascript without sandboxed environment
    /// - Parameters:
    ///     - javascript: String representing javascript to be evaluated
    ///     - completion: Tuple containing optional data and an optional error
    public func evaluateJavascriptInDefaultContentWorld(_ javascript: String,_ completion: @escaping ((Any?, Error?) -> Void)) {
        #if compiler(>=5.3)
            if #available(iOS 14.0, *), USE_NEW_SANDBOX_APIS {
                self.evaluateJavaScript(javascript, in: nil, in: .defaultClient) { result in
                    switch result {
                    case .success(let value):
                        completion(value, nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            } else {
                self.evaluateJavaScript(javascript) { data, error  in
                    completion(data, error)
                }
            }
        #else
            self.evaluateJavaScript(javascript) { data, error  in
                completion(data, error)
            }
        #endif
    }
}

extension WKUserContentController {
    public func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        if #available(iOS 14.0, *), USE_NEW_SANDBOX_APIS {
            add(scriptMessageHandler, contentWorld: .defaultClient, name: name)
        } else {
            add(scriptMessageHandler, name: name)
        }
    }
}

extension WKUserScript {
    public class func createInDefaultContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        if #available(iOS 14.0, *), USE_NEW_SANDBOX_APIS {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .defaultClient)
        } else {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }
}


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

struct MimeType {
    var type:String
    var fileExtension:String
}

protocol WKWebViewDownloadHelperDelegate {
    func fileDownloadedAtURL(url:URL)
}

class WKWebviewDownloadHelper:NSObject {
    
    var webView:WKWebView
    var mimeTypes:[MimeType]
    var delegate:WKWebViewDownloadHelperDelegate
    
    init(webView:WKWebView, mimeTypes:[MimeType], delegate:WKWebViewDownloadHelperDelegate) {
        self.webView = webView
        self.mimeTypes = mimeTypes
        self.delegate = delegate
        super.init()
        webView.navigationDelegate = self
    }
    
    private func downloadData(fromURL url:URL,
                              fileName:String,
                              completion:@escaping (Bool, URL?) -> Void) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { cookies in
            let session = URLSession.shared
            session.configuration.httpCookieStorage?.setCookies(cookies, for: url, mainDocumentURL: nil)
            let task = session.downloadTask(with: url) { localURL, urlResponse, error in
                if let localURL = localURL {
                    let destinationURL = self.moveDownloadedFile(url: localURL, fileName: fileName)
                    completion(true, destinationURL)
                }
                else {
                    completion(false, nil)
                }
            }

            task.resume()
        }
    }
    
    private func getDefaultFileName(forMimeType mimeType:String) -> String {
        for record in self.mimeTypes {
            if mimeType.contains(record.type) {
                return "default." + record.fileExtension
            }
        }
        return "default"
    }
    
    private func getFileNameFromResponse(_ response:URLResponse) -> String? {
        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            if let disposition = headers["Content-Disposition"] as? String {
                let components = disposition.components(separatedBy: " ")
                if components.count > 1 {
                    let innerComponents = components[1].components(separatedBy: "=")
                    if innerComponents.count > 1 {
                        if innerComponents[0].contains("filename") {
                            return innerComponents[1]
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func isMimeTypeConfigured(_ mimeType:String) -> Bool {
        for record in self.mimeTypes {
            if mimeType.contains(record.type) {
                return true
            }
        }
        return false
    }
    
    private func moveDownloadedFile(url:URL, fileName:String) -> URL {
        let tempDir = NSTemporaryDirectory()
        let destinationPath = tempDir + fileName
        let destinationURL = URL(fileURLWithPath: destinationPath)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: url, to: destinationURL)
        return destinationURL
    }
}

extension WKWebviewDownloadHelper: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let mimeType = navigationResponse.response.mimeType {
            if isMimeTypeConfigured(mimeType) {
                if let url = navigationResponse.response.url {
                    var fileName = getDefaultFileName(forMimeType: mimeType)
                    if let name = getFileNameFromResponse(navigationResponse.response) {
                        fileName = name
                    }
                    downloadData(fromURL: url, fileName: fileName) { success, destinationURL in
                        if success, let destinationURL = destinationURL {
                            self.delegate.fileDownloadedAtURL(url: destinationURL)
                        }
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
}
