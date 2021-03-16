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
        favicon = nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishedLoadUpdates()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        decisionHandler(.allow)
        guard let urlString = navigationAction.request.url else {
            return
        }

        print("URL for redirecting = \(urlString)")
        
        if urlString.absoluteString.contains("top_sites_button") {
            decisionHandler(.cancel)
//            executeDocumentDownloadScript(forAbsoluteUrl: urlString)
//            DownloadHelper.requestDownload(url: urlString, webView: webView)
            let destURL = URL.documents.appendingPathComponent("top_sites_button")
            Downloader.load(url: urlString, to: destURL) {
                print("Downloaded")
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
        
        
        if (message.name == "openDocument") {
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
    
    /*
     Intercept the download of documents in webView, trigger the download in JavaScript and pass the binary file to JavaScript handler in Swift code
     */
    private func executeDocumentDownloadScript(forAbsoluteUrl absoluteUrl : String) {
//        openURL(path: absoluteUrl)
        // TODO: Add more supported mime-types for missing content-disposition headers
//        webView?.evaluateJavaScript("""
//                (async function download() {
//                    const url = '\(absoluteUrl)';
//                    try {
//                        // we use a second try block here to have more detailed error information
//                        // because of the nature of JS the outer try-catch doesn't know anything where the error happended
//                        let res;
//                        try {
//                            res = await fetch(url, {
//                                credentials: 'include'
//                            });
//                        } catch (err) {
//                            webkit.messageHandlers.jsError.postMessage(`fetch threw, error: ${err}, url: ${url}`);
//                            return;
//                        }
//                        if (!res.ok) {
//                            webkit.messageHandlers.jsError.postMessage(`Response status was not ok, status: ${res.status}, url: ${url}`);
//                            return;
//                        }
//                        const contentDisp = res.headers.get('content-disposition');
//                        if (contentDisp) {
//                            const match = contentDisp.match(/(^;|)\\s*filename=\\s*(\"([^\"]*)\"|([^;\\s]*))\\s*(;|$)/i);
//                            if (match) {
//                                filename = match[3] || match[4];
//                            } else {
//                                // TODO: we could here guess the filename from the mime-type (e.g. unnamed.pdf for pdfs, or unnamed.tiff for tiffs)
//                                webkit.messageHandlers.jsError.postMessage(`content-disposition header could not be matched against regex, content-disposition: ${contentDisp} url: ${url}`);
//                            }
//                        } else {
//                            webkit.messageHandlers.jsError.postMessage(`content-disposition header missing, url: ${url}`);
//                            return;
//                        }
//                        if (!filename) {
//                            const contentType = res.headers.get('content-type');
//                            if (contentType) {
//                                if (contentType.indexOf('application/json') === 0) {
//                                    filename = 'unnamed.pdf';
//                                } else if (contentType.indexOf('image/tiff') === 0) {
//                                    filename = 'unnamed.tiff';
//                                }
//                            }
//                        }
//                        if (!filename) {
//                            webkit.messageHandlers.jsError.postMessage(`Could not determine filename from content-disposition nor content-type, content-dispositon: ${contentDispositon}, content-type: ${contentType}, url: ${url}`);
//                        }
//                        let data;
//                        try {
//                            data = await res.blob();
//                        } catch (err) {
//                            webkit.messageHandlers.jsError.postMessage(`res.blob() threw, error: ${err}, url: ${url}`);
//                            return;
//                        }
//                        const fr = new FileReader();
//                        fr.onload = () => {
//                            webkit.messageHandlers.openExt.postMessage(`${filename};${fr.result}`)
//                        };
//                        fr.addEventListener('error', (err) => {
//                            webkit.messageHandlers.jsError.postMessage(`FileReader threw, error: ${err}`)
//                        })
//                        fr.readAsDataURL(data);
//                    } catch (err) {
//                        // TODO: better log the error, currently only TypeError: Type error
//                        webkit.messageHandlers.jsError.postMessage(`JSError while downloading document, url: ${url}, err: ${err}`)
//                    }
//                })();
//                // null is needed here as this eval returns the last statement and we can't return a promise
//                null;
//            """) { (result, err) in
//            print("Result is = \(result)")
//            if (err != nil) {
//                debugPrint("JS ERR: \(String(describing: err))")
//            }
//        }
    }
    
    @objc func finishedLoadUpdates() {
        guard let webView = webView else { return }
        
        WebViewManager.shared.logPageVisit(url: webView.url?.absoluteString, pageTitle: webView.title)
        
        tabView?.tabTitle = webView.title
        tryToGetFavicon(for: webView.url)
        
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
//        if let failUrl = error.userInfo["NSErrorFailingURLStringKey"] as? String, let url = URL(string: failUrl), !failUrl.contains("localhost") {
//            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { success in
//                if success {
//                    print("openURL succeeded")
//                }
//            })
//        }
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

