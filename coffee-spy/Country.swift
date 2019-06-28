//
//  Country.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 6/27/19.
//  Copyright © 2019 KK. All rights reserved.
//

import UIKit

struct Country: Equatable, CustomStringConvertible {
    
    enum Region: String, CaseIterable {
        case africa = "Africa"
        case centralAmerica = "Central America"
        case southAmerica = "South America"
        case southeastAsia = "Southeast Asia"
    }
    
    var name: String
    var code: String
    var region: Region
    
    var description: String {
        return "\(flagEmoji) \(name)"
    }
    
    var flagEmoji: String {
        let base : UInt32 = 127397
        var s = ""
        for v in code.unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return String(s)
    }
    
    static func ==(lhs: Country, rhs: Country) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func countries(in region: Region) -> [Country] {
        return availableCountries.filter { $0.region == region }
    }
    
    static func country(named name: String) -> Country? {
        return availableCountries.first { $0.name == name }
    }
    
    static let availableCountries = [
        // Africa
        Country(name: "Ethiopia", code: "ET", region: .africa),
        // Central America
        Country(name: "Nicaragua", code: "NI", region: .centralAmerica),
        // South America
        Country(name: "Brazil", code: "BR", region: .southAmerica),
        // Southeast Asia
        Country(name: "India", code: "IN", region: .southeastAsia),
        Country(name: "Indonesia", code: "ID", region: .southeastAsia),
    ]
}

