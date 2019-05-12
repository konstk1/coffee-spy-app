//
//  Roast.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/30/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

public final class MyRoast {
    var startTimestamp: Date?
    
    var fcTime: TimeInterval?
    var scTime: TimeInterval?
    var stopTime: TimeInterval?
    
    var elapsedTime: TimeInterval {
        guard let startTimestamp = startTimestamp else { return 0 }
        return Date().timeIntervalSince(startTimestamp)
    }
    
    var isRunning: Bool {
        return startTimestamp != nil && stopTime == nil
    }
    
    public var btCurve = [TempSample]()
    public var etCurve = [TempSample]()
    
    public init() {
        print("Roast init")
    }
    
    func start() {
        startTimestamp = Date()
        stopTime = nil
        fcTime = nil
        scTime = nil
    }
    
    func markFC() {
        fcTime = elapsedTime
    }
    
    func marcSC() {
        scTime = elapsedTime
    }
    
    func stop() {
        stopTime = elapsedTime
    }
    
    fileprivate func addTempSample(temp: DegreesC, time: TimeInterval?, curve: inout [TempSample]) {
        guard stopTime == nil else { return }   // if roast stopped (non-nil stopTime), ignore sample
        
        var sampleTime: TimeInterval
        
        switch (time, startTimestamp) {
        case let (nil, startTimestamp?):        // no time provided, requires startTimestamp
            sampleTime = Date().timeIntervalSince(startTimestamp)
        case let (time?, _):                    // time provided, ignore startTimestamp
            sampleTime = time
        default:                                // no time provided and roast hasn't started
            return                              // ignore sample
        }
    
        curve.append(TempSample(time: sampleTime, temp: temp))
    }
    
    func addBtSample(temp: DegreesC, time: TimeInterval? = nil) {
        addTempSample(temp: temp, time: time, curve: &btCurve)
    }
    
    func addEtSample(temp: DegreesC, time: TimeInterval? = nil) {
        addTempSample(temp: temp, time: time, curve: &etCurve)
    }
}

public extension MyRoast {
    func loadSampleCsv() {
        let data = try! String(contentsOf: URL(fileURLWithPath: "/Users/kon/Library/Developer/Xcode/DerivedData/coffee-spy-gxhfygvqgfbdlpaxoxhbghrgxvta/Build/Products/Debug/SampleRoast.csv"))
        
//        print(data)
        
        for line in data.components(separatedBy: "\n")[1...] {
            var time: Int = 0
            var beanTemp: DegreesC = 0
            var envTemp: DegreesC = 0
            
            for (idx, column) in line.components(separatedBy: ",").enumerated() {
                switch idx {
                case 1:
                    let timeParts = column.components(separatedBy: ":")
                    time = Int(timeParts[0])! * 60 + Int(timeParts[1])!
                case 2:
                    // this sample csv has temps in F, need to convert to C
                    beanTemp = Double(column)!.asCelcius()
                case 3:
                    envTemp = Double(column)!.asCelcius()
                default:
                    // nothing
                    break
                }
            }
            
            addBtSample(temp: beanTemp, time: TimeInterval(time))
            addEtSample(temp: envTemp, time: TimeInterval(time))
        }
        
        print("Loaded \(btCurve.count) samples")
    }
    
    public func printData() {
        
    }
}

public struct TempSample {
    public var time: TimeInterval
    public var temp: DegreesC
}
