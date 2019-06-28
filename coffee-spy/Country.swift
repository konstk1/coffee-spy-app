//
//  Country.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 6/27/19.
//  Copyright © 2019 KK. All rights reserved.
//

import UIKit

enum CoffeeRegion: String, CaseIterable {
    case africa = "Africa"
    case centralAmerica = "Central America"
    case southAmerica = "South America"
    case southeastAsia = "Southeast Asia"
}

struct Country {
    var name: String
    var code: String
    var region: CoffeeRegion
    
    func flagImage() -> UIImage {
        return UIImage(named: code) ?? UIImage()
    }
}

let coffeeCountries = [
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

func countries(in region: CoffeeRegion) -> [Country] {
    return coffeeCountries.filter { $0.region == region }
}

func country(named name: String) -> Country? {
    return coffeeCountries.first { $0.name == name }
}
