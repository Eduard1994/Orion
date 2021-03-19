//
//  WebContainerView.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import UIKit
import WebKit
import SDWebImage
import RealmSwift
import Zip

class WebContainer: UIView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    @objc weak var parentView: UIView?
    @objc var webView: WKWebView?
    @objc var isObserving = false
    
    @objc weak var tabView: TabView?
    var favicon: Favicon?
    var currentScreenshot: UIImage?
    @objc var builtinExtensions: [BuiltinExtension]?
    
    @objc var progressView: UIProgressView?
    
    @objc var notificationToken: NotificationToken!
    
    deinit {
        if isObserving {
            webView?.removeObserver(self, forKeyPath: "estimatedProgress")
            webView?.removeObserver(self, forKeyPath: "title")
        }
        notificationToken.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc init(parent: UIView) {
        super.init(frame: .zero)
        
        NotificationCenter.default.addObserver(self, selector: #selector(adBlockChanged), name: NSNotification.Name.adBlockSettingsChanged, object: nil)
        
        self.parentView = parent
        
        backgroundColor = .white
        
        webView = WKWebView(frame: .zero, configuration: loadConfiguration()).then { [unowned self] in
            $0.customUserAgent = UserAgent.desktopUserAgent()
            $0.allowsLinkPreview = true
            $0.allowsBackForwardNavigationGestures = true
            $0.navigationDelegate = self
            $0.uiDelegate = self
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.edges.equalTo(self)
            }
        }
        
        progressView = UIProgressView().then { [unowned self] in
            $0.isHidden = true
            
            self.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.width.equalTo(self)
                make.top.equalTo(self)
                make.left.equalTo(self)
            }
        }
        
        do {
            let realm = try Realm()
            self.notificationToken = realm.observe { _, _ in
                self.reloadExtensions()
            }
        } catch let error as NSError {
            print("Error occured opening realm: \(error.localizedDescription)")
        }
        
        loadBuiltins()
        loadAdBlocking { [weak self] in
            if self?.webView?.url == nil {
                let _ = self?.webView?.load(URLRequest(url: URL(string: "http://localhost:8080")!))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration Setup
    @objc func loadBuiltins() {
        builtinExtensions = WebViewManager.shared.loadBuiltinExtensions(webContainer: self)
        builtinExtensions?.forEach {
            if let handler = $0 as? WKScriptMessageHandler, let handlerName = $0.scriptHandlerName {
                webView?.configuration.userContentController.add(handler, name: handlerName)
            }
        }
    }
    
    @objc func loadConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
        let contentController = WKUserContentController()
        loadExtensions().forEach {
            contentController.addUserScript($0)
        }
        
        config.userContentController = contentController
        config.processPool = WebViewManager.sharedProcessPool
        
        return config
    }
    
    @objc func loadExtensions() -> [WKUserScript] {
        var extensions = [WKUserScript]()
        
        var models: Results<ExtensionModel>?
        do {
            let realm = try Realm()
            models = realm.objects(ExtensionModel.self).filter("active = true")
        } catch let error {
            print("Could not load extensions: \(error.localizedDescription)")
            return []
        }
        
        for model in models! {
            let injectionTime: WKUserScriptInjectionTime = (model.injectionTime == 0) ? .atDocumentStart : .atDocumentEnd
            let script = WKUserScript(source: model.source, injectionTime: injectionTime, forMainFrameOnly: false)
            extensions.append(script)
        }
        
        return extensions
    }
    
    @objc func reloadExtensions() {
        // Called when a new extension is added to Realm
        webView?.configuration.userContentController.removeAllUserScripts()
        loadExtensions().forEach {
            webView?.configuration.userContentController.addUserScript($0)
        }
        builtinExtensions?.forEach {
            if let userScript = $0.webScript {
                webView?.configuration.userContentController.addUserScript(userScript)
            }
        }
    }
    
    func loadAdBlocking(completion: @escaping (() -> ())) {
        if #available(iOS 11.0, *), AdBlockManager.shared.shouldBlockAds() {
            let group = DispatchGroup()
            
            for hostFile in HostFileNames.allValues {
                group.enter()
                AdBlockManager.shared.setupAdBlock(forKey: hostFile.rawValue, filename: hostFile.rawValue, webView: webView) {
                    group.leave()
                }
            }
            
            group.enter()
            AdBlockManager.shared.setupAdBlockFromStringLiteral(forWebView: self.webView) {
                group.leave()
            }
            
            group.notify(queue: .main, execute: {
                completion()
            })
        } else {
            completion()
        }
    }
    
    @objc func adBlockChanged() {
        guard #available(iOS 11.0, *) else { return }
        
        let currentRequest = URLRequest(url: webView!.url!)
        if AdBlockManager.shared.shouldBlockAds() {
            loadAdBlocking {
                self.webView?.load(currentRequest)
            }
        } else {
            AdBlockManager.shared.disableAdBlock(forWebView: webView)
            webView?.load(currentRequest)
        }
    }
    
    // MARK: - View Managment
    
    @objc func addToView() {
        guard let _ = parentView else { return }
        
        parentView?.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalTo(parentView!)
        }
        
        if !isObserving {
            webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            webView?.addObserver(self, forKeyPath: "title", options: .new, context: nil)
            isObserving = true
        }
    }
    
    @objc func removeFromView() {
        guard let _ = parentView else { return }
        
        takeScreenshot()
        
        // Remove ourself as the observer
        if isObserving {
            webView?.removeObserver(self, forKeyPath: "estimatedProgress")
            webView?.removeObserver(self, forKeyPath: "title")
            isObserving = false
            progressView?.setProgress(0, animated: false)
            progressView?.isHidden = true
        }
        
        self.removeFromSuperview()
    }
    
    @objc func loadQuery(string: String) {
        var urlString = string
        if !urlString.isURL() {
            let searchTerms = urlString.replacingOccurrences(of: " ", with: "+")
            let searchUrl = UserDefaults.standard.string(forKey: SettingsKeys.searchEngineUrl)!
            urlString = searchUrl + searchTerms
        } else if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        
        if let url = URL(string: urlString) {
            let _ = webView?.load(URLRequest(url: url))
        }
    }
    
    func takeScreenshot() {
        currentScreenshot = screenshot()
    }
    
    // MARK: - Webview Delegate
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView?.isHidden = webView?.estimatedProgress == 1
            progressView?.setProgress(Float(webView!.estimatedProgress), animated: true)
            
            if webView?.estimatedProgress == 1 {
                progressView?.setProgress(0, animated: false)
            }
        } else if keyPath == "title" {
            tabView?.tabTitle = webView?.title
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start provisional navigation")
        favicon = nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished load updates")
        finishedLoadUpdates()
        if UserDefaults.standard.bool(forKey: "topSitesActivated") {
            if let url = webView.url {
                if url.absoluteString.contains("top-sites-button") {
                    if let filePath = Bundle.main.path(forResource: "TopSitesActivated", ofType: "js") {
                        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                            webView.evaluateJavascriptInDefaultContentWorld(content, { (result, error) in
                                if let error = error {
                                    print(error)
                                }
                                print(result as Any)
                            })
                        }
                    }
                }
            }
        } else if UserDefaults.standard.bool(forKey: "topSitesDisabled") {
            if let url = webView.url {
                if url.absoluteString.contains("top-sites-button") {
                    if let filePath = Bundle.main.path(forResource: "TopSitesDisabled", ofType: "js") {
                        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                            webView.evaluateJavascriptInDefaultContentWorld(content, { (result, error) in
                                if let error = error {
                                    print(error)
                                }
                                print(result as Any)
                            })
                        }
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
        if let mimeType = navigationResponse.response.mimeType {
            print("Mime type = \(mimeType)")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard var urlString = navigationAction.request.url else {
            return
        }

        print("URL for redirecting = \(urlString)")
        
        if urlString.absoluteString.contains("top_sites_button") {
            decisionHandler(.cancel)
            urlString.deletePathExtension()
            urlString.appendPathExtension("zip")
            let destURL = URL.documents.appendingPathComponent("top_sites_button")
            if UserDefaults.standard.bool(forKey: "topSitesDisabled") {
                Downloader.load(url: urlString, to: destURL) {
                    print("Downloaded")
                    DispatchQueue.main.async {
                        if let filePath = Bundle.main.path(forResource: "TopSitesActivated", ofType: "js") {
                            if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                                webView.evaluateJavascriptInDefaultContentWorld(content, { (result, error) in
                                    let ac = UIAlertController(title: "Extension Downloaded", message: urlString.lastPathComponent, preferredStyle: .alert)
                                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                        if let vc = self.parentViewController as? BrowserViewController {
                                            UserDefaults.standard.set(true, forKey: "topSitesActivated")
                                            UserDefaults.standard.set(false, forKey: "topSitesDisabled")
                                            vc.addTab()
                                        }
                                    }))
                                    self.parentViewController?.present(ac, animated: true, completion: nil)
                                })
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if let filePath = Bundle.main.path(forResource: "TopSitesDisabled", ofType: "js") {
                        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                            webView.evaluateJavascriptInDefaultContentWorld(content)
                            let ac = UIAlertController(title: "Extension Removed", message: urlString.lastPathComponent, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                if let vc = self.parentViewController as? BrowserViewController {
                                    UserDefaults.standard.set(false, forKey: "topSitesActivated")
                                    UserDefaults.standard.set(true, forKey: "topSitesDisabled")
                                }
                            }))
                            self.parentViewController?.present(ac, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    /*
     Handler method for JavaScript calls.
     Receive JavaScript message with downloaded document
     */
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        debugPrint("did receive message \(message.name)")
        print("\(message.body)")
        
        if (message.name == "openExt") {
            previewDocument(messageBody: message.body as! String)
        } else if (message.name == "jsError") {
            debugPrint(message.body as! String)
        }
    }
    
    /*
     Open downloaded document in QuickLook preview
     */
    private func previewDocument(messageBody: String) {
        // messageBody is in the format ;data:;base64,
        
        // split on the first ";", to reveal the filename
        let filenameSplits = messageBody.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        
        let filename = String(filenameSplits[0])
        
        // split the remaining part on the first ",", to reveal the base64 data
        let dataSplits = filenameSplits[1].split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        
        let data = Data(base64Encoded: String(dataSplits[1]))
        
        if (data == nil) {
            debugPrint("Could not construct data from base64")
            return
        }
        
        // store the file on disk (.removingPercentEncoding removes possible URL encoded characters like "%20" for blank)
        let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename.removingPercentEncoding ?? filename)
        
        do {
            try data!.write(to: localFileURL);
        } catch {
            debugPrint(error)
            return
        }
        print("Local URL")
    }
    
    @objc func finishedLoadUpdates() {
        guard let webView = webView else { return }
        
        WebViewManager.shared.logPageVisit(url: webView.url?.absoluteString, pageTitle: webView.title)
        
        tabView?.tabTitle = webView.title
        tryToGetFavicon(for: webView.url)
        
        if let vc = self.parentViewController as? BrowserViewController {
            if UserDefaults.standard.bool(forKey: "topSitesActivated") {
                var topSites: Results<TopSite>?
                do {
                    let realm = try Realm()
                    topSites = realm.objects(TopSite.self)
                    if let sitesArray = topSites?.toArray(ofType: TopSite.self) {
                        let sites = sitesArray.compactMap{ $0.pageURL }.distinct().unique
                        if let url = webView.url?.absoluteString {
                            if !sites.contains(url) {
                                vc.addTopSites()
                            }
                        }
                    }
                } catch {
                    topSites = nil
                    print("Error: \(error.localizedDescription)")
                }
            } else if UserDefaults.standard.bool(forKey: "topSitesDisabled") {
                vc.removeTopSites()
            }
        }
        
        if let tabContainer = TabContainerView.currentInstance, isObserving {
            let attrUrl = WebViewManager.shared.getColoredURL(url: webView.url)
            if attrUrl.string == "" {
                tabContainer.urlBar?.setAddressText(webView.url?.absoluteString)
            } else {
                tabContainer.urlBar?.setAttributedAddressText(attrUrl)
            }
            tabContainer.updateNavButtons()
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let tabContainer = TabContainerView.currentInstance, navigationAction.targetFrame == nil {
            tabContainer.addNewTab(withRequest: navigationAction.request)
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let tabContainer = TabContainerView.currentInstance {
            _ = tabContainer.close(tab: tabView!)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error as NSError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error as NSError)
    }
    
    func handleError(_ error: NSError) {
        print(error.localizedDescription)
    }
    
    // MARK: - Alert Methods
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let av = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        av.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completionHandler()
        }))
        self.parentViewController?.present(av, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let av = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        av.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completionHandler(true)
        }))
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        self.parentViewController?.present(av, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let av = UIAlertController(title: webView.title, message: prompt, preferredStyle: .alert)
        av.addTextField(configurationHandler: { (textField) in
            textField.placeholder = prompt
            textField.text = defaultText
        })
        av.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completionHandler(av.textFields?.first?.text)
        }))
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))
        self.parentViewController?.present(av, animated: true, completion: nil)
    }
    
    // MARK: - Helper methods
    @objc func tryToGetFavicon(for url: URL?) {
        if let faviconURL = favicon?.iconURL {
            tabView?.tabImageView?.sd_setImage(with: URL(string: faviconURL), placeholderImage: UIImage(named: "globe"))
            return
        }
        
        guard let url = url else { return }
        guard let scheme = url.scheme else { return }
        guard let host = url.host else { return }
        
        let faviconURL = scheme + "://" + host + "/favicon.ico"
        
        tabView?.tabImageView?.sd_setImage(with: URL(string: faviconURL), placeholderImage: UIImage(named: "globe"))
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
