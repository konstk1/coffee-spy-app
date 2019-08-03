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
    func asCelsius() -> Double {
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

func getPlist(named name: String) -> [String: String]? {
    guard  let path = Bundle.main.path(forResource: name, ofType: "plist"),
        let xml = FileManager.default.contents(atPath: path) else {
            log.error("Failed to read contents of \(name).plist")
            return nil
    }
    
    return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainers, format: nil)) as? [String: String]
}

