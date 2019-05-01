//
//  Roast.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/30/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

final class MyRoast {
    var startTimestamp: Date!
    
    var fcTime: TimeInterval?
    var scTime: TimeInterval?
    var stopTime: TimeInterval?
    
    var bt = TempCurve()
    var et = TempCurve()
    
    func start() {
        startTimestamp = Date()
    }
    
    func markFC() {
        fcTime = Date().timeIntervalSince(startTimestamp)
    }
    
    func marcSC() {
        scTime = Date().timeIntervalSince(startTimestamp)
    }
    
    func stop() {
        stopTime = Date().timeIntervalSince(startTimestamp)
    }
    
    func addBtSample(temp: Int) {
        let time = Date().timeIntervalSince(startTimestamp)
        bt.addSample(time: time, temp: temp)
    }
    
    func addEtSample(temp: Int) {
        let time = Date().timeIntervalSince(startTimestamp)
        et.addSample(time: time, temp: temp)
    }
}

struct TempCurve {
    private(set) var timestamp = [TimeInterval]()
    private(set) var temp = [Int]()
    
    var count: Int {
        return timestamp.count
    }
    
    mutating func addSample(time: TimeInterval, temp: Int) {
        timestamp.append(time)
        self.temp.append(temp)
    }
}
