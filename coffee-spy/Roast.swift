//
//  Roast.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/30/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

public final class MyRoast {
    var startTimestamp: Date!
    
    var fcTime: TimeInterval?
    var scTime: TimeInterval?
    var stopTime: TimeInterval?
    
    public var btCurve = [TempSample]()
    public var etCurve = [TempSample]()
    
    public init() {
        
    }
    
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
    
    func addBtSample(temp: Double, time: TimeInterval? = nil) {
        let time = time ?? Date().timeIntervalSince(startTimestamp)
        btCurve.append(TempSample(time: time, temp: temp))
    }
    
    func addEtSample(temp: Double, time: TimeInterval? = nil) {
        let time = time ?? Date().timeIntervalSince(startTimestamp)
        etCurve.append(TempSample(time: time, temp: temp))
    }
}

extension MyRoast {
    public func loadSampleCsv() {
        let data = try! String(contentsOf: URL(fileURLWithPath: "/Users/kon/Library/Developer/Xcode/DerivedData/coffee-spy-gxhfygvqgfbdlpaxoxhbghrgxvta/Build/Products/Debug/SampleRoast.csv"))
        
        for line in data.components(separatedBy: "\n")[1...] {
            var time: Int = 0
            var beanTemp: Double = 0
            var envTemp: Double = 0
            
            for (idx, column) in line.components(separatedBy: ",").enumerated() {
                switch idx {
                case 1:
                    let timeParts = column.components(separatedBy: ":")
                    time = Int(timeParts[0])! * 60 + Int(timeParts[1])!
                case 2:
                    beanTemp = Double(column)!
                case 3:
                    envTemp = Double(column)!
                default:
                    // nothing
                    break
                }
            }
            
            addBtSample(temp: beanTemp, time: TimeInterval(time))
            addEtSample(temp: envTemp, time: TimeInterval(time))
        }
        print("Loaded")
    }
    
    public func printData() {
        
    }
}

public struct TempSample {
    public var time: TimeInterval
    public var temp: Double
}
