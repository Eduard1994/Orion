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
    
    v = v.replace(/\bThe Orion\b/g, "My Remove");
    v = v.replace(/\bThe orion\b/g, "My remove");
    v = v.replace(/\bthe Orion\b/g, "my Remove");
    v = v.replace(/\bthe orion\b/g, "my remove");
    v = v.replace(/\bAdd to Orion\b/g, "Remove");
    v = v.replace(/\borion\b/g, "remove");
    v = v.replace(/\bOrion\b/g, "Remove");
    v = v.replace(/\borions\b/g, "removes");
    v = v.replace(/\bOrions\b/g, "Removes");
    
    textNode.nodeValue = v;
}
