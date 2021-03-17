//
//  BrowserViewController.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/11/21.
//

import UIKit
import WebKit
import LUAutocompleteView
import JavaScriptCore

class BrowserViewController: UIViewController, HistoryNavigationDelegate {

    @objc var container: UIView?
    @objc var tabContainer: TabContainerView?
    var urlBar: URLBar!
    private let autocompleteView = LUAutocompleteView()
    
    var pendingToast: Toast? // A toast that might be waiting for BVC to appear before displaying
    var downloadToast: DownloadToast? // A toast that is showing the combined download progress
    
    weak var pendingDownloadWebView: WKWebView?

    let downloadQueue = DownloadQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadQueue.delegate = self
        self.view.backgroundColor = .mainDarkGray
        
        let padding = UIView().then { [unowned self] in
            $0.backgroundColor = .mainDarkGray
            
            self.view.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.width.equalTo(self.view)
                if #available(iOS 11.0, *) {
                    make.height.equalTo(self.view.safeAreaInsets.top)
                } else {
                    make.height.equalTo(UIApplication.shared.statusBarFrame.height)
                }
                make.top.equalTo(self.view)
            }
        }
        
        tabContainer = TabContainerView(frame: .zero).then { [unowned self] in
            $0.addTabButton?.addTarget(self, action: #selector(self.addTab), for: .touchUpInside)
            $0.tabCountButton.addTarget(self, action: #selector(showTabTray), for: .touchUpInside)
            
            self.view.addSubview($0)
            $0.snp.makeConstraints { (make) in
                if #available(iOS 11.0, *) {
                    make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                } else {
                    make.top.equalTo(padding.snp.bottom)
                }
                make.left.equalTo(self.view)
                make.width.equalTo(self.view)
                make.height.equalTo(TabContainerView.standardHeight)
            }
        }
        
        urlBar = URLBar(frame: .zero).then { [unowned self] in
            $0.tabContainer = self.tabContainer
            self.tabContainer?.urlBar = $0
            
            $0.setupNaviagtionActions(forTabConatiner: self.tabContainer!)
            $0.menuButton?.addTarget(self, action: #selector(self.showMenu(sender:)), for: .touchUpInside)
            
            self.view.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.top.equalTo(self.tabContainer!.snp.bottom)
                make.left.width.equalTo(self.view)
                make.height.equalTo(URLBar.standardHeight)
            }
        }
        
        container = UIView().then { [unowned self] in
            self.tabContainer?.containerView = $0
            
            self.view.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.top.equalTo(urlBar.snp.bottom)
                make.width.equalTo(self.view)
                make.bottom.equalTo(self.view)
                make.left.equalTo(self.view)
            }
        }
        
        self.view.addSubview(autocompleteView)
        autocompleteView.textField = urlBar.urlField
        autocompleteView.dataSource = self
        autocompleteView.delegate = self
        autocompleteView.rowHeight = 45
        autocompleteView.autocompleteCell = AutocompleteTableViewCell.self
        autocompleteView.throttleTime = 0.2

        tabContainer?.loadBrowsingSession()
        
        if UserDefaults.standard.bool(forKey: SettingsKeys.needToShowAdBlockAlert) {
            showAdBlockEnabled()
        }
        
