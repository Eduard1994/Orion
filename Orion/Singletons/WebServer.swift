//
//  WebServer.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/12/21.
//

import Foundation
import GCDWebServer
import RealmSwift

class WebServer {
    static let shared = WebServer()
    
    let webServer = GCDWebServer()
    
    let newTabHTMLStart = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>New Tab</title>
                        <style type="text/css">
                            * {
                                font-family: sans-serif;
                            }

                            h1 {
                                padding-top: 72px;
                                font-size: 72px;
                            }

                            #noTopSite {
                                padding-top: 144px;
                                font-size: 48px;
                            }
                            
                            .topSiteTitle {
                                margin: 0;
                                font-size: 36px;
                                overflow: hidden;
                                display: -webkit-box;
                                -webkit-line-clamp: 1;
                                -webkit-box-orient: vertical;
                            }

                            .container {
                                padding-top: 144px;
                                padding-left: 5%;
                                padding-right: 5%;
                            }
                            
                            .floatBlock {
                                display: inline-block;
                                float: left;
                                width: 33%;
                                padding-bottom: 33%
                            }

                            a img {
                                display: block;
                                margin: auto;
                            }

                            .footer {
                                background: #EFEFEF;
                                position: fixed;
                                bottom: 0;
                                width: 100%;
                                height: 100px;
                                font-size: 28px;
                                margin: 0;
                                padding-bottom: env(safe-area-inset-bottom);
                            }
                    </style>
        </head>
        <body>
            <h1 align="center">Top Sites</h1>
        """
    let newTabEnd = """
        <div class="footer">
            <p align=\"center\">Orion Web Browser v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"))</p>
        </div>
        </body></html>
        """
    
    init() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { _  in
            return GCDWebServerDataResponse(html: self.getNewTabHTMLString())
        })
        webServer.addHandler(forMethod: "GET", path: "/noimage", request: GCDWebServerRequest.self, processBlock: { _ in
            let img = #imageLiteral(resourceName: "globe")
            return GCDWebServerDataResponse(data: img.pngData()!, contentType: "image/png")
        })
        webServer.addHandler(forMethod: "GET", path: "/favicon.ico", request: GCDWebServerRequest.self, processBlock: { _ in
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary
            let primaryIconsDictionary = iconsDictionary?["CFBundlePrimaryIcon"] as? NSDictionary
            let iconFiles = primaryIconsDictionary?["CFBundleIconFiles"] as? NSArray
            // First will be smallest for the device class, last will be the largest for device class
            let lastIcon = iconFiles?.lastObject as? NSString
            guard let icon = lastIcon as String?, let img = UIImage(named: icon) else {
                let img = #imageLiteral(resourceName: "globe")
                return GCDWebServerDataResponse(data: img.pngData()!, contentType: "image/png")
            }
            return GCDWebServerDataResponse(data: img.pngData()!, contentType: "image/png")
        })
    }
    
    func startServer() {
        webServer.start(withPort: 8080, bonjourName: nil)
    }
    
    func getNewTabHTMLString() -> String {
        var result = newTabHTMLStart
        
        let topSites: Results<TopSite>?
        var sites: [TopSite]?
        do {
            let realm = try Realm()
            topSites = realm.objects(TopSite.self)
            let sitesArray = (topSites?.toArray(ofType: TopSite.self) ?? [])
            sites = sitesArray.unique
        } catch {
            topSites = nil
            print("Error: \(error.localizedDescription)")
        }

        if let topSites = sites, topSites.count > 0 {
            result += "<div class=\"container\">"
            for i in 0..<min(10, topSites.count) {
                let iconLoc = (topSites[i].iconURL == "") ? "http://localhost:8080/noimage" : topSites[i].iconURL
                result += """
                    <div class="floatBlock">
                <a href="\(topSites[i].pageURL)"><img src="\(iconLoc)" onerror=\"this.src='/noimage';\" width=200px height=200px></a>
                    <p class="topSiteTitle" align=\"center\">\(topSites[i].name)</p>
                    </div>
                """
            }
            result += "</div>"
        } else {
            result += "<p id=\"noTopSite\" align=\"center\">Go add some sites to see them here!</p>"
        }
        
        return result + newTabEnd
    }
}

extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for i in 0 ..< count {
            if let result = self[i] as? T {
                array.append(result)
            }
        }

        return array
    }
}

extension Sequence where Iterator.Element: Hashable {
    func uniqueee() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

extension Array where Element: Hashable {
    func distinct() -> Array<Element> {
        var set = Set<Element>()
        return filter {
            guard !set.contains($0) else { return false }
            set.insert($0)
            return true
        }
    }
    
    func distincts() -> Array<Element> {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
