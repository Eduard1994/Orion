// Enabling this extension will replace all
// occurrences of "Firefox" with "Orion"
// This is especially fun if you forget
// you've enabled it. Try searching for
// "the cloud" on google to see it in
// action.

walk(document.body);

function walk(node) {
    // I stole this function from here:
    // http://is.gd/mwZp7E
    var child, next;
    
    switch (node.nodeType) {
        case 1:  // Element
        case 9:  // Document
        case 11: // Document fragment
            child = node.firstChild;
            while (child) {
                next = child.nextSibling;
                walk(child);
                child = next;
            }
            break;
        case 3: // Text node
            handleText(node);
            break;
    }
}

function handleText(textNode)  {
    var v = textNode.nodeValue;
    
    v = v.replace(/\bThe Firefox\b/g, "My Orion");
    v = v.replace(/\bThe firefox\b/g, "My orion");
    v = v.replace(/\bthe Firefox\b/g, "my Orion");
    v = v.replace(/\bthe firefox\b/g, "my orion");
    v = v.replace(/\bfirefox\b/g, "orion");
    v = v.replace(/\bFirefox\b/g, "Orion");
    v = v.replace(/\bfirefoxs\b/g, "Orions");
    v = v.replace(/\bFirefoxs\b/g, "Orions");
    
    textNode.nodeValue = v;
}
