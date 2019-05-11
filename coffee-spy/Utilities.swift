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

extension Double {
    func asFahrenheit() -> Double {
        return (self * 9.0/5.0) + 32.0
    }
    
    func asCelcius() -> Double {
        return (self - 32.0) * 5.0/9.0
    }
}
