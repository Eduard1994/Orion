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


if (!window.__firefox__) {
  Object.defineProperty(window, "__firefox__", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
      userScripts: {},
      includeOnce: function(userScript, initializer) {
        if (!__firefox__.userScripts[userScript]) {
          __firefox__.userScripts[userScript] = true;
          if (typeof initializer === 'function') {
            initializer();
          }
          return false;
        }

        return true;
      }
    }
  });
}

window.__firefox__= function() {
    function getTopSites() {
        var browser = window.__firefox__;
        browser.topSites.get().then((sites) => {
            webkit.messageHandlers.topSitesMessageHandler.postMessage(sites)
        });
    }
    return {
        getTopSites : getTopSites
    }
}();

window.__firefox__.getTopSites();
