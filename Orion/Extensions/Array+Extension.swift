//
//  Array+Extension.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/16/21.
//

import Foundation

public extension Sequence {
    // [T] -> (T -> K) -> [K: [T]]
    // As opposed to `groupWith` (to follow Haskell's naming), which would be
    // [T] -> (T -> K) -> [[T]]
    func groupBy<Key, Value>(_ selector: (Self.Iterator.Element) -> Key, transformer: (Self.Iterator.Element) -> Value) -> [Key: [Value]] {
        var acc: [Key: [Value]] = [:]
        for x in self {
            let k = selector(x)
            var a = acc[k] ?? []
            a.append(transformer(x))
            acc[k] = a
        }
        return acc
    }

    func zip<S: Sequence>(_ elems: S) -> [(Self.Iterator.Element, S.Iterator.Element)] {
        var rights = elems.makeIterator()
        return self.compactMap { lhs in
            guard let rhs = rights.next() else {
                return nil
            }
            return (lhs, rhs)
        }
    }
}

public extension Array where Element: Comparable {
    func sameElements(_ arr: [Element]) -> Bool {
        guard self.count == arr.count else { return false }
        let sorted = self.sorted(by: <)
        let arrSorted = arr.sorted(by: <)
        for elements in sorted.zip(arrSorted) where elements.0 != elements.1 {
            return false
        }
        return true
    }
}

public extension Array {

    func find(_ f: (Iterator.Element) -> Bool) -> Iterator.Element? {
        for x in self {
            if f(x) {
                return x
            }
        }
        return nil
    }

    func contains(_ x: Element, f: (Element, Element) -> Bool) -> Bool {
        for y in self {
            if f(x, y) {
                return true
            }
        }
        return false
    }

    // Performs a union operator using the result of f(Element) as the value to base uniqueness on.
    func union<T: Hashable>(_ arr: [Element], f: ((Element) -> T)) -> [Element] {
        let result = self + arr
        return result.unique(f)
    }

    // Returns unique values in an array using the result of f()
    func unique<T: Hashable>(_ f: ((Element) -> T)) -> [Element] {
        var map: [T: Element] = [T: Element]()
        return self.compactMap { a in
            let t = f(a)
            if map[t] == nil {
                map[t] = a
                return a
            } else {
                return nil
            }
        }
    }

}

public extension Sequence {
    func every(_ f: (Self.Iterator.Element) -> Bool) -> Bool {
        for x in self {
            if !f(x) {
                return false
            }
        }
        return true
    }
}

public extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

