
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
    
    v = v.replace(/\bThe Remove\b/g, "My Orion");
    v = v.replace(/\bThe remove\b/g, "My orion");
    v = v.replace(/\bthe Remove\b/g, "my Orion");
    v = v.replace(/\bthe remove\b/g, "my orion");
    v = v.replace(/\bAdd to Remove\b/g, "Orion");
    v = v.replace(/\bremove\b/g, "orion");
    v = v.replace(/\bRemove\b/g, "Add to Orion");
    v = v.replace(/\bremoves\b/g, "orions");
    v = v.replace(/\bRemoves\b/g, "Orions");
    
    textNode.nodeValue = v;
}
