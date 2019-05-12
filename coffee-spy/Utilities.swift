//
//  Utilities.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 5/11/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

public typealias DegreesC = Double
public typealias DegreesF = Double

public extension DegreesC {
    func asFahrenheit() -> Double {
        return (self * 9.0/5.0) + 32.0
    }
}

public extension DegreesF {
    func asCelcius() -> Double {
        return (self - 32.0) * 5.0/9.0
    }
}

public extension TimeInterval {
    func asMinSecString() -> String {
        let min = Int(self / 60)
        let sec = Int(self) % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

