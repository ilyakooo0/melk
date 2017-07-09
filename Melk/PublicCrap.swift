//
//  PublicCrap.swift
//  golos
//
//  Created by Ilya Kos on 8/29/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import UIKit
import RealmSwift

//let userQueue = DispatchQueue(label: "io.golos.userRequestedQueue", qos: .userInitiated)
let userQueue = DispatchQueue.init(label: "io.golos.userRequestedQueue", qos: .userInitiated, attributes: .concurrent)

fileprivate let manager = FileManager.default

func url(forName name: String) -> URL? {
    return manager.urls(for: .libraryDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent("Caches")
        .appendingPathComponent(name)
}

func write(cache data: Data?, withName name: String, completion: (() -> ())? = nil) {
    if let url = url(forName: name) {
        userQueue.async {
            manager.createFile(atPath: url.path, contents: data)
            //            try! data?.write(to: url)
            if let completion = completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
}

func delete(cache name: String) {
    if let url = manager.urls(for: .documentDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent("Cache")
        .appendingPathComponent(name) {
        DispatchQueue.main.async {
            userQueue.async {
                try? manager.removeItem(at: url)
            }
        }
    }
}

func getLocalImage(fromName name: String) -> UIImage? {
    return url(forName: name) =>>
        {try? Data(contentsOf: $0)} =>>
        {UIImage.init(data: $0)}
}

func cache(image: UIImage?, withName name: String) -> String? {
    return image =>> {return UIImagePNGRepresentation($0)} >>>
        { data in
            write(cache: data, withName: name)
            return name
    }
}

precedencegroup SortedAppend {
    higherThan: AssignmentPrecedence
    associativity: left
}

infix operator <-: SortedAppend // Expects all things to be sorted
infix operator <~: SortedAppend // Sorts all things it gets regardless

protocol SortedArrayItem {
    func equal(to: Self) -> Bool
    func greater(than: Self) -> Bool
}

/// Returns: true if added. false if was already in list
func <~<T: SortedArrayItem>(lhs: List<T>?, rhs: T?) -> Bool {  // Note: Most recent go first (i e bigger ids go first)
    if let rhs = rhs,
        let lhs = lhs {
        if lhs.count == 0 {
            lhs.append(rhs)
            return true
        }
        var l = 0
        var r = lhs.count - 1
        var i = Int((l+r)/2)
        while l<r {
            i = Int((l+r)/2)
            if rhs.greater(than: lhs[i]) {
                l = i + 1
            } else if rhs.equal(to: lhs[i]) {
                return false
            } else {
                r = i
            }
        }
        if lhs[r].equal(to: rhs) {
            return false
        }
        assert(l == r, "l != r!!!")
        if rhs.greater(than: lhs[l]) {
            lhs.insert(rhs, at: l + 1)
        } else {
            lhs.insert(rhs, at: l)
        }
        return true
    }
    return false
}

/// Will silently break if not passed a SORTED list
/// Returns: Indexes of added items
func <-<T: SortedArrayItem>(lhs: List<T>?, rhs: List<T>?) -> [Int] {
    var indexes: [Int] = []
    if let lhs = lhs,
        let rhs = rhs {
        var index = 0
        for item in rhs {
            while index < lhs.count && item.greater(than: lhs[index]) {
                index += 1
            }
            if index == lhs.count || !item.equal(to: lhs[index]) {
                lhs.insert(item, at: index)
                indexes.append(index)
            }
        }
    }
    return indexes
}

/// Returns: Indexes of added items
func <-<T: SortedArrayItem>(lhs: List<T>?, rhs: [T?]?) -> [Int] {
    var indexes: [Int] = []
    if let lhs = lhs,
        let rhs = rhs?.flatMap({$0}) {
        var index = 0
        for item in rhs {
            while index < lhs.count && item.greater(than: lhs[index]) {
                index += 1
            }
            if index == lhs.count || !item.equal(to: lhs[index]) {
                lhs.insert(item, at: index)
                indexes.append(index)
            }
        }
    }
    return indexes
}

/// Returns: true if added. false if was already in list
func <~(lhs: RealmDialog?, rhs: Message?) -> Bool {
    guard let message = rhs,
        let dialog = lhs
        else { return false }
//    assert(dialog.date != nil, "Date is nil on dialog!!!")
    print(dialog.date ?? "no date found")
    var out: Bool!
    realmWrite { (_) in
        let messages = dialog.value?.messages
        out = messages <~ message
        dialog.date = messages?.first?.date
    }
    print(dialog.date ?? "There was no date... \t", message)
    return out
}

func <-(lhs: RealmDialog?, rhs: [Message?]?){
    guard let ms = rhs,
        let dialog = lhs
        else { return }
    realmWrite { (_) in
        let messages = dialog.value?.messages
        messages <- ms
        dialog.date = messages?.first?.date
    }

}

/// Returns: true if added. false if was already in list
func <~(lhs: Dialog?, rhs: Message?) -> Bool {
    guard let message = rhs,
        let dialog = lhs
        else { return false}
    var out: Bool!
    realmWrite { (_) in
        out = dialog.messages <~ message
    }
    return out
}

func <-(lhs: Dialog?, rhs: [Message?]?) {
    guard let messages = rhs,
        let dialog = lhs
        else { return }
    realmWrite { (_) in
        dialog.messages <- messages
    }
}

/// Appends if not already in list
func add<T>(item: T?, toList list: List<T>) {
    if let item = item {
        if !list.contains(item) {
            list.append(item)
        }
    }
}

func realmWrite(_ code: ((Realm) -> ())) {
    realmWriteWithCompletion { realm, _ in
        code(realm)
    }
}

fileprivate var completions: [String: [(()->())]] = [:]


/// Passed closure should be called from within realmWrite and should be passed a completion block
func realmWriteWithCompletion(_ code: ((Realm, (( @escaping (()->()) )->()) ) -> ())) {
    let label = String.init(utf8String: __dispatch_queue_get_label(nil))!
    let addCompletion: (( @escaping (()->()) )->()) = { completion in
        if !completions.keys.contains(label) {
            completions[label] = []
        }
        completions[label]?.append(completion)
    }
    do {
        let realm = try Realm()
        if realm.isInWriteTransaction {
            code(realm, addCompletion)
        } else {
            try realm.write {
                code(realm, addCompletion)
            }
            completions[label]?.map { $0() }
            completions[label]?.removeAll()            
        }
    } catch {
        // TODO: Handle error. Error closure?
    }
}

struct DecayingAverage {
    var weight: CGFloat = 20
    var value: CGFloat = 0
    mutating func add(_ num: CGFloat) {
        value = (value * weight + num) / (weight + 1)
    }
}

func mainSync(_ code: (() -> ())) {
    if Thread.isMainThread {
        code()
    } else {
        DispatchQueue.main.sync {
            code()
        }
    }
}
