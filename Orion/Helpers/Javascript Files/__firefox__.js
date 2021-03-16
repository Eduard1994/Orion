
"use strict";

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