//        urlBar.urlField?.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabContainer?.currentTab?.webContainer?.takeScreenshot()
    }
    
    override func viewDidLayoutSubviews() {
        tabContainer?.setUpTabConstraints()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tabContainer?.setUpTabConstraints()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let toast = self.pendingToast {
            self.pendingToast = nil
            show(toast: toast, afterWaiting: ButtonToastUX.ToastDelay)
        }
    }
    
    func showAdBlockEnabled() {
        UserDefaults.standard.set(false, forKey: SettingsKeys.needToShowAdBlockAlert)
        
        let av = UIAlertController(title: "Ad Block Enabled!", message: "Thank you for being an early adopter of Orion! As a token of my grattitude you have received the new Ad Block add on free of charge! This will block ads from known sources on web pages you visit. Happy browsing!", preferredStyle: .alert)
        av.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            self.showSettings()
        }))
        av.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        delay(0.5) {
            self.present(av, animated: true, completion: nil)
        }
    }
    
    func show(toast: Toast, afterWaiting delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore, duration: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter) {
        if let downloadToast = toast as? DownloadToast {
            self.downloadToast = downloadToast
        }

        // If BVC isnt visible hold on to this toast until viewDidAppear
        if self.view.window == nil {
            self.pendingToast = toast
            return
        }

        toast.showToast(viewController: self, delay: delay, duration: duration, makeConstraints: { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view?.snp.bottom ?? 0)
        })
    }
    
    @objc func addTab() {
        let _ = tabContainer?.addNewTab(container: container!)
    }
    
    @objc func showMenu(sender: UIButton) {
        let convertedPoint = sender.convert(sender.center, to: self.view)
        
        let addBookmarkAction = MenuItem.item(named: "Add Bookmark", action: { [unowned self] in
            self.addBookmark(btn: sender)
        })
        let bookmarkAction = MenuItem.item(named: "Bookmarks", action: { [unowned self] in
            self.showBookmarks()
        })
        let shareAction = MenuItem.item(named: "Share", action: { [unowned self] in
            self.shareLink()
        })
        let extensionAction = MenuItem.item(named: "Extensions", action: { [unowned self] in
            let _ = self.showExtensions(animated: true)
        })
        let historyAction = MenuItem.item(named: "History", action: { [unowned self] in
            self.showHistory()
        })
        let settingsAction = MenuItem.item(named: "Settings", action: { [unowned self] in
            self.showSettings()
        })
        
        let menu = SharedDropdownMenu(menuItems: [addBookmarkAction, bookmarkAction, shareAction, extensionAction, historyAction, settingsAction])
        menu.show(in: self.view, from: convertedPoint)
    }
    
    @objc func shareLink() {
        guard let tabContainer = self.tabContainer else { return }
        let selectedTab = tabContainer.tabList[tabContainer.selectedTabIndex]
        
        guard let url = selectedTab.webContainer?.webView?.url else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.print]
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @objc func showExtensions(animated: Bool) -> ExtensionsTableViewController {
        let vc = ExtensionsTableViewController(style: .grouped)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.barTintColor = .mainGray
        
        if isiPadUI {
            nav.modalPresentationStyle = .formSheet
        }
        
        self.present(nav, animated: animated, completion: nil)
        
        return vc
    }
    
    @objc func showHistory() {
        let vc = HistoryTableViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.barTintColor = .mainGray
        
        if isiPadUI {
            nav.modalPresentationStyle = .formSheet
        }
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func showBookmarks() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 80, height: 97.5)
        let vc = BookmarkCollectionViewController(collectionViewLayout: flowLayout)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.barTintColor = .mainGray
        
        if isiPadUI {
            nav.modalPresentationStyle = .formSheet
        }
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func addBookmark(btn: UIView) {
        let vc = AddBookmarkTableViewController(style: .grouped)
        vc.pageIconURL = tabContainer?.currentTab?.webContainer?.favicon?.getPreferredURL()
        vc.pageTitle = tabContainer?.currentTab?.webContainer?.webView?.title
        vc.pageURL = tabContainer?.currentTab?.webContainer?.webView?.url?.absoluteString
        let nav = UINavigationController(rootViewController: vc)
        
        if isiPadUI {
            nav.modalPresentationStyle = .popover
            nav.popoverPresentationController?.permittedArrowDirections = .up
            nav.popoverPresentationController?.sourceView = btn
            nav.popoverPresentationController?.sourceRect = btn.bounds
        }
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func didSelectEntry(with url: URL?) {
        guard let url = url else { return }
        tabContainer?.loadQuery(string: url.absoluteString)
    }
    
    func showSettings() {
        let vc = SettingsTableViewController(style: .grouped)
        let nav = UINavigationController(rootViewController: vc)
        
        if isiPadUI {
            nav.modalPresentationStyle = .formSheet
        }
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func showTabTray() {
        let vc = TabTrayViewController()
        
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Import methods
    @objc func openEditor(withSource source: String, andName name: String) {
        if let presentedController = self.presentedViewController {
            presentedController.dismiss(animated: false, completion: nil)
        }
        
        let vc = self.showExtensions(animated: false)
        delay(0.15) {
            vc.presentEditor(name: name, source: source)
        }
    }
}

extension BrowserViewController: LUAutocompleteViewDataSource {
    func autocompleteView(_ autocompleteView: LUAutocompleteView, elementsFor text: String, completion: @escaping ([String]) -> Void) {
        let results = SuggestionManager.shared.queryDomains(forText: text).map { $0.urlString }
        completion(results)
    }
}

extension BrowserViewController: LUAutocompleteViewDelegate {
    func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect text: String) {
        urlBar.urlField?.text = text
        _ = urlBar.textFieldShouldReturn(urlBar.urlField!)
    }
}

extension BrowserViewController: DownloadQueueDelegate {
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {
        // If no other download toast is shown, create a new download toast and show it.
        guard let downloadToast = self.downloadToast else {
            let downloadToast = DownloadToast(download: download, completion: { buttonPressed in
                // When this toast is dismissed, be sure to clear this so that any
                // subsequent downloads cause a new toast to be created.
                self.downloadToast = nil

                // Handle download cancellation
                if buttonPressed, !downloadQueue.isEmpty {
                    downloadQueue.cancelAll()

                    let downloadCancelledToast = ButtonToast(labelText: Strings.DownloadCancelledToastLabelText, backgroundColor: UIColor.gray.withAlphaComponent(0.6), textAlignment: .center)

                    self.show(toast: downloadCancelledToast)
                }
            })

            show(toast: downloadToast, duration: nil)
            return
        }

        // Otherwise, just add this download to the existing download toast.
        downloadToast.addDownload(download)
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didDownloadCombinedBytes combinedBytesDownloaded: Int64, combinedTotalBytesExpected: Int64?) {
        downloadToast?.combinedBytesDownloaded = combinedBytesDownloaded
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo(): \(location)")
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
        guard let downloadToast = self.downloadToast, let download = downloadToast.downloads.first else {
            return
        }

        DispatchQueue.main.async {
            downloadToast.dismiss(false)

            if error == nil {
                let downloadCompleteToast = ButtonToast(labelText: download.filename, imageName: "check", buttonText: Strings.DownloadsButtonTitle, completion: { buttonPressed in
                    guard buttonPressed else { return }

//                    self.showLibrary(panel: .downloads)
//                    TelemetryWrapper.recordEvent(category: .action, method: .view, object: .downloadsPanel, value: .downloadCompleteToast)
                })

                self.show(toast: downloadCompleteToast, duration: DispatchTimeInterval.seconds(8))
            } else {
                let downloadFailedToast = ButtonToast(labelText: Strings.DownloadFailedToastLabelText, backgroundColor: UIColor.gray.withAlphaComponent(0.6), textAlignment: .center)

                self.show(toast: downloadFailedToast, duration: nil)
            }
        }
    }
}
