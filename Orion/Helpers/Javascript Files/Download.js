
(async function download() {
    const url = '\(absoluteUrl)';
    try {
        // we use a second try block here to have more detailed error information
        // because of the nature of JS the outer try-catch doesn't know anything where the error happended
        let res;
        try {
            res = await fetch(url, {
            credentials: 'include'
            });
        } catch (err) {
            webkit.messageHandlers.jsError.postMessage(`fetch threw, error: ${err}, url: ${url}`);
            return;
        }
        if (!res.ok) {
            webkit.messageHandlers.jsError.postMessage(`Response status was not ok, status: ${res.status}, url: ${url}`);
            return;
        }
        const contentDisp = res.headers.get('content-disposition');
        if (contentDisp) {
            const match = contentDisp.match(/(^;|)\\s*filename=\\s*(\"([^\"]*)\"|([^;\\s]*))\\s*(;|$)/i);
            if (match) {
                filename = match[3] || match[4];
            } else {
                // TODO: we could here guess the filename from the mime-type (e.g. unnamed.pdf for pdfs, or unnamed.tiff for tiffs)
                webkit.messageHandlers.jsError.postMessage(`content-disposition header could not be matched against regex, content-disposition: ${contentDisp} url: ${url}`);
            }
        } else {
            webkit.messageHandlers.jsError.postMessage(`content-disposition header missing, url: ${url}`);
            return;
        }
        if (!filename) {
            const contentType = res.headers.get('content-type');
            if (contentType) {
                if (contentType.indexOf('application/json') === 0) {
                    filename = 'unnamed.pdf';
                } else if (contentType.indexOf('image/tiff') === 0) {
                    filename = 'unnamed.tiff';
                }
            }
        }
        if (!filename) {
            webkit.messageHandlers.jsError.postMessage(`Could not determine filename from content-disposition nor content-type, content-dispositon: ${contentDispositon}, content-type: ${contentType}, url: ${url}`);
        }
        let data;
        try {
            data = await res.blob();
        } catch (err) {
            webkit.messageHandlers.jsError.postMessage(`res.blob() threw, error: ${err}, url: ${url}`);
            return;
        }
        const fr = new FileReader();
        fr.onload = () => {
            webkit.messageHandlers.openExt.postMessage(`${filename};${fr.result}`)
        };
        fr.addEventListener('error', (err) => {
            webkit.messageHandlers.jsError.postMessage(`FileReader threw, error: ${err}`)
        })
        fr.readAsDataURL(data);
    } catch (err) {
        // TODO: better log the error, currently only TypeError: Type error
        webkit.messageHandlers.jsError.postMessage(`JSError while downloading document, url: ${url}, err: ${err}`)
    }
})();
// null is needed here as this eval returns the last statement and we can't return a promise
null;
