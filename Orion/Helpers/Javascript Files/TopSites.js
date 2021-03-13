var myDynamicManifest = {
    "manifest_version": 2,
    "name": "Override examples",
    "version": "0.1",
    "chrome_url_overrides": {
        "newtab": "sites.html"
    },
    "permissions": [
        "topSites"
    ],
    "browser_specific_settings": {
        "gecko": {
            "strict_min_version": "54.0a1"
        }
    }
};

const stringManifest = JSON.stringify(myDynamicManifest);
const blob = new Blob([stringManifest], {type: 'application/json'});
const manifestURL = URL.createObjectURL(blob);
document.querySelector('#my-manifest-placeholder').setAttribute('href', manifestURL);

if (!window.__firefox__) {
    window.__firefox__ = {};
}

window.__firefox__.topSite = function() {
    
    function getTopSites() {
//        window.__firefox__.topSites.get().then((sites) => {
        var bro = window.__firefox__;
        bro.topSites.get().then((sites) => {
//            var div = document.getElementById('site-list');
//
//            document.querySelector('#my-manifest-placeholder').setAttribute('href', '/my-dynamic-manifest-url.json');
//
//            if (!sites.length) {
//                div.innerText = 'No sites returned from the topSites API.';
//                return;
//            }
            
//            let ul = document.createElement('ul');
//            ul.className = 'list-group';
//            for (let site of sites) {
//                let li = document.createElement('li');
//                li.className = 'list-group-item';
//                let a = document.createElement('a');
//                a.href = site.url;
//                a.innerText = site.title || site.url;
//                li.appendChild(a);
//                ul.appendChild(li);
//            }
//
//            div.appendChild(ul);
//            console.log("Yuhuuu");
//            console.log(sites);
            
            webkit.messageHandlers.topSitesMessageHandler.postMessage(sites)
        });
    }
    
    return {
        getTopSites : getTopSites
    }
}();

window.__firefox__.topSite.getTopSites();
