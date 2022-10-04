//
//  SynchronizedArray.swift
//  SynchronizedTableViewDemo
//
//  Created by stephen payne on 10/4/22.
//

import Foundation

public class SynchronizedArray<Element> {
    private let queue = DispatchQueue(label: "Messages.SynchronizedArray", attributes: .concurrent)
    private var array = [Element]()

    var first: Element? {
    var result: Element?
            queue.sync { result = self.array.first }
            return result
        }

    var last: Element? {
        var result: Element?
        queue.sync { result = self.array.last }
        return result
    }

    var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }

    var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }

    var description: String {
        var result = ""
        queue.sync { result = self.array.description }
        return result
    }

    public init() { }

    public convenience init(_ array: [Element]) {
        self.init()
        self.array = array
    }
}

public extension SynchronizedArray where Element: Comparable {
    func sorted() -> [Element]? {
        var result: [Element]?
        queue.sync { result = self.array.sorted() }
        return result
    }
}

public extension SynchronizedArray {
    var indices: Range<Int> {
        get {
            queue.sync {
                return array.indices
            }
        }
    }

    func first(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        queue.sync { result = self.array.first(where: predicate) }
        return result
    }

    func last(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        queue.sync { result = self.array.last(where: predicate) }
        return result
    }

    func filter(_ isIncluded: @escaping (Element) -> Bool) -> SynchronizedArray {
        var result: SynchronizedArray?
        queue.sync { result = SynchronizedArray(self.array.filter(isIncluded)) }
        return result!
    }

    func index(where predicate: (Element) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.array.firstIndex(where: predicate) }
        return result
    }
    
    func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> SynchronizedArray {
        var result: SynchronizedArray?
        queue.sync { result = SynchronizedArray(self.array.sorted(by: areInIncreasingOrder)) }
        return result!
    }

    func map<ElementOfResult>(_ transform: @escaping (Element) -> ElementOfResult) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.array.map(transform) }
        return result
    }

    func compactMap<ElementOfResult>(_ transform: (Element) -> ElementOfResult?) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.array.compactMap(transform) }
        return result
    }

    func reduce<ElementOfResult>(_ initialResult: ElementOfResult, _ nextPartialResult: @escaping (ElementOfResult, Element) -> ElementOfResult) -> ElementOfResult {
        var result: ElementOfResult?
        queue.sync { result = self.array.reduce(initialResult, nextPartialResult) }
        return result ?? initialResult
    }

    func reduce<ElementOfResult>(into initialResult: ElementOfResult, _ updateAccumulatingResult: @escaping (inout ElementOfResult, Element) -> ()) -> ElementOfResult {
        var result: ElementOfResult?
        queue.sync { result = self.array.reduce(into: initialResult, updateAccumulatingResult) }
        return result ?? initialResult
    }

    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.array.forEach(body) }
    }

    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(where: predicate) }
        return result
    }

    func allSatisfy(_ predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.allSatisfy(predicate) }
        return result
    }
    
    subscript(range: Range<Int>) -> [Element]? {
        queue.sync {
            return Array(self.array[range])
        }
    }

    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            queue.sync {
                guard self.array.startIndex..<self.array.endIndex ~= index else { return }
                result = self.array[index]
            }

            return result
        }
        set {
            guard let newValue = newValue else { return }
            queue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
    }
}

public extension SynchronizedArray where Element: Equatable {
    func firstIndex(of element: Element) -> Int? {
        var result: Int?
        queue.sync {
            result = self.array.firstIndex(of: element)
        }
        
        return result
    }
    
    func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        var result: Int?
        queue.sync {
            result = try? self.array.firstIndex(where: predicate)
        }
        
        return result
    }
    
    func insert(contentsOf contents: [Element], at index: Int) {
        queue.async(flags: .barrier) {
            self.array.insert(contentsOf: contents, at: index)
        }
    }
    
    func allElements() -> [Element]? {
        var result: [Element]?
        queue.sync {
            result = self.array
        }
        
        return result
    }
    
    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(element) }
        return result
    }
}

// MARK: APPEND/INSERT/REMOVE
public extension SynchronizedArray {
    func append(_ element: Element) {
        queue.async(flags: .barrier) { self.array.append(element) }
    }

    func append(_ elements: [Element]) {
        queue.async(flags: .barrier) { self.array += elements }
    }

    func insert(_ element: Element, at index: Int) {
        queue.async(flags: .barrier) { self.array.insert(element, at: index) }
    }

    func remove(at index: Int, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let element = self.array.remove(at: index)
            DispatchQueue.main.async { completion?(element) }
        }
    }

    func remove(where predicate: @escaping (Element) -> Bool, completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            var elements = [Element]()
            while let index = self.array.firstIndex(where: predicate) {
                elements.append(self.array.remove(at: index))
            }
            DispatchQueue.main.async { completion?(elements) }
        }
    }

    func removeAll(completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let elements = self.array
            self.array.removeAll()
            DispatchQueue.main.async { completion?(elements) }
        }
    }
}

public extension SynchronizedArray {
    static func +=(left: inout SynchronizedArray, right: Element) {
        left.append(right)
    }

    static func +=(left: inout SynchronizedArray, right: [Element]) {
        left.append(right)
    }
}
