//
//  MyWierdness.swift
//  golos
//
//  Created by Ilya Kos on 8/9/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import Foundation

func monadate<T, M>(inp: T?, funct: ((T) -> M?)) -> M? {
    if let sinp = inp {
        return funct(sinp)
    } else {
        return nil
    }
}

infix operator =>>: Monadation
/// Unwraps
func =>><T, M>(inp: T?, funct: ((T) -> M?)) -> M? {
    return monadate(inp: inp, funct: funct)
}

precedencegroup Monadation {
    higherThan: SortedAppend //AssignmentPrecedence
    associativity: left
}

infix operator >>>: Monadation
/// Doesn't unwrap
func >>><T, M>(inp: T?, funct: ((T) -> M)) -> M? {
    if let sinp = inp {
        return funct(sinp)
    }
    return nil
}

func sum(acc: Int, arr: [Int]) -> Int {
    if arr == [] {
        return acc
    } else {
        var arr = arr
        let num = arr.popLast()
        return sum(acc: acc + num!, arr: arr)
    }
}

extension Bool {
    static func from(num: Int) -> Bool {
        return num > 0 ? true : false
    }
    init(from num: Int) {
        self = Bool.from(num: num)
    }
}

extension Int {
    var bool: Bool {
        return self > 0 ? true : false
    }
}


infix operator |>: Monadation
/// runs right after left
func |>(lhs: (() -> ())?, rhs: (() -> ())?) -> (() -> ())? {
    if lhs != nil || rhs != nil {
        return {
            lhs?()
            rhs?()
        }
    } else {
        return nil
    }
}
func |><T>(lhs: ((T) -> ())?, rhs: (() -> ())?) -> ((T) -> ())? {
    if lhs != nil || rhs != nil {
        return {
            lhs?($0)
            rhs?()
        }
    } else {
        return nil
    }
}
func |><T>(lhs: (() -> ())?, rhs: ((T) -> ())?) -> ((T) -> ())? {
    if lhs != nil || rhs != nil {
        return {
            lhs?()
            rhs?($0)
        }
    } else {
        return nil
    }
}

func ??<T>(lhs: T?, rhs: (() -> T)) -> T {
    if let l = lhs {
        return l
    } else {
        return rhs()
    }
}
